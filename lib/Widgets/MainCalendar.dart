import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

const PRIMARY_COLOR = Color(0xFF5C6BC0);
const SECONDARY_COLOR = Color(0xFF198A43);
final LIGHT_GREY_COLOR = Colors.grey[200]!;
final DARK_GREY_COLOR = Colors.grey[600]!;
final TEXT_FIELD_FILL_COLOR = Colors.grey[300]!;

class MainCalendar extends StatefulWidget {
  final OnDaySelected onDaySelected;
  final DateTime selectedDate;

  MainCalendar({
    required this.onDaySelected,
    required this.selectedDate,
  });

  @override
  _MainCalendarState createState() => _MainCalendarState();
}

class _MainCalendarState extends State<MainCalendar> {
  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      locale: 'ko_KR',
      onDaySelected: widget.onDaySelected,
      selectedDayPredicate: (date) =>
          date.year == widget.selectedDate.year &&
          date.month == widget.selectedDate.month &&
          date.day == widget.selectedDate.day,
      firstDay: DateTime.utc(1800, 1, 1),
      lastDay: DateTime.utc(3000, 1, 1),
      focusedDay: DateTime.now(),
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 16.0,
          fontWeight: FontWeight.w700,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          if (day.weekday == DateTime.saturday) {
            return Center(
              child: Text(
                day.day.toString(),
                style: const TextStyle(color: Colors.blue),
              ),
            );
          } else if (day.weekday == DateTime.sunday) {
            return Center(
              child: Text(
                day.day.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else {
            return null;
          }
        },
        // todayBuilder: (context, date, _) {
        //   return Center(
        //     child: Container(
        //       width: 40.0,
        //       height: 40.0,
        //       decoration: BoxDecoration(
        //         border: Border.all(
        //           color: PRIMARY_COLOR,
        //         ),
        //         shape: BoxShape.circle,
        //       ),
        //       child: Center(
        //         child: Text(
        //           date.day.toString(),
        //           style: const TextStyle(color: Colors.black),
        //         ),
        //       ),
        //     ),
        //   );
        // },
        // selectedBuilder: (context, date, _) {
        //   return Center(
        //     child: AnimatedContainer(
        //       width: 40.0,
        //       height: 40.0,
        //       decoration: const BoxDecoration(
        //         color: PRIMARY_COLOR,
        //         shape: BoxShape.circle,
        //       ),
        //       duration: const Duration(milliseconds: 300),
        //       child: Center(
        //         child: Text(
        //           date.day.toString(),
        //           style: const TextStyle(color: Colors.white),
        //         ),
        //       ),
        //     ),
        //   );
        // },
      ),
    );
  }
}
