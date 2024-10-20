import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:foxxy_package/backend/http/shared.dart';
import 'package:foxxy_package/backend/schema/geolocation.dart';
import 'package:foxxy_package/backend/schema/memory.dart';
import 'package:foxxy_package/backend/schema/structured.dart';
import 'package:foxxy_package/backend/schema/transcript_segment.dart';
import 'package:foxxy_package/env/env.dart';
import 'package:foxxy_package/utils/analytics/growthbook.dart';
import 'package:http/http.dart' as http;
import 'package:instabug_flutter/instabug_flutter.dart';
import 'package:path/path.dart';
import 'package:tuple/tuple.dart';

Future<bool> migrateMemoriesToBackend(List<dynamic> memories) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v1/migration/memories',
    headers: {'Content-Type': 'application/json'},
    method: 'POST',
    body: jsonEncode(memories),
  );
  debugPrint('migrateMemoriesToBackend: ${response?.body}');
  return response?.statusCode == 200;
}

Future<CreateMemoryResponse?> createMemoryServer({
  required DateTime startedAt,
  required DateTime finishedAt,
  required List<TranscriptSegment> transcriptSegments,
  Geolocation? geolocation,
  List<Tuple2<String, String>> photos = const [],
  bool triggerIntegrations = true,
  String? language,
  File? audioFile,
  String? source,
  String? processingMemoryId,
}) async {
  var response = await makeApiCall(
    url:
        '${Env.apiBaseUrl}v1/memories?trigger_integrations=$triggerIntegrations&source=$source',
    headers: {},
    method: 'POST',
    body: jsonEncode({
      'started_at': startedAt.toUtc().toIso8601String(),
      'finished_at': finishedAt.toUtc().toIso8601String(),
      'transcript_segments':
          transcriptSegments.map((segment) => segment.toJson()).toList(),
      'geolocation': geolocation?.toJson(),
      'photos': photos
          .map((photo) => {'base64': photo.item1, 'description': photo.item2})
          .toList(),
      'source': transcriptSegments.isNotEmpty ? 'friend' : 'openglass',
      'language': language, // maybe determine auto?
      'processing_memory_id': processingMemoryId,
      // 'audio_base64_url': audioFile != null ? await wavToBase64Url(audioFile.path) : null,
    }),
  );
  if (response == null) return null;
  debugPrint('createMemoryServer: ${response.body}');
  if (response.statusCode == 200) {
    return CreateMemoryResponse.fromJson(jsonDecode(response.body));
  } else {
    // TODO: Server returns 304 doesn't recover
    CrashReporting.reportHandledCrash(
      Exception('Failed to create memory'),
      StackTrace.current,
      level: NonFatalExceptionLevel.info,
      userAttributes: {
        'response': response.body,
        'transcriptSegments':
            TranscriptSegment.segmentsAsString(transcriptSegments),
      },
    );
  }
  return null;
}

Future<List<ServerMemory>> getMemories({int limit = 50, int offset = 0}) async {
  var response = await makeApiCall(
      url: '${Env.apiBaseUrl}v1/memories?limit=$limit&offset=$offset',
      headers: {},
      method: 'GET',
      body: '');
  if (response == null) return [];
  if (response.statusCode == 200) {
    // decode body bytes to utf8 string and then parse json so as to avoid utf8 char issues
    var body = utf8.decode(response.bodyBytes);
    var memories = (jsonDecode(body) as List<dynamic>)
        .map((memory) => ServerMemory.fromJson(memory))
        .toList();
    debugPrint('getMemories length: ${memories.length}');
    return memories;
  }
  return [];
}

Future<ServerMemory?> reProcessMemoryServer(String memoryId) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v1/memories/$memoryId/reprocess',
    headers: {},
    method: 'POST',
    body: '',
  );
  if (response == null) return null;
  debugPrint('reProcessMemoryServer: ${response.body}');
  if (response.statusCode == 200) {
    var body = utf8.decode(response.bodyBytes);
    return ServerMemory.fromJson(jsonDecode(body));
  }
  return null;
}

