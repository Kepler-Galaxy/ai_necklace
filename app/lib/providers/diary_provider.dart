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

  void _updateDiaryEventMap() {
    diaryEventMap = Map.fromIterable(
      _diaries,
      key: (diary) => DateTime(
          diary.createdAt.year, diary.createdAt.month, diary.createdAt.day),
      value: (diary) => _diaries
          .where((d) => isSameDay(d.createdAt, diary.createdAt))
          .toList(),
    );
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
    return diaryEventMap[day] ?? [];
  }

  void selectDiary(DateTime day) {
    final diariesForDay = getDiariesForDay(day);
    _selectedDiary = diariesForDay.isNotEmpty ? diariesForDay.first : null;
    notifyListeners();
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Map<DateTime, List<ServerDiary>> getDiaryEventMap() {
    return diaryEventMap;
  }
}
