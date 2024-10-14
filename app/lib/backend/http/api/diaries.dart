import 'dart:convert';
import 'package:foxxy_package/backend/schema/diary.dart';
import 'package:foxxy_package/backend/http/shared.dart';
import 'package:foxxy_package/env/env.dart';

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
      return jsonList
          .map((json) {
            try {
              return ServerDiary.fromJson(json);
            } catch (e) {
              return null;
            }
          })
          .where((diary) => diary != null)
          .cast<ServerDiary>()
          .toList();
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
