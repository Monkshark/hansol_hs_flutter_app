import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hansol_high_school/Data/LocalDatabase.dart';
import 'package:hansol_high_school/Data/ScheduleData.dart';
import 'package:hansol_high_school/Widgets/MainCalendar.dart';
import 'package:hansol_high_school/Widgets/ScheduleBottomSheet.dart';
import 'package:hansol_high_school/Widgets/ScheduleCard.dart';
import 'package:hansol_high_school/Widgets/TodayBanner.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HansolHighSchool extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NoticeScreen(),
    );
  }
}

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({Key? key}) : super(key: key);

  @override
  _NoticeScreenState createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  DateTime selectedDate = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: PRIMARY_COLOR,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (_) => ScheduleBottomSheet(
              selectedDate: selectedDate,
              onScheduleCreated: () {
                setState(() {});
              },
            ),
            isScrollControlled: true,
            isDismissible: true,
          );
        },
        child: const Icon(
          Icons.add,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            MainCalendar(
              selectedDate: selectedDate,
              onDaySelected: onDaySelected,
            ),
            const SizedBox(height: 8.0),
            StreamBuilder<List<Schedule>>(
              stream: GetIt.I<LocalDataBase>().watchSchedules(selectedDate),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container();

                return TodayBanner(
                  selectedDate: selectedDate,
                  count: snapshot.data!.length ?? 0,
                );
              },
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: StreamBuilder<List<Schedule>>(
                stream: GetIt.I<LocalDataBase>().watchSchedules(selectedDate),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Container();

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final schedule = snapshot.data![index];
                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          final prefs = await SharedPreferences.getInstance();
                          final scheduleStrings =
                              prefs.getStringList('schedules') ?? [];
                          final schedules = scheduleStrings.map((schedule) {
                            return jsonDecode(schedule) as Map<String, dynamic>;
                          }).toList();
                          final selectedDateSchedules =
                              schedules.where((schedule) {
                            return DateTime.parse(schedule['date']).day ==
                                    selectedDate.day &&
                                DateTime.parse(schedule['date']).month ==
                                    selectedDate.month &&
                                DateTime.parse(schedule['date']).year ==
                                    selectedDate.year;
                          }).toList();
                          final scheduleToRemove = selectedDateSchedules[index];
                          schedules.remove(scheduleToRemove);
                          final updatedScheduleStrings =
                              schedules.map((schedule) {
                            return jsonEncode(schedule);
                          }).toList();
                          await prefs.setStringList(
                              'schedules', updatedScheduleStrings);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('일정 삭제됨'),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 8.0,
                            left: 8.0,
                            right: 8.0,
                          ),
                          child: ScheduleCard(
                            startTime: schedule.startTime,
                            endTime: schedule.endTime,
                            content: schedule.content,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onDaySelected(DateTime selectedDate, DateTime focusedDay) {
    setState(() {
      this.selectedDate = selectedDate;
    });
  }
}
