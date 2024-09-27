import 'package:flutter/material.dart';
import 'package:friend_private/backend/schema/diary.dart';
import 'package:friend_private/backend/http/api/diaries.dart';

class DiaryProvider extends ChangeNotifier {
  List<ServerDiary> _diaries = [];
  Map<DateTime, List<ServerDiary>> diaryEventMap = {};
  bool _isLoadingDiaries = false;
  ServerDiary? _selectedDiary;

  List<ServerDiary> get diaries => _diaries;
  bool get isLoadingDiaries => _isLoadingDiaries;
  ServerDiary? get selectedDiary => _selectedDiary;

  Future<void> loadAllDiaries() async {
    _isLoadingDiaries = true;
    notifyListeners();

    try {
      final fetchedDiaries = await DiariesApi.getAllDiaries();
      _diaries = fetchedDiaries;
      _updateDiaryEventMap();
    } catch (e) {
      print('Error fetching diaries: $e');
    }

    _isLoadingDiaries = false;
    notifyListeners();
  }

  // Normalize the date to the start of the day so that it can be stable key in the map
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _updateDiaryEventMap() {
    diaryEventMap = Map.fromIterable(
      _diaries,
      key: (diary) => _normalizeDate(diary.createdAt),
      value: (diary) => _diaries
          .where((d) => isSameDay(d.createdAt, diary.createdAt))
          .toList(),
    );
    print('diaryEventMap: $diaryEventMap');
  }

  Future<void> deleteDiary(String diaryId) async {
    try {
      await DiariesApi.deleteDiary(diaryId);
      _diaries.removeWhere((d) => d.id == diaryId);
      _updateDiaryEventMap();
      notifyListeners();
    } catch (e) {
      print('Error deleting diary: $e');
    }
  }

  List<ServerDiary> getDiariesForDay(DateTime day) {
    print('diary in diaryEventMap: $diaryEventMap[_normalizeDate(day)]');
    return diaryEventMap[_normalizeDate(day)] ?? [];
  }

  void selectDiary(DateTime day) {
    final diariesForDay = getDiariesForDay(day);
    _selectedDiary = diariesForDay.isNotEmpty ? diariesForDay.first : null;
    notifyListeners();
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return _normalizeDate(date1) == _normalizeDate(date2);
  }

  Map<DateTime, List<ServerDiary>> getDiaryEventMap() {
    return diaryEventMap;
  }

  Set<DateTime> getDiaryDates() {
    return _diaries.map((diary) => _normalizeDate(diary.createdAt)).toSet();
  }
}
