import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:friend_private/backend/http/api/memories.dart';
import 'package:friend_private/backend/preferences.dart';
import 'package:friend_private/backend/schema/memory.dart';
import 'package:friend_private/utils/analytics/mixpanel.dart';
import 'package:friend_private/utils/memories/process.dart';
import 'package:instabug_flutter/instabug_flutter.dart';
import 'package:tuple/tuple.dart';
import 'package:friend_private/backend/http/shared.dart';
import 'package:friend_private/env/env.dart';
import 'package:friend_private/backend/schema/memory_connection.dart';

class MemoryProvider extends ChangeNotifier {
  List<ServerMemory> memories = [];
  List<ServerMemory> filteredMemories = [];
  List memoriesWithDates = [];

  bool isLoadingMemories = false;
  bool displayDiscardMemories = false;
  bool hasNonDiscardedMemories = true;

  String previousQuery = '';

  bool _isCreatingWeChatMemory = false;
  bool get isCreatingWeChatMemory => _isCreatingWeChatMemory;
  void setCreatingWeChatMemory(bool value) {
    _isCreatingWeChatMemory = value;
    notifyListeners();
  }

  Future<ServerMemory?> getMemoryById(String id) async {
    try {
      final response = await makeApiCall(
        url: '${Env.apiBaseUrl}v1/memories/$id',
        method: 'GET',
        headers: {},
        body: '',
      );
      if (response != null && response.statusCode == 200) {
        return ServerMemory.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print("Error fetching memory: $e");
    }
    return null;
  }

  // TODO(yiqi): use batch request
  Future<List<ServerMemory>> getMemoriesByIds(List<String> memoryIds) async {
    List<ServerMemory> memories = [];
    for (String id in memoryIds) {
      ServerMemory? memory = await getMemoryById(id);
      if (memory != null) {
        memories.add(memory);
      }
    }
    return memories;
  }

  Future<List<MemoryConnectionNode>> getMemoryChains(
      List<String> memoryIds, int depth) async {
    final response = await getMemoryConnectionsGraph(memoryIds, depth);
    return (response['forest'] as List)
        .map((tree) => MemoryConnectionNode.fromJson(tree))
        .toList();
  }

  void populateMemoriesWithDates() {
    memoriesWithDates = [];
    for (var i = 0; i < filteredMemories.length; i++) {
      if (i == 0) {
        memoriesWithDates.add(filteredMemories[i]);
      } else {
        if (filteredMemories[i].createdAt.day !=
            filteredMemories[i - 1].createdAt.day) {
          memoriesWithDates.add(filteredMemories[i].createdAt);
        }
        memoriesWithDates.add(filteredMemories[i]);
      }
    }
    notifyListeners();
  }

  void initFilteredMemories() {
    filterMemories('');
    populateMemoriesWithDates();
    notifyListeners();
  }

  void filterMemories(String query) {
    filteredMemories = [];
    filteredMemories = displayDiscardMemories
        ? memories
        : memories.where((memory) => !memory.discarded).toList();
    filteredMemories = query.isEmpty
        ? filteredMemories
        : filteredMemories
            .where(
              (memory) => (memory.getTranscript() +
                      memory.structured.title +
                      memory.structured.overview)
                  .toLowerCase()
                  .contains(query.toLowerCase()),
            )
            .toList();
    if (query == '' && filteredMemories.isEmpty) {
      filteredMemories = memories;
      displayDiscardMemories = true;
      hasNonDiscardedMemories = false;
    }
    populateMemoriesWithDates();
    notifyListeners();
  }

  void toggleDiscardMemories() {
    MixpanelManager().showDiscardedMemoriesToggled(!displayDiscardMemories);
    displayDiscardMemories = !displayDiscardMemories;
    filterMemories('');
    populateMemoriesWithDates();
    notifyListeners();
  }

  void setLoadingMemories(bool value) {
    isLoadingMemories = value;
    notifyListeners();
  }

  Future getInitialMemories() async {
    memories = await getMemoriesFromServer();
    if (memories.isEmpty) {
      memories = SharedPreferencesUtil().cachedMemories;
    } else {
      SharedPreferencesUtil().cachedMemories = memories;
    }
    initFilteredMemories();
    retryFailedMemories();
    notifyListeners();
  }

  Future getMemoriesFromServer() async {
    setLoadingMemories(true);
    var mem = await getMemories(limit: 50);
    memories = mem;
    setLoadingMemories(false);
    notifyListeners();
    return memories;
  }

  Future getMoreMemoriesFromServer() async {
    if (memories.length % 50 != 0) return;
    debugPrint(
        'current memory lengh: ${memories.length}, getMoreMemoriesFromServer');
    if (isLoadingMemories) return;
    setLoadingMemories(true);
    var newMemories = await getMemories(offset: memories.length);
    memories.addAll(newMemories);
    filterMemories('');
    setLoadingMemories(false);
    notifyListeners();
  }

  void addMemory(ServerMemory memory) {
    memories.insert(0, memory);
    filterMemories('');
    notifyListeners();
  }

  void updateMemory(ServerMemory memory, [int? index]) {
    if (index != null) {
      memories[index] = memory;
    } else {
      int i = memories.indexWhere((element) => element.id == memory.id);
      if (i != -1) {
        memories[i] = memory;
      }
    }
    filterMemories('');
    notifyListeners();
  }

  void deleteMemory(ServerMemory memory, int index) {
    memories.removeAt(index);
    deleteMemoryServer(memory.id);
    filterMemories('');
    notifyListeners();
  }

  // TODO: Move this to somewhere more suitable
  Future<ServerMemory?> _retrySingleFailed(ServerMemory memory) async {
    if (memory.transcriptSegments.isEmpty || memory.photos.isEmpty) return null;
    return await processTranscriptContent(
      segments: memory.transcriptSegments,
      sendMessageToChat: null,
      startedAt: memory.startedAt,
      finishedAt: memory.finishedAt,
      geolocation: memory.geolocation,
      photos: memory.photos
          .map((photo) => Tuple2(photo.base64, photo.description))
          .toList(),
      triggerIntegrations: false,
      language: memory.language ?? 'en',
      processingMemoryId: memory.processingMemoryId,
    );
  }

  Future retryFailedMemories() async {
    if (SharedPreferencesUtil().failedMemories.isEmpty) return;
    debugPrint(
        'SharedPreferencesUtil().failedMemories: ${SharedPreferencesUtil().failedMemories.length}');
    // retry failed memories
    List<Future<ServerMemory?>> asyncEvents = [];
    for (var item in SharedPreferencesUtil().failedMemories) {
      asyncEvents.add(_retrySingleFailed(item));
    }
    // TODO: should be able to retry including created at date.
    // TODO: should trigger integrations? probably yes, but notifications?

    List<ServerMemory?> results = await Future.wait(asyncEvents);
    var failedCopy =
        List<ServerMemory>.from(SharedPreferencesUtil().failedMemories);

    for (var i = 0; i < results.length; i++) {
      ServerMemory? newCreatedMemory = results[i];

      if (newCreatedMemory != null) {
        SharedPreferencesUtil().removeFailedMemory(failedCopy[i].id);
        memories.insert(0, newCreatedMemory);
      } else {
        var prefsMemory = SharedPreferencesUtil().failedMemories[i];
        if (prefsMemory.transcriptSegments.isEmpty &&
            prefsMemory.photos.isEmpty) {
          SharedPreferencesUtil().removeFailedMemory(failedCopy[i].id);
          continue;
        }
        if (SharedPreferencesUtil().failedMemories[i].retries == 3) {
          CrashReporting.reportHandledCrash(
              Exception('Retry memory limits reached'), StackTrace.current,
              userAttributes: {
                'memory': jsonEncode(
                    SharedPreferencesUtil().failedMemories[i].toJson())
              });
          SharedPreferencesUtil().removeFailedMemory(failedCopy[i].id);
          continue;
        }
        memories.insert(
            0,
            SharedPreferencesUtil()
                .failedMemories[i]); // TODO: sort them or something?
        SharedPreferencesUtil().increaseFailedMemoryRetries(failedCopy[i].id);
      }
    }
    debugPrint(
        'SharedPreferencesUtil().failedMemories: ${SharedPreferencesUtil().failedMemories.length}');
    notifyListeners();
  }

  Future<void> addWeChatMemory(String articleLink) async {
    setCreatingWeChatMemory(true);
    try {
      final memory = await createMemoryFromWeChatArticle(articleLink);
      addMemory(memory);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to create memory: $e');
    } finally {
      setCreatingWeChatMemory(false);
    }
  }
}
