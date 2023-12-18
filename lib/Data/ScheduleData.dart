import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Schedule {
  final int startTime;
  final int endTime;
  final String content;
  final String date;

  Schedule({
    required this.startTime,
    required this.endTime,
    required this.content,
    required this.date, // And this line
  });
}

Stream<List<Schedule>> watchSchedules(DateTime date) async* {
  final prefs = await SharedPreferences.getInstance();
  final schedules = prefs.getStringList('schedules') ?? [];

  yield schedules.map((schedule) {
    final decodedSchedule = jsonDecode(schedule) as Map<String, dynamic>;
    return Schedule(
      startTime: decodedSchedule['startTime'],
      endTime: decodedSchedule['endTime'],
      content: decodedSchedule['content'],
      date: decodedSchedule['date'],
    );
  }).where((schedule) {
    final scheduleDate = DateTime.parse(schedule.date);
    return scheduleDate.year == date.year &&
        scheduleDate.month == date.month &&
        scheduleDate.day == date.day;
  }).toList();
}
