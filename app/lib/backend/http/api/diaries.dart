import 'dart:convert';
import 'package:friend_private/backend/schema/diary.dart';
import 'package:friend_private/backend/http/shared.dart';

class DiariesApi {
  static Future<List<ServerDiary>> getDiaries(
      {required int page, required int pageSize}) async {
    final response = await makeApiCall(
      url: '/v1/diaries?page=$page&pageSize=$pageSize',
      method: 'GET',
      headers: {},
      body: '',
    );

    if (response != null && response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ServerDiary.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load diaries');
    }
  }

  static Future<void> updateDiary(ServerDiary diary) async {
    final response = await makeApiCall(
      url: '/v1/diaries/${diary.id}',
      method: 'PATCH',
      headers: {'Content-Type': 'application/json'},
      body: json.encode(diary.toJson()),
    );

    if (response == null || response.statusCode != 200) {
      throw Exception('Failed to update diary');
    }
  }

  static Future<void> deleteDiary(String diaryId) async {
    final response = await makeApiCall(
      url: '/v1/diaries/$diaryId',
      method: 'DELETE',
      headers: {},
      body: '',
    );

    if (response == null || response.statusCode != 200) {
      throw Exception('Failed to delete diary');
    }
  }
}