Future<bool> deleteMemoryServer(String memoryId) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v1/memories/$memoryId',
    headers: {},
    method: 'DELETE',
    body: '',
  );
  if (response == null) return false;
  debugPrint('deleteMemory: ${response.statusCode}');
  return response.statusCode == 204;
}

Future<ServerMemory?> getMemoryById(String memoryId) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v1/memories/$memoryId',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getMemoryById: ${response.body}');
  if (response.statusCode == 200) {
    var body = utf8.decode(response.bodyBytes);
    return ServerMemory.fromJson(jsonDecode(body));
  }
  return null;
}

Future<ServerProcessingMemory?> getProcessingMemoryById(String id) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v1/processing-memories/$id',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getProcessingMemoryById: ${response.body}');
  if (response.statusCode == 200) {
    var body = utf8.decode(response.bodyBytes);
    return ServerProcessingMemory.fromJson(jsonDecode(body));
  }
  return null;
}

Future<List<MemoryPhoto>> getMemoryPhotos(String memoryId) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v1/memories/$memoryId/photos',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return [];
  debugPrint('getMemoryPhotos: ${response.body}');
  if (response.statusCode == 200) {
    return (jsonDecode(response.body) as List<dynamic>)
        .map((photo) => MemoryPhoto.fromJson(photo))
        .toList();
  }
  return [];
}

class TranscriptsResponse {
  List<TranscriptSegment> deepgram;
  List<TranscriptSegment> soniox;
  List<TranscriptSegment> whisperx;
  List<TranscriptSegment> speechmatics;

  TranscriptsResponse({
    this.deepgram = const [],
    this.soniox = const [],
    this.whisperx = const [],
    this.speechmatics = const [],
  });

  factory TranscriptsResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptsResponse(
      deepgram: (json['deepgram'] as List<dynamic>)
          .map((segment) => TranscriptSegment.fromJson(segment))
          .toList(),
      soniox: (json['soniox'] as List<dynamic>)
          .map((segment) => TranscriptSegment.fromJson(segment))
          .toList(),
      whisperx: (json['whisperx'] as List<dynamic>)
          .map((segment) => TranscriptSegment.fromJson(segment))
          .toList(),
      speechmatics: (json['speechmatics'] as List<dynamic>)
          .map((segment) => TranscriptSegment.fromJson(segment))
          .toList(),
    );
  }
}

Future<TranscriptsResponse> getMemoryTranscripts(String memoryId) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v1/memories/$memoryId/transcripts',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return TranscriptsResponse();
  debugPrint('getMemoryTranscripts: ${response.body}');
  if (response.statusCode == 200) {
    var transcripts = (jsonDecode(response.body) as Map<String, dynamic>);
    return TranscriptsResponse.fromJson(transcripts);
  }
  return TranscriptsResponse();
}

Future<bool> uploadMemoryAudio(String memoryId, File file) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('${Env.apiBaseUrl}v1/memories/$memoryId/upload_audio'),
  );
  request.files.add(await http.MultipartFile.fromPath('file', file.path,
      filename: basename(file.path)));
  request.headers
      .addAll({'Authorization': await getAuthHeader(), 'Provider': 'authing'});

  try {
    var response = await request.send();
    debugPrint('uploadMemoryAudio: ${response.statusCode}');
    return response.statusCode == 200;
  } catch (e) {
    debugPrint('An error occurred uploadMemoryAudio: $e');
    return false;
  }
}

