import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:friend_private/providers/diary_provider.dart';
import 'package:friend_private/backend/schema/memory.dart';
import 'package:friend_private/widgets/extensions/string.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:friend_private/providers/memory_provider.dart';
import 'package:friend_private/pages/memory_detail/page.dart';
import 'package:friend_private/pages/diary/memory_chains_view.dart';
import 'package:friend_private/backend/http/api/memories.dart';
import 'package:friend_private/backend/schema/memory_connection.dart';
import 'package:friend_private/utils/other/temp.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  bool _isCalendarExpanded = false;
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  bool _isLoading = true;
  List<String> _selectedDayMemoryIds = [];
  List<MemoryConnectionNode> _memoryChainForest = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    // TODO(yiqi): don't load diaries and related memories every time the page is loaded.
    // Use cached data if available.
    // _loadDiaries();
    // _loadMemoryChainData();
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
    try {
      final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
      await diaryProvider.loadAllDiaries();
      setState(() {
        _selectedDay = _findClosestDiaryDate(DateTime.now()) ?? DateTime.now();
        _focusedDay = _selectedDay;
        _isLoading = false;
      });
      _updateSelectedDayMemoryIds();
    } catch (e) {
      print("Error loading diaries: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateSelectedDayMemoryIds() {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    final diaries = diaryProvider.getDiariesForDay(_selectedDay);
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

  Future<void> _loadMemoryChainData() async {
    if (_selectedDayMemoryIds.isEmpty) {
      debugPrint("No memory IDs selected for the day");
      setState(() {
        _memoryChainForest = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint("Fetching memory connections graph for ids: $_selectedDayMemoryIds");
      final response = await getMemoryConnectionsGraph(
        _selectedDayMemoryIds,
        3, // Number of levels
      );

      debugPrint("Received response: $response");

      if (response['forest'] != null) {
        debugPrint("Forest data: ${response['forest']}");
        if (response['forest'] is List) {
          final forest = (response['forest'] as List)
              .map((tree) => _parseMemoryConnectionNode(tree))
              .toList();

          if (mounted) {
            setState(() {
              _memoryChainForest = forest;
              _isLoading = false;
            });
            debugPrint("Memory chain forest length: ${_memoryChainForest.length}");
          } else {
            debugPrint("Widget was disposed before setState could be called");
          }
        } else {
          debugPrint("Forest is not a List: ${response['forest'].runtimeType}");
          if (mounted) {
            setState(() {
              _memoryChainForest = [];
              _isLoading = false;
            });
          }
        }
      } else {
        debugPrint("Forest is null in the response");
        if (mounted) {
          setState(() {
            _memoryChainForest = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading memory connections graph: $e');
      if (mounted) {
        setState(() {
          _memoryChainForest = [];
          _isLoading = false;
        });
      }
    }
  }

  MemoryConnectionNode _parseMemoryConnectionNode(Map<String, dynamic> node) {
    return MemoryConnectionNode.fromJson(node);
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
          SizedBox(
            child: _buildCalendar(),
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

  Widget _buildCalendar() {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateTimeFormat('MMM d, yyyy', _selectedDay),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isCalendarExpanded = !_isCalendarExpanded;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select Another Day',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.event, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isCalendarExpanded)
          TableCalendar(
            firstDay: DateTime.utc(2022, 10, 16),
            lastDay: DateTime.utc(2025, 3, 14),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => diaryProvider.getDiariesForDay(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _isCalendarExpanded =
                    false; // Collapse the calendar when a day is selected
              });
              _updateSelectedDayMemoryIds();
              _loadMemoryChainData();
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
              markerSize: 8,
              markerMargin: EdgeInsets.symmetric(horizontal: 1),
              markersAnchor: 1,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontSize: 10, color: Colors.white),
              weekendStyle: TextStyle(fontSize: 10, color: Colors.white),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleTextStyle: TextStyle(fontSize: 16, color: Colors.white),
              leftChevronIcon:
                  Icon(Icons.chevron_left, size: 20, color: Colors.white),
              rightChevronIcon:
                  Icon(Icons.chevron_right, size: 20, color: Colors.white),
            ),
            rowHeight: 25,
            daysOfWeekHeight: 20,
          ),
      ],
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
          if (diary.content.footprintJpeg == null || diary.content.footprintJpeg!.isEmpty)
            Text(
                'Footprint image not available, try set app location permission to always allow to enable this feature',
                style: TextStyle(color: const Color.fromARGB(255, 189, 0, 157)))
          else
            Image.memory(
              base64Decode(diary.content.footprintJpeg!),
            ),
          SizedBox(height: 16),
          Text(utf8.decode(diary.content.content.codeUnits)),
          // SizedBox(height: 16),
          // Text('Related Memories:',
          //     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          // ..._selectedDayMemoryIds.map((memoryId) => _buildMemoryItem(memoryId)),
        ],
      ),
    );
  }

  // Widget _buildMemoryItem(ServerMemory memory) {
  //   return Container(
  //     padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
  //     margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
  //     decoration: const BoxDecoration(
  //       color: Colors.black,
  //       borderRadius: BorderRadius.all(Radius.circular(16)),
  //       border: GradientBoxBorder(
  //         gradient: LinearGradient(colors: [
  //           Color.fromARGB(127, 208, 208, 208),
  //           Color.fromARGB(127, 188, 99, 121),
  //           Color.fromARGB(127, 86, 101, 182),
  //           Color.fromARGB(127, 126, 190, 236)
  //         ]),
  //         width: 1,
  //       ),
  //       shape: BoxShape.rectangle,
  //     ),
  //     child: ListTile(
  //       contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //       title: Text(
  //         memory.structured.title,
  //         style: TextStyle(
  //           color: Colors.white,
  //           fontWeight: FontWeight.bold,
  //           fontSize: 18,
  //         ),
  //       ),
  //       subtitle: Text(
  //         memory.structured.category,
  //         style: TextStyle(
  //           color: Colors.white.withOpacity(0.8),
  //           fontSize: 14,
  //         ),
  //       ),
  //       trailing: Icon(
  //         Icons.arrow_forward_ios,
  //         color: Colors.white,
  //       ),
  //       onTap: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) =>
  //                 MemoryDetailPage(memory: memory, isPopup: true),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
}
