import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:friend_private/providers/diary_provider.dart';
import 'package:friend_private/pages/diary/memory_chains_view.dart';
import 'package:friend_private/backend/http/api/memories.dart';
import 'package:friend_private/backend/schema/memory_connection.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:friend_private/pages/diary/calandar_widget.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  DateTime? _currentDiaryDate;

  List<String> _selectedDayMemoryIds = [];
  List<MemoryConnectionNode> _memoryChainForest = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDiaryDate = DateTime.now();
    // TODO(yiqi): cache diarys and memory chains data on the device.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDiariesAndMemoryChainData();
    });
  }

  Future<void> _loadDiariesAndMemoryChainData() async {
    await _loadDiaries();
    await _loadMemoryChainData();
  }

  Future<void> _loadDiaries() async {
    setState(() => _isLoading = true);
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    await diaryProvider.loadAllDiaries();

    setState(() {
      _currentDiaryDate =
          _findClosestDiaryDate(DateTime.now()) ?? DateTime.now();
      _isLoading = false;
    });
    _updateSelectedDayMemoryIds();
  }

  void _updateSelectedDayMemoryIds() {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    // TODO(yiqi): How to let user choose from multiple diaries in the UI?
    final diaries = diaryProvider.getDiariesForDay(_currentDiaryDate!);
    if (diaries.isNotEmpty) {
      final diary = diaries.first;
      setState(() {
        _selectedDayMemoryIds = diary.description.memoryIds;
      });
    } else {
      setState(() {
        _selectedDayMemoryIds = [];
      });
    }
  }

  // TODO(yiqi): Memory chain data should be cached in someway. Maybe through a different provider.
  Future<void> _loadMemoryChainData() async {
    if (_selectedDayMemoryIds.isEmpty) {
      setState(() {
        _memoryChainForest = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final response = await getMemoryConnectionsGraph(_selectedDayMemoryIds, 3);
    final forest = (response['forest'] as List)
        .map((tree) => MemoryConnectionNode.fromJson(tree))
        .toList();
    setState(() {
      _memoryChainForest = forest;
      _isLoading = false;
    });
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
      backgroundColor: Colors.black,
      body: Column(
        children: [
          CalendarWidget(
            selectedDay: _currentDiaryDate ?? DateTime.now(),
            focusedDay: _currentDiaryDate ?? DateTime.now(),
            diaryDates: Provider.of<DiaryProvider>(context).getDiaryDates(),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_currentDiaryDate, selectedDay)) {
                setState(() {
                  _currentDiaryDate = selectedDay;
                });
                _updateSelectedDayMemoryIds();
                _loadMemoryChainData();
              }
            },
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        MemoryChainsView(forest: _memoryChainForest),
                        _buildDiaryContent(),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryContent() {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    final diaries = diaryProvider.getDiariesForDay(_currentDiaryDate!);
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
          // if (diary.content.footprintJpeg == null ||
          //     diary.content.footprintJpeg!.isEmpty)
          //   Text(
          //       'Footprint image not available, try set app location permission to always allow to enable this feature',
          //       style: TextStyle(color: const Color.fromARGB(255, 189, 0, 157)))
          // else
          //   Image.memory(
          //     base64Decode(diary.content.footprintJpeg!),
          //   ),
          // SizedBox(height: 16),
          Text(utf8.decode(diary.content.content.codeUnits)),
        ],
      ),
    );
  }
}
