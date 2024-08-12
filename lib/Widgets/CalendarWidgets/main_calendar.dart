import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final calendarHeight = screenHeight * 0.4;
    final dayFontSize = calendarHeight * 0.05;

    return Container(
      height: calendarHeight,
      child: TableCalendar(
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
        daysOfWeekHeight: calendarHeight * 0.1,
        rowHeight: calendarHeight * 0.135,

        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: dayFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(fontSize: dayFontSize),
          weekendTextStyle: TextStyle(fontSize: dayFontSize, color: Colors.red),
          selectedTextStyle: TextStyle(fontSize: dayFontSize, color: Colors.white),
          todayTextStyle: TextStyle(fontSize: dayFontSize, color: Colors.blue),
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
                  style: TextStyle(color: Colors.blue, fontSize: dayFontSize),
                ),
              );
            } else if (day.weekday == DateTime.sunday) {
              return Center(
                child: Text(
                  day.day.toString(),
                  style: TextStyle(color: Colors.red, fontSize: dayFontSize),
                ),
              );
            } else {
              return Center(
                child: Text(
                  day.day.toString(),
                  style: TextStyle(fontSize: dayFontSize),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
