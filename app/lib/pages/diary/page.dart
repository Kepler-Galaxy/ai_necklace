import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:friend_private/providers/diary_provider.dart';
import 'package:friend_private/backend/schema/diary.dart';
import 'package:friend_private/backend/schema/memory.dart';
import 'package:friend_private/widgets/extensions/string.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'dart:convert';
import 'package:friend_private/providers/memory_provider.dart';
import 'package:friend_private/pages/memory_detail/page.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  bool _isLoading = true;
  List<ServerMemory> _relatedMemories = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    // TODO(yiqi): don't load diaries and related memories every time the page is loaded.
    // Use cached data if available.
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
        _selectedDay = _findClosestDiaryDate(DateTime.now()) ?? DateTime.now();
        _focusedDay = _selectedDay;
        _isLoading = false;
      });
      _loadRelatedMemories();
    } catch (e) {
      print("Error loading diaries: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadRelatedMemories() async {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    final diaries = diaryProvider.getDiariesForDay(_selectedDay);
    if (diaries.isNotEmpty) {
      final diary = diaries.first;
      final memoryProvider =
          Provider.of<MemoryProvider>(context, listen: false);
      _relatedMemories = await memoryProvider.getMemoriesByIds(diary.memoryIds);
      setState(() {});
    }
  }

  DateTime? _findClosestDiaryDate(DateTime date) {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    final diaryEventMap = diaryProvider.getDiaryEventMap();
    final sortedDates = diaryEventMap.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    if (sortedDates.isEmpty) {
      return null;
    }

    try {
      return sortedDates.firstWhere(
        (d) => d.isAfter(date) || isSameDay(d, date),
        orElse: () => sortedDates.last,
      );
    } catch (e) {
      print("Error finding closest diary date: $e");
      return null;
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
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: _buildCalendar(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildDiaryContent(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    return TableCalendar(
      firstDay: DateTime.utc(2022, 10, 16),
      lastDay: DateTime.utc(2025, 3, 14),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) => diaryProvider.getDiariesForDay(day),
      onDaySelected: (selectedDay, focusedDay) {
        if (diaryProvider.getDiariesForDay(selectedDay).isNotEmpty) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _loadRelatedMemories();
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
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    final diaries = diaryProvider.getDiariesForDay(_selectedDay);
    if (diaries.isEmpty) {
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
          if (diary.footprintJpeg == null || diary.footprintJpeg!.isEmpty)
            Text(
                'Footprint image not available, try set app location permission to always allow to enable this feature',
                style: TextStyle(color: const Color.fromARGB(255, 189, 0, 157)))
          else
            Image.memory(
              base64Decode(diary.footprintJpeg!),
            ),
          SizedBox(height: 16),
          Text(diary.content.decodeSting),
          SizedBox(height: 16),
          Text("Number of related memories: " +
              _relatedMemories.length.toString()),
          SizedBox(height: 16),
          Text('Related Memories:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._relatedMemories.map((memory) => _buildMemoryItem(memory)),
        ],
      ),
    );
  }

  Widget _buildMemoryItem(ServerMemory memory) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: GradientBoxBorder(
          gradient: LinearGradient(colors: [
            Color.fromARGB(127, 208, 208, 208),
            Color.fromARGB(127, 188, 99, 121),
            Color.fromARGB(127, 86, 101, 182),
            Color.fromARGB(127, 126, 190, 236)
          ]),
          width: 1,
        ),
        shape: BoxShape.rectangle,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(
          memory.structured.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          memory.structured.category,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MemoryDetailPage(memory: memory, isPopup: true),
            ),
          );
        },
      ),
    );
  }
}
