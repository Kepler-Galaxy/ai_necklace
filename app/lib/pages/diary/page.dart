import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:friend_private/providers/diary_provider.dart';
import 'package:friend_private/backend/schema/diary.dart';
import 'dart:convert';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late Map<DateTime, List<ServerDiary>> _diaryEvents;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _diaryEvents = {};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDiaries();
    });
  }

  void _loadDiaries() async {
    setState(() => _isLoading = true);
    try {
      final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
      await diaryProvider.loadAllDiaries();
      setState(() {
        _diaryEvents = diaryProvider.getDiaryEventMap();
        DateTime? closestDate = _findClosestDiaryDate(_focusedDay);
        _selectedDay = closestDate ??
            _focusedDay; // Use _focusedDay if closestDate is null
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading diaries: $e");
      setState(() {
        _isLoading = false;
        _diaryEvents =
            {}; // Ensure _diaryEvents is initialized even if loading fails
      });
    }
  }

  DateTime? _findClosestDiaryDate(DateTime date) {
    final sortedDates = _diaryEvents.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    if (sortedDates.isEmpty) {
      return null; // Return null if there are no diary entries
    }

    try {
      return sortedDates.firstWhere(
        (d) => d.isAfter(date) || isSameDay(d, date),
        orElse: () => sortedDates.last,
      );
    } catch (e) {
      print("Error finding closest diary date: $e");
      return null; // Return null if an error occurs
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.3, // 30% of screen height
                  child: _buildCalendar(),
                ),
                Expanded(
                  child: Center(
                    // Center the diary content
                    child: SingleChildScrollView(
                      // Make the content scrollable
                      child: _buildDiaryContent(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2022, 10, 16),
      lastDay: DateTime.utc(2025, 3, 14),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) => _diaryEvents[day] ?? [],
      onDaySelected: (selectedDay, focusedDay) {
        if (_diaryEvents.containsKey(selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        }
      },
      calendarStyle: CalendarStyle(
        markersMaxCount: 1,
        markerDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        cellMargin: EdgeInsets.only(left: 4.0, right: 4.0),
        cellPadding: EdgeInsets.zero,
        tablePadding: EdgeInsets.symmetric(horizontal: 50),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontSize: 10),
        weekendStyle: TextStyle(fontSize: 10),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false, // Hide the format button
        titleTextStyle: TextStyle(fontSize: 16),
        leftChevronIcon: Icon(Icons.chevron_left, size: 20),
        rightChevronIcon: Icon(Icons.chevron_right, size: 20),
      ),
      rowHeight: 25,
      daysOfWeekHeight: 20,
    );
  }

  Widget _buildDiaryContent() {
    final diaries = _diaryEvents[_selectedDay];
    if (diaries == null || diaries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No diary entry for this date, wear Kepler Star to automatically record your diary',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    final diary = diaries.first;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (diary.footprintJpeg != null)
            Image.memory(base64Decode(diary.footprintJpeg!)),
          SizedBox(height: 16),
          Text(diary.content),
          SizedBox(height: 16),
          Text('Related Memories:'),
          ...diary.memoryIds.map((id) => Text('- $id')),
        ],
      ),
    );
  }
}
