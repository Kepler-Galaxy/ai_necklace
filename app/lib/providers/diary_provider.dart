import 'package:flutter/material.dart';
import 'package:friend_private/backend/schema/diary.dart';
import 'package:friend_private/backend/http/api/diaries.dart';

class DiaryProvider extends ChangeNotifier {
  List<dynamic> _diariesWithDates = [];
  List<ServerDiary> _diaries = [];
  bool _isLoadingDiaries = false;
  ServerDiary? _selectedDiary;
  int _currentPage = 1;
  static const int _pageSize = 20;

  List<dynamic> get diariesWithDates => _diariesWithDates;
  List<ServerDiary> get diaries => _diaries;
  bool get isLoadingDiaries => _isLoadingDiaries;
  ServerDiary? get selectedDiary => _selectedDiary;

  Future<void> getInitialDiaries() async {
    _isLoadingDiaries = true;
    notifyListeners();

    try {
      final fetchedDiaries = await DiariesApi.getDiaries(page: 1, pageSize: _pageSize);
      _diaries = fetchedDiaries;
      _updateDiariesWithDates();
      _currentPage = 1;
    } catch (e) {
      print('Error fetching initial diaries: $e');
    }

    _isLoadingDiaries = false;
    notifyListeners();
  }

  Future<void> getMoreDiariesFromServer() async {
    if (_isLoadingDiaries) return;

    _isLoadingDiaries = true;
    notifyListeners();

    try {
      final fetchedDiaries = await DiariesApi.getDiaries(page: _currentPage + 1, pageSize: _pageSize);
      if (fetchedDiaries.isNotEmpty) {
        _diaries.addAll(fetchedDiaries);
        _updateDiariesWithDates();
        _currentPage++;
      }
    } catch (e) {
      print('Error fetching more diaries: $e');
    }

    _isLoadingDiaries = false;
    notifyListeners();
  }

  void _updateDiariesWithDates() {
    _diariesWithDates = [];
    DateTime? currentDate;

    for (var diary in _diaries) {
      if (currentDate == null || !isSameDay(currentDate, diary.createdAt)) {
        currentDate = diary.createdAt;
        _diariesWithDates.add(currentDate);
      }
      _diariesWithDates.add(diary);
    }
  }

  void filterDiaries(String query) {
    if (query.isEmpty) {
      _updateDiariesWithDates();
    } else {
      final filteredDiaries = _diaries.where((diary) =>
          diary.content.toLowerCase().contains(query.toLowerCase())).toList();
      _diariesWithDates = filteredDiaries;
    }
    notifyListeners();
  }

  void initFilteredDiaries() {
    _updateDiariesWithDates();
    notifyListeners();
  }

  Future<void> updateDiary(ServerDiary diary) async {
    try {
      await DiariesApi.updateDiary(diary);
      final index = _diaries.indexWhere((d) => d.id == diary.id);
      if (index != -1) {
        _diaries[index] = diary;
        _updateDiariesWithDates();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating diary: $e');
    }
  }

  Future<void> deleteDiary(String diaryId) async {
    try {
      await DiariesApi.deleteDiary(diaryId);
      _diaries.removeWhere((d) => d.id == diaryId);
      _updateDiariesWithDates();
      notifyListeners();
    } catch (e) {
      print('Error deleting diary: $e');
    }
  }

  List<ServerDiary> getDiariesForDay(DateTime day) {
    return _diaries.where((diary) => isSameDay(diary.createdAt, day)).toList();
  }

  void selectDiary(DateTime day) {
    final diariesForDay = getDiariesForDay(day);
    _selectedDiary = diariesForDay.isNotEmpty ? diariesForDay.first : null;
    notifyListeners();
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}