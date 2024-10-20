import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foxxy_package/backend/http/api/memories.dart';
import 'package:foxxy_package/backend/preferences.dart';
import 'package:foxxy_package/backend/schema/memory.dart';
import 'package:foxxy_package/backend/schema/structured.dart';
import 'package:foxxy_package/utils/analytics/mixpanel.dart';
import 'package:foxxy_package/utils/features/calendar.dart';
import 'package:foxxy_package/backend/http/shared.dart';
import 'package:foxxy_package/env/env.dart';
import 'package:foxxy_package/backend/schema/memory_connection.dart';
import 'dart:convert';

class MemoryProvider extends ChangeNotifier {
  List<ServerMemory> memories = [];
  List<ServerMemory> filteredMemories = [];
  List memoriesWithDates = [];

  bool isLoadingMemories = false;
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
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        return ServerMemory.fromJson(jsonResponse);
      }
    } catch (e) {
      print("Error fetching memory: $e");
    }
    return null;
  }

  Future cleanMemories() async {
    memories = [];
    filteredMemories = [];
    memoriesWithDates = [];
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
    populateMemoriesWithDates();
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
    filteredMemories = SharedPreferencesUtil().showDiscardedMemories
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
      SharedPreferencesUtil().showDiscardedMemories = true;
      hasNonDiscardedMemories = false;
    }
    populateMemoriesWithDates();
    notifyListeners();
  }

  void toggleDiscardMemories() {
    MixpanelManager().showDiscardedMemoriesToggled(
        !SharedPreferencesUtil().showDiscardedMemories);
    SharedPreferencesUtil().showDiscardedMemories =
        !SharedPreferencesUtil().showDiscardedMemories;
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
    // No need to retry memories anymore as it is handled by the server
    // retryFailedMemories();
    notifyListeners();
  }

  Future getMemoriesFromServer() async {
    setLoadingMemories(true);
    var mem = await getMemories(limit: 50);
    memories = mem;
    createEventsForMemories();
    setLoadingMemories(false);
    notifyListeners();
    return memories;
  }

  void createEventsForMemories() {
    for (var memory in memories) {
      if (memory.structured.events.isNotEmpty &&
          !memory.structured.events.first.created &&
          memory.startedAt!
              .isAfter(DateTime.now().add(const Duration(days: -1)))) {
        _handleCalendarCreation(memory);
      }
    }
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
    initFilteredMemories();
    notifyListeners();
  }

  int addMemoryWithDate(ServerMemory memory) {
    int idx;
    var date = memoriesWithDates.indexWhere((element) =>
        element is DateTime &&
        element.day == memory.createdAt.day &&
        element.month == memory.createdAt.month &&
        element.year == memory.createdAt.year);
    if (date != -1) {
      var hour = memoriesWithDates[date + 1].createdAt.hour;
      var newHour = memory.createdAt.hour;
      if (newHour > hour) {
        memoriesWithDates.insert(date + 1, memory);
        idx = date + 1;
      } else {
        memoriesWithDates.insert(date + 2, memory);
        idx = date + 2;
      }
    } else {
      memoriesWithDates.add(memory.createdAt);
      memoriesWithDates.add(memory);
      idx = memoriesWithDates.length - 1;
    }
    notifyListeners();
    return idx;
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
    initFilteredMemories();
    notifyListeners();
  }

  _handleCalendarCreation(ServerMemory memory) {
    if (!SharedPreferencesUtil().calendarEnabled) return;
    if (SharedPreferencesUtil().calendarType != 'auto') return;

    List<Event> events = memory.structured.events;
    if (events.isEmpty) return;

    List<int> indexes = events.mapIndexed((index, e) => index).toList();
    setMemoryEventsState(memory.id, indexes, indexes.map((_) => true).toList());
    for (var i = 0; i < events.length; i++) {
      print('Creating event: ${events[i].title}');
      if (events[i].created) continue;
      events[i].created = true;
      CalendarUtil().createEvent(
        events[i].title,
        events[i].startsAt,
        events[i].duration,
        description: events[i].description,
      );
    }
  }

  /////////////////////////////////////////////////////////////////
  ////////// Delete Memory With Undo Functionality ///////////////

  Map<String, ServerMemory> memoriesToDelete = {};

  void deleteMemoryLocally(ServerMemory memory, int index) {
    memoriesToDelete[memory.id] = memory;
    memories.removeWhere((element) => element.id == memory.id);
    filterMemories('');
    notifyListeners();
  }

  void deleteMemoryOnServer(String memoryId) {
    deleteMemoryServer(memoryId);
    memoriesToDelete.remove(memoryId);
  }

  void undoDeleteMemory(String memoryId, int index) {
    if (memoriesToDelete.containsKey(memoryId)) {
      ServerMemory memory = memoriesToDelete.remove(memoryId)!;
      memories.insert(index, memory);
      filterMemories('');
    }
    notifyListeners();
  }
  /////////////////////////////////////////////////////////////////

  void deleteMemory(ServerMemory memory, int index) {
    memories.removeWhere((element) => element.id == memory.id);
    deleteMemoryServer(memory.id);
    filterMemories('');
    notifyListeners();
  }

  Future<void> addWebLinkMemory(String articleLink) async {
    setCreatingWeChatMemory(true);
    try {
      final memory = await createMemoryFromWeChatArticle(articleLink);
      addMemory(memory);
      MixpanelManager().memoryCreated(memory);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to create memory: $e');
    } finally {
      setCreatingWeChatMemory(false);
    }
  }
}
