import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';

/**
 * 일정 화면 월간 캘린더
 * - TableCalendar 기반 월간 뷰, 한국어 로케일 적용
 * - 토요일(파란색), 일요일(빨간색) 커스텀 색상 처리
 * - 오늘/선택 날짜를 primaryColor로 시각 구분
 * - 다크/라이트 테마 자동 대응
 */
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEEEEEE) : const Color(0xFF1E1E1E);
    final subColor = isDark ? const Color(0xFF8B8F99) : const Color(0xFF999999);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TableCalendar(
        locale: 'ko_KR',
        onDaySelected: (selectedDay, focusedDay) {
          widget.onDaySelected(selectedDay, focusedDay);
          setState(() => this.focusedDay = selectedDay);
        },
        selectedDayPredicate: (date) =>
            date.year == widget.selectedDate.year &&
            date.month == widget.selectedDate.month &&
            date.day == widget.selectedDate.day,
        firstDay: DateTime.utc(1800, 1, 1),
        lastDay: DateTime.utc(3000, 1, 1),
        focusedDay: focusedDay,
        rowHeight: 42,
        daysOfWeekHeight: 32,
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          headerPadding: const EdgeInsets.symmetric(vertical: 12),
          titleTextStyle: TextStyle(
            color: textColor,
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: textColor, size: 22),
          rightChevronIcon: Icon(Icons.chevron_right, color: textColor, size: 22),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w600),
          weekendStyle: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.all(3),
          defaultTextStyle: TextStyle(color: textColor, fontSize: 14),
          weekendTextStyle: TextStyle(color: textColor, fontSize: 14),
          outsideTextStyle: TextStyle(color: textColor.withAlpha(80), fontSize: 14),
          todayDecoration: BoxDecoration(
            color: AppColors.theme.primaryColor.withAlpha(40),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: AppColors.theme.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          selectedDecoration: BoxDecoration(
            color: AppColors.theme.primaryColor,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
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
                  style: const TextStyle(color: Color(0xFF5B8DEF), fontSize: 14),
                ),
              );
            } else if (day.weekday == DateTime.sunday) {
              return Center(
                child: Text(
                  day.day.toString(),
                  style: const TextStyle(color: Color(0xFFEF5B5B), fontSize: 14),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}
