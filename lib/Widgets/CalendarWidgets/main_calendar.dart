import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

const PRIMARY_COLOR = Color(0xFF5C6BC0);
const SECONDARY_COLOR = Color(0xFF198A43);
final LIGHTER_COLOR = PRIMARY_COLOR.withOpacity(0.6);
final LIGHT_GREY_COLOR = Colors.grey[200]!;
final DARK_GREY_COLOR = Colors.grey[600]!;
final TEXT_FIELD_FILL_COLOR = Colors.grey[300]!;

class MainCalendar extends StatefulWidget {
  final OnDaySelected onDaySelected;
  final DateTime selectedDate;

  const MainCalendar({
    Key? key,
    required this.onDaySelected,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _MainCalendarState createState() => _MainCalendarState();
}

class _MainCalendarState extends State<MainCalendar> {
  DateTime focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      locale: 'en_US',
      onDaySelected: (selectedDay, focusedDay) {
        widget.onDaySelected(selectedDay, focusedDay);
        setState(() {
          this.focusedDay = selectedDay;
        });
      },
      selectedDayPredicate: (date) =>
          date.year == widget.selectedDate.year &&
          date.month == widget.selectedDate.month &&
          date.day == widget.selectedDate.day,
      firstDay: DateTime.utc(1800, 1, 1),
      lastDay: DateTime.utc(3000, 1, 1),
      focusedDay: focusedDay,
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 16.0,
          fontWeight: FontWeight.w700,
        ),
      ),
      availableCalendarFormats: const {
        CalendarFormat.month: 'yyyy - MM',
      },
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
      ),
    );
  }
}
