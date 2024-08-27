import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles.dart';
import 'package:table_calendar/table_calendar.dart';

class WeeklyCalendar extends StatefulWidget {
  final Color backgroundColor;
  final Function(DateTime) onDaySelected;

  const WeeklyCalendar({
    Key? key,
    required this.backgroundColor,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  _WeeklyCalendarState createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<WeeklyCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TableCalendar(
              // locale: 'ko_KR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                widget.onDaySelected(selectedDay);
              },
              calendarFormat: CalendarFormat.week,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: LIGHTER_COLOR,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: PRIMARY_COLOR,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: Colors.white),
                defaultTextStyle: const TextStyle(color: Colors.white),
                outsideDaysVisible: false,
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekendStyle: const TextStyle(color: Colors.white),
                weekdayStyle: const TextStyle(color: Colors.white),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Colors.white),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: Colors.white),
              ),
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0),
            child: Row(
              key: ValueKey<DateTime>(_focusedDay),
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final day = _focusedDay
                    .add(Duration(days: index - _focusedDay.weekday + 1));
                final isSelected = isSameDay(day, _selectedDay);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFD0DBFF)
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getCircleColor(day),
                          ),
                          width: 30,
                          height: 30,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCircleColor(DateTime day) {
    final int dayHash = day.year * 10000 + day.month * 100 + day.day;
    final int colorCode = dayHash % 3;

    switch (colorCode) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.yellow;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

// Color _getCircleColor(int score) {
  //   if (score >= 66) {
  //     return Colors.green;
  //   } else if (score >= 33) {
  //     return Colors.yellow;
  //   } else {
  //     return Colors.red;
  //   }
  // }
}
