import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';

/// 급식 화면 주간 캘린더 스트립
/// - TableCalendar를 주간(week) 포맷으로 표시
/// - 월요일 시작, 한국어 로케일 적용
/// - 선택된 날짜와 오늘 날짜를 시각적으로 구분
/// - 날짜 선택 시 콜백으로 부모에 전달
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
            rowHeight: 48,
            daysOfWeekHeight: 24,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              selectedDecoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: AppColors.theme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
              weekendTextStyle: TextStyle(color: Colors.white.withAlpha(200)),
              defaultTextStyle: const TextStyle(color: Colors.white),
              outsideDaysVisible: false,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.white.withAlpha(160), fontSize: 13),
              weekdayStyle: TextStyle(color: Colors.white.withAlpha(160), fontSize: 13),
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
