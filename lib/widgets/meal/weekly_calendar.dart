import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';
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
  State<WeeklyCalendar> createState() => _WeeklyCalendarState();
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_focusedDay.year}년 ${_focusedDay.month}월',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.sp(context, 18),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          TableCalendar(
            locale: Localizations.localeOf(context).toString(),
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              widget.onDaySelected(selectedDay);
            },
            calendarFormat: CalendarFormat.week,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            rowHeight: Responsive.h(context, 48),
            daysOfWeekHeight: Responsive.h(context, 24),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: Colors.white, fontSize: Responsive.sp(context, 14), fontWeight: FontWeight.w700),
              selectedDecoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: AppColors.theme.primaryColor,
                fontSize: Responsive.sp(context, 14),
                fontWeight: FontWeight.w700,
              ),
              weekendTextStyle: TextStyle(color: Colors.white.withAlpha(200), fontSize: Responsive.sp(context, 14)),
              defaultTextStyle: TextStyle(color: Colors.white, fontSize: Responsive.sp(context, 14)),
              outsideDaysVisible: false,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.white.withAlpha(160), fontSize: Responsive.sp(context, 13)),
              weekdayStyle: TextStyle(color: Colors.white.withAlpha(160), fontSize: Responsive.sp(context, 13)),
            ),
            headerVisible: false,
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
