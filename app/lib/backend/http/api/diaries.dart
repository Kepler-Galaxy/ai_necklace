import 'dart:convert';
import 'package:friend_private/backend/schema/diary.dart';
import 'package:friend_private/backend/http/shared.dart';
import 'package:friend_private/env/env.dart';

class DiariesApi {
  static Future<List<ServerDiary>> getAllDiaries() async {
    final response = await makeApiCall(
      url: '${Env.apiBaseUrl}v1/diaries',
      method: 'GET',
      headers: {},
      body: '',
    );

    if (response != null && response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ServerDiary.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load all diaries');
    }
  }

  static Future<void> deleteDiary(String diaryId) async {
    final response = await makeApiCall(
      url: '${Env.apiBaseUrl}v1/diaries/$diaryId',
      method: 'DELETE',
      headers: {},
      body: '',
    );

    if (response == null || response.statusCode != 200) {
      throw Exception('Failed to delete diary');
    }
  }
}
