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
  Map<String, List<int>> _personalEventColors = {};
  List<PersonalEventBar> _personalBars = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPersonalEvents();
  }

  Future<void> _loadPersonalEvents() async {
    final db = GetIt.I<LocalDataBase>();
    final allSchedules = await db.getSchedulesForDateRange(
      DateTime(selectedDate.year, selectedDate.month, 1), 31);
    final map = <String, Set<int>>{};
    for (final s in allSchedules) {
      if (s.endDate != null) continue; // 연속일정은 바로 표시, 점은 생략
      map.putIfAbsent(s.date.substring(0, 10), () => {}).add(s.color);
    }
    final barList = <PersonalEventBar>[];
    for (final s in allSchedules) {
      if (s.endDate != null) {
        barList.add(PersonalEventBar(
          name: s.content,
          startDate: s.date.substring(0, 10),
          endDate: s.endDate!.substring(0, 10),
          color: s.color,
        ));
      }
    }
    if (mounted) setState(() {
      _personalEventColors = map.map((k, v) => MapEntry(k, v.toList()));
      _personalBars = barList;
    });
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
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ScheduleBottomSheet(
              selectedDate: selectedDate,
              onScheduleCreated: () { _loadData(); _loadPersonalEvents(); },
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
              personalEvents: _personalEventColors,
              personalBars: _personalBars,
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

    final isMultiDay = schedule.endDate != null;

    return Dismissible(
      key: ValueKey(schedule.id ?? '${schedule.content}_${schedule.date}_$index'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (!isMultiDay) return true;

        final result = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2028) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(width: 36, height: 4, decoration: BoxDecoration(
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Text('연속 일정 삭제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.today, color: Colors.orange),
                      title: const Text('이 날만 삭제'),
                      onTap: () => Navigator.pop(ctx, 'this'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep, color: Colors.red),
                      title: const Text('전체 일정 삭제', style: TextStyle(color: Colors.red)),
                      onTap: () => Navigator.pop(ctx, 'all'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );

        if (result == null) return false;

        if (result == 'all') {
          return true; // onDismissed에서 전체 삭제
        }

        // 이 날만 제외: 연속일정 분할
        await _excludeDateFromSchedule(schedule, selectedDate);
        _loadData();
        _loadPersonalEvents();
        return false; // Dismissible 자체 삭제 안 함
      },
      onDismissed: (_) {
        setState(() => _schedules.removeAt(index));
        GetIt.I<LocalDataBase>().deleteSchedule(schedule);
        _loadPersonalEvents();
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
        color: schedule.color,
        endDate: schedule.endDate,
        date: schedule.date,
      ),
    );
  }

  Future<void> _excludeDateFromSchedule(Schedule schedule, DateTime excludeDate) async {
    final db = GetIt.I<LocalDataBase>();
    final start = DateTime.parse(schedule.date);
    final end = DateTime.parse(schedule.endDate!);
    final startStr = schedule.date;
    final endStr = schedule.endDate!;

    // 원본 삭제
    await db.deleteSchedule(schedule);

    // 제외일 앞쪽 (start ~ 제외일-1)
    final beforeEnd = excludeDate.subtract(const Duration(days: 1));
    if (!beforeEnd.isBefore(start)) {
      final bEndStr = beforeEnd.toIso8601String().substring(0, 10);
      await db.insertSchedule(Schedule(
        startTime: -1, endTime: -1,
        content: schedule.content,
        date: startStr,
        endDate: startStr == bEndStr ? null : bEndStr,
        color: schedule.color,
      ));
    }

    // 제외일 뒤쪽 (제외일+1 ~ end)
    final afterStart = excludeDate.add(const Duration(days: 1));
    if (!afterStart.isAfter(end)) {
      final aStartStr = afterStart.toIso8601String().substring(0, 10);
      await db.insertSchedule(Schedule(
        startTime: -1, endTime: -1,
        content: schedule.content,
        date: aStartStr,
        endDate: aStartStr == endStr ? null : endStr,
        color: schedule.color,
      ));
    }
  }

  void onDaySelected(DateTime selectedDate, DateTime focusedDay) {
    this.selectedDate = selectedDate;
    _loadData();
  }
}
