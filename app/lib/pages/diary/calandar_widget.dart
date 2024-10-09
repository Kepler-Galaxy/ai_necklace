import 'package:flutter/material.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:friend_private/utils/other/temp.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:friend_private/generated/l10n.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final Set<DateTime> diaryDates;
  final Function(DateTime, DateTime) onDaySelected;

  const CalendarWidget({
    Key? key,
    required this.selectedDay,
    required this.focusedDay,
    required this.diaryDates,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  bool _isCalendarExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateTimeFormat('MMM d, yyyy', widget.selectedDay),
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
                      S.current.SelectAnotherDay,
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
            focusedDay: widget.focusedDay,
            selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              widget.onDaySelected(selectedDay, focusedDay);
              setState(() {
                _isCalendarExpanded = false;
              });
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
            eventLoader: (day) {
              return widget.diaryDates.contains(_normalizeDate(day)) ? [Object()] : [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      width: 6.0,
                      height: 6.0,
                    ),
                  );
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
