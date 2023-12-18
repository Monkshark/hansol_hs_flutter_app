import 'dart:convert';
import 'package:hansol_high_school/Data/ScheduleData.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataBase {
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
}
