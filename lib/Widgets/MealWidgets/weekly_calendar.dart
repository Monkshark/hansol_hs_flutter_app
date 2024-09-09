import 'package:flutter/material.dart';
import 'package:hansol_high_school/Data/device.dart';
import 'package:hansol_high_school/Styles/app_colors.dart';
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
            padding: EdgeInsets.symmetric(
              horizontal: Device.getWidth(1.5),
            ),
            child: _buildCustomHeader(context),
          ),
          TableCalendar(
            locale: 'ko_KR',
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
                color: AppColors.color.lighterColor,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.color.primaryColor,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: const TextStyle(color: Colors.white),
              defaultTextStyle: const TextStyle(color: Colors.white),
              outsideDaysVisible: false,
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.white),
              weekdayStyle: TextStyle(color: Colors.white),
            ),
            headerVisible: false,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  Device.isTablet ? Device.width * 0.053 : Device.width * 0.03,
            ),
            child: Row(
              key: ValueKey<DateTime>(_focusedDay),
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final day = _focusedDay
                    .add(Duration(days: index - _focusedDay.weekday + 1));
                final isSelected = isSameDay(day, _selectedDay);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                      _focusedDay = day;
                    });
                    widget.onDaySelected(day);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FutureBuilder<LinearGradient>(
                        future: _getCircleColor(day),
                        builder: (context, snapshot) {
                          LinearGradient gradient;

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            gradient = const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xffF8F8F8),
                                Color(0xffA9A9A9),
                              ],
                            );
                          } else if (snapshot.hasError) {
                            gradient = const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xffF8F8F8),
                                Color(0xffA9A9A9),
                              ],
                            );
                          } else {
                            gradient = snapshot.data!;
                          }

                          return Container(
                            width: isSelected ? 32 : 36,
                            height: isSelected ? 32 : 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFD0DBFF)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: gradient,
                                ),
                                width: 30,
                                height: 30,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    final year = _focusedDay.year.toString();
    final month = _focusedDay.month.toString();

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          top: Device.getHeight(3),
          left: Device.getWidth(3),
          bottom: Device.getHeight(3),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: year,
                style: TextStyle(
                  color: Colors.white,
                  fontSize:
                      Device.isTablet ? Device.getWidth(3) : Device.getWidth(5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: '년 ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize:
                      Device.isTablet ? Device.getWidth(3) : Device.getWidth(5),
                ),
              ),
              TextSpan(
                text: month,
                style: TextStyle(
                  color: Colors.white,
                  fontSize:
                      Device.isTablet ? Device.getWidth(3) : Device.getWidth(5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: '월',
                style: TextStyle(
                  color: Colors.white,
                  fontSize:
                      Device.isTablet ? Device.getWidth(3) : Device.getWidth(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<LinearGradient> _getCircleColor(DateTime day) async {
    await Future.delayed(Duration(milliseconds: 100));
    final int dayHash = day.year * 10000 + day.month * 100 + day.day;
    final int colorCode = dayHash % 3;

    switch (colorCode) {
      case 0:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xffB6E9FF),
            Color(0xff4FCAFF),
          ],
        );
      case 1:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xffCEFBD5),
            Color(0xff60D32A),
          ],
        );
      case 2:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xffFFD0D0),
            Color(0xffFF4A4A),
          ],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xffF8F8F8),
            Color(0xffA9A9A9),
          ],
        );
    }
  }
}
