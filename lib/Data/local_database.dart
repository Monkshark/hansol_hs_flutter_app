import 'dart:convert';
import 'package:hansol_high_school/Data/schedule_data.dart';
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

  Future<void> deleteSchedule(Schedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    final schedules = prefs.getStringList('schedules') ?? [];

    final scheduleIndex = schedules.indexWhere((storedSchedule) {
      final decodedSchedule =
          jsonDecode(storedSchedule) as Map<String, dynamic>;
      return decodedSchedule['startTime'] == schedule.startTime &&
          decodedSchedule['endTime'] == schedule.endTime &&
          decodedSchedule['content'] == schedule.content &&
          decodedSchedule['date'] == schedule.date;
    });

    if (scheduleIndex != -1) {
      schedules.removeAt(scheduleIndex);
      await prefs.setStringList('schedules', schedules);
    }
  }
}
