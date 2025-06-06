import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/notice_data_api.dart';
import 'package:hansol_high_school/data/local_database.dart';
import 'package:hansol_high_school/data/schedule_data.dart';
import 'package:hansol_high_school/widgets/alert/delete_alert_dialog.dart';
import 'package:hansol_high_school/Widgets/calendar/main_calendar.dart';
import 'package:hansol_high_school/Widgets/calendar/schedule_bottom_sheet.dart';
import 'package:hansol_high_school/Widgets/calendar/schedule_card.dart';
import 'package:hansol_high_school/Widgets/calendar/school_schedule_card.dart';
import 'package:hansol_high_school/Widgets/calendar/today_banner.dart';
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({Key? key}) : super(key: key);

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
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

  Future<bool> hasSchoolSchedule(DateTime date) async {
    final schoolSchedule = await NoticeDataApi().getNotice(date: date);
    return schoolSchedule != null && schoolSchedule != '학사일정이 없습니다';
  }

  Future<bool> hasPersonalSchedules(DateTime date) async {
    final schedulesStream = GetIt.I<LocalDataBase>().watchSchedules(date);
    final schedules = await schedulesStream.first;
    return schedules.isNotEmpty;
  }

  Future<bool> hasAnySchedule(DateTime date) async {
    final schoolScheduleExists = await hasSchoolSchedule(date);
    final personalSchedulesExist = await hasPersonalSchedules(date);
    return schoolScheduleExists || personalSchedulesExist;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.theme.primaryColor,
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
          color: Colors.white,
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

                return FutureBuilder<String?>(
                  future: NoticeDataApi().getNotice(date: selectedDate),
                  builder: (context, snapshot2) {
                    final schoolSchedule = snapshot2.data;
                    final hasSchoolSchedule = schoolSchedule != null &&
                        schoolSchedule != '학사일정이 없습니다';

                    final schedules = snapshot.data!;
                    final count =
                        schedules.length + (hasSchoolSchedule ? 1 : 0);

                    return TodayBanner(
                      selectedDate: selectedDate,
                      count: count,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: FutureBuilder<String?>(
                future: NoticeDataApi().getNotice(date: selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final schoolSchedule = snapshot.data;
                  final hasSchoolSchedule =
                      schoolSchedule != null && schoolSchedule != '학사일정이 없습니다';

                  return StreamBuilder<List<Schedule>>(
                    stream:
                        GetIt.I<LocalDataBase>().watchSchedules(selectedDate),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Container();

                      final schedules = snapshot.data!;
                      final itemCount =
                          schedules.length + (hasSchoolSchedule ? 1 : 0);

                      return ListView.builder(
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          if (hasSchoolSchedule && index == 0) {
                            return Dismissible(
                              key: UniqueKey(),
                              direction: DismissDirection.horizontal,
                              confirmDismiss: (direction) async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('학사일정은 삭제가 불가능합니다'),
                                  ),
                                );
                                return false;
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 8.0,
                                  left: 8.0,
                                  right: 8.0,
                                ),
                                child: SchoolScheduleCard(
                                  startTime: 8,
                                  endTime: 4,
                                  content: schoolSchedule!,
                                ),
                              ),
                            );
                          } else {
                            final schedule =
                                schedules[index - (hasSchoolSchedule ? 1 : 0)];

                            return Dismissible(
                              key: UniqueKey(),
                              direction: DismissDirection.horizontal,
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return const DeleteAlertDialog(
                                      title: '일정 삭제',
                                      content:
                                          '정말 일정을 삭제하시겠습니까?\n삭제 후에는 복구가 불가능합니다.',
                                    );
                                  },
                                );
                              },
                              onDismissed: (direction) async {
                                await GetIt.I<LocalDataBase>()
                                    .deleteSchedule(schedule);
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
                                  startTimeInMinutes: schedule.startTime,
                                  endTimeInMinutes: schedule.endTime,
                                  content: schedule.content,
                                ),
                              ),
                            );
                          }
                        },
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
