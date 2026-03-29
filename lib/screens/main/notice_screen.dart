import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/notice_data_api.dart';
import 'package:hansol_high_school/data/local_database.dart';
import 'package:hansol_high_school/data/schedule_data.dart';
import 'package:hansol_high_school/widgets/calendar/main_calendar.dart';
import 'package:hansol_high_school/widgets/calendar/schedule_bottom_sheet.dart';
import 'package:hansol_high_school/widgets/calendar/schedule_card.dart';
import 'package:hansol_high_school/widgets/calendar/school_schedule_card.dart';
import 'package:hansol_high_school/widgets/calendar/today_banner.dart';
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 일정 화면 (NoticeScreen)
///
/// - 월간 캘린더에서 날짜를 선택하여 일정 조회
/// - 개인 일정과 NEIS 학사일정을 함께 표시
/// - 바텀시트를 통한 개인 일정 추가 기능
/// - 스와이프 제스처로 개인 일정 삭제 지원
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

  final NoticeDataApi _noticeApi = NoticeDataApi();
  String? _schoolSchedule;
  List<Schedule> _schedules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final results = await Future.wait([
      _noticeApi.getNotice(date: selectedDate),
      GetIt.I<LocalDataBase>().watchSchedules(selectedDate).first,
    ]);

    if (mounted) {
      setState(() {
        _schoolSchedule = results[0] as String?;
        _schedules = results[1] as List<Schedule>;
        _loading = false;
      });
    }
  }

  bool get _hasSchool =>
      _schoolSchedule != null && _schoolSchedule != '학사일정이 없습니다';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF17191E) : const Color(0xFFF5F6F8);
    final itemCount = _schedules.length + (_hasSchool ? 1 : 0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.theme.primaryColor,
        elevation: 2,
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => ScheduleBottomSheet(
              selectedDate: selectedDate,
              onScheduleCreated: _loadData,
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            MainCalendar(
              selectedDate: selectedDate,
              onDaySelected: onDaySelected,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    TodayBanner(
                      selectedDate: selectedDate,
                      count: itemCount,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : itemCount == 0
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.event_note, size: 40, color: AppColors.theme.darkGreyColor),
                                      const SizedBox(height: 8),
                                      Text(
                                        '일정이 없습니다',
                                        style: TextStyle(fontSize: 14, color: AppColors.theme.darkGreyColor),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                    16, 0, 16,
                                    MediaQuery.of(context).padding.bottom + 80,
                                  ),
                                  itemCount: itemCount,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    if (_hasSchool && index == 0) {
                                      return _buildSchoolItem();
                                    }
                                    final scheduleIndex = index - (_hasSchool ? 1 : 0);
                                    return _buildPersonalItem(scheduleIndex);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolItem() {
    return SchoolScheduleCard(
      startTime: 8,
      endTime: 4,
      content: _schoolSchedule ?? '',
    );
  }

  Widget _buildPersonalItem(int index) {
    final schedule = _schedules[index];

    return Dismissible(
      key: ValueKey(schedule.id ?? '${schedule.content}_${schedule.date}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() => _schedules.removeAt(index));
        GetIt.I<LocalDataBase>().deleteSchedule(schedule);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ScheduleCard(
        startTimeInMinutes: schedule.startTime,
        endTimeInMinutes: schedule.endTime,
        content: schedule.content,
      ),
    );
  }

  void onDaySelected(DateTime selectedDate, DateTime focusedDay) {
    this.selectedDate = selectedDate;
    _loadData();
  }
}