Future<Map<String, dynamic>> getMemoryConnectionsGraph(
    List<String> memoryIds, int levels) async {
  try {
    final response = await makeApiCall(
      url: '${Env.apiBaseUrl}v1/memories/connections_graph',
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'memory_ids': memoryIds,
        'memory_connection_depth': levels,
      }),
    );

    if (response == null) {
      throw Exception('Failed to get memory connections graph: No response');
    }

    if (response.statusCode == 200) {
      var body = utf8.decode(response.bodyBytes);
      return jsonDecode(body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'Failed to get memory connections graph: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error in getMemoryConnectionsGraph: $e');
    rethrow;
  }
}

Future<bool> hasMemoryRecording(String memoryId) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v1/memories/$memoryId/recording',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return false;
  debugPrint('getMemoryPhotos: ${response.body}');
  if (response.statusCode == 200) {
    return jsonDecode(response.body)['has_recording'] ?? false;
  }
  return false;
}

Future<bool> assignMemoryTranscriptSegment(
  String memoryId,
  int segmentIdx, {
  bool? isUser,
  String? personId,
  bool useForSpeechTraining = true,
}) async {
  String assignType = isUser != null ? 'is_user' : 'person_id';
  var response = await makeApiCall(
    url:
        '${Env.apiBaseUrl}v1/memories/$memoryId/segments/$segmentIdx/assign?value=${isUser ?? personId}'
        '&assign_type=$assignType&use_for_speech_training=$useForSpeechTraining',
    headers: {},
    method: 'PATCH',
    body: '',
  );
  if (response == null) return false;
  debugPrint('assignMemoryTranscriptSegment: ${response.body}');
  return response.statusCode == 200;
}

Future<bool> setMemoryVisibility(String memoryId,
    {String visibility = 'shared'}) async {
  var response = await makeApiCall(
    url:
        '${Env.apiBaseUrl}v1/memories/$memoryId/visibility?value=$visibility&visibility=$visibility',
    headers: {},
    method: 'PATCH',
    body: '',
  );
  if (response == null) return false;
  debugPrint('setMemoryVisibility: ${response.body}');
  return response.statusCode == 200;
}

Future<bool> setMemoryEventsState(
  String memoryId,
  List<int> eventsIdx,
  List<bool> values,
) async {
  print(jsonEncode({
    'events_idx': eventsIdx,
    'values': values,
  }));
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v1/memories/$memoryId/events',
    headers: {},
    method: 'PATCH',
    body: jsonEncode({
      'events_idx': eventsIdx,
      'values': values,
    }),
  );
  if (response == null) return false;
  debugPrint('setMemoryEventsState: ${response.body}');
  return response.statusCode == 200;
}

//this is expected to return complete memories
Future<List<ServerMemory>> sendStorageToBackend(
    File file, String dateTimeStorageString) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse(
        '${Env.apiBaseUrl}sdcard_memory?date_time=$dateTimeStorageString'),
  );
  request.headers.addAll({'Authorization': await getAuthHeader()});
  request.files.add(await http.MultipartFile.fromPath('file', file.path,
      filename: basename(file.path)));
  try {
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      debugPrint('storageSend Response body: ${jsonDecode(response.body)}');
    } else {
      debugPrint('Failed to storageSend. Status code: ${response.statusCode}');
      return [];
    }

    var memories = (jsonDecode(response.body) as List<dynamic>)
        .map((memory) => ServerMemory.fromJson(memory))
        .toList();
    debugPrint('getMemories length: ${memories.length}');

    return memories;
  } catch (e) {
    debugPrint('An error occurred storageSend: $e');
    return [];
  }
}

Future<ServerMemory> createMemoryFromWeChatArticle(String articleLink) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}v1/memories/wechat-article',
    headers: {},
    method: 'POST',
    body: jsonEncode(<String, String>{
      'article_link': articleLink,
    }),
  );

  if (response == null) {
    throw Exception(
        'Failed to create memory from WeChat article, this should not happen');
  }

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    return ServerMemory.fromJson(jsonResponse);
  } else {
    throw Exception(
        'Failed to create memory from WeChat article: ${response.body}');
  }
}
