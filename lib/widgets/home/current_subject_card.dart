import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/data/subject_data_manager.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/**
 * 현재/다음 교시 실시간 표시 카드
 * - 1분 주기 타이머로 현재 시각에 맞는 교시 자동 갱신
 * - 수업 중일 때 진행률 프로그레스바 표시
 * - 다음 교시 과목명과 시간 정보 함께 표시
 * - 주말/수업 없음/학년 미설정 상태별 안내 메시지 제공
 */
class CurrentSubjectCard extends StatefulWidget {
  const CurrentSubjectCard({Key? key}) : super(key: key);

  @override
  State<CurrentSubjectCard> createState() => _CurrentSubjectCardState();
}

class _CurrentSubjectCardState extends State<CurrentSubjectCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static const _periodTimes = [
    [8, 40, 9, 30],
    [9, 40, 10, 30],
    [10, 40, 11, 30],
    [11, 40, 12, 30],
    [13, 30, 14, 20],
    [14, 30, 15, 20],
    [15, 30, 16, 20],
  ];

  String _formatTime(int h, int m) {
    final period = h < 12 ? '오전' : '오후';
    final hour = h > 12 ? h - 12 : h;
    return '$period $hour:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!SettingData().isGradeSet) {
      return _buildEmptyCard(context, '학년/반을 설정하면\n시간표가 표시됩니다');
    }

    final now = _now;
    if (now.weekday > 5) {
      return _buildEmptyCard(context, '주말에는 수업이 없어요');
    }

    return FutureBuilder<List<String>>(
      future: _getTodaySubjects(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyCard(context, '오늘 시간표를 불러오는 중...');
        }

        final subjects = snapshot.data!;
        final nowMinutes = now.hour * 60 + now.minute;

        int currentPeriod = -1;
        int nextPeriod = -1;

        for (int i = 0; i < _periodTimes.length && i < subjects.length; i++) {
          if (subjects[i].isEmpty) continue;
          final startMin = _periodTimes[i][0] * 60 + _periodTimes[i][1];
          final endMin = _periodTimes[i][2] * 60 + _periodTimes[i][3];

          if (nowMinutes >= startMin && nowMinutes < endMin) {
            currentPeriod = i;
          } else if (nowMinutes < startMin && nextPeriod == -1) {
            nextPeriod = i;
          }
        }

        if (currentPeriod >= 0) {
          int afterCurrent = -1;
          for (int i = currentPeriod + 1; i < subjects.length && i < _periodTimes.length; i++) {
            if (subjects[i].isNotEmpty) { afterCurrent = i; break; }
          }
          return _buildSubjectCard(context,
            period: currentPeriod, subject: subjects[currentPeriod],
            nextPeriod: afterCurrent >= 0 ? afterCurrent : null,
            nextSubject: afterCurrent >= 0 ? subjects[afterCurrent] : null,
            nowMinutes: nowMinutes, isCurrently: true);
        } else if (nextPeriod >= 0) {
          int afterNext = -1;
          for (int i = nextPeriod + 1; i < subjects.length && i < _periodTimes.length; i++) {
            if (subjects[i].isNotEmpty) { afterNext = i; break; }
          }
          return _buildSubjectCard(context,
            period: nextPeriod, subject: subjects[nextPeriod],
            nextPeriod: afterNext >= 0 ? afterNext : null,
            nextSubject: afterNext >= 0 ? subjects[afterNext] : null,
            nowMinutes: nowMinutes, isCurrently: false);
        } else {
          return _buildEmptyCard(context, '오늘 남은 수업이 없어요');
        }
      },
    );
  }

  Future<List<String>> _getTodaySubjects() async {
    final grade = SettingData().grade;
    final classNum = SettingData().classNum;
    final now = _now;

    if (grade == 1) {
      final timetable = await TimetableDataApi.getTimeTable(
        startDate: now, endDate: now,
        grade: grade.toString(), classNum: classNum.toString(),
      );
      final dateKey = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final classMap = timetable[dateKey];
      if (classMap == null) return [];
      return classMap.values.first;
    } else {
      final selected = await SubjectDataManager.loadSelectedSubjects(grade);
      final selectedMap = <String, int>{};
      for (var s in selected) {
        selectedMap[s.subjectName] = s.subjectClass;
      }

      final timetable = await TimetableDataApi.getTimeTable(
        startDate: now, endDate: now, grade: grade.toString(),
      );
      final dateKey = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final classMap = timetable[dateKey];
      if (classMap == null) return [];

      const maxPeriods = 7;
      final result = List.filled(maxPeriods, '');
      classMap.forEach((cn, subjects) {
        if (cn == 'error') return;
        final classInt = cn == 'special' ? -1 : (int.tryParse(cn) ?? -1);
        for (int p = 0; p < subjects.length && p < maxPeriods; p++) {
          final name = subjects[p];
          if (name.isEmpty) continue;
          if (selectedMap.containsKey(name) && selectedMap[name] == classInt) {
            result[p] = name;
          }
        }
      });
      return result;
    }
  }

  Widget _buildSubjectCard(BuildContext context, {
    required int period, required String subject,
    int? nextPeriod, String? nextSubject,
    required int nowMinutes, required bool isCurrently,
  }) {
    final times = _periodTimes[period];
    final startMin = times[0] * 60 + times[1];
    final endMin = times[2] * 60 + times[3];
    final progress = isCurrently
        ? ((nowMinutes - startMin) / (endMin - startMin)).clamp(0.0, 1.0)
        : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${period + 1}교시는',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                  Text('$subject${isCurrently ? "이에요!" : " 시작 예정"}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  if (nextPeriod != null && nextSubject != null)
                    Text('${nextPeriod + 1}교시 $nextSubject',
                      style: TextStyle(fontSize: 13, color: AppColors.theme.mealTypeTextColor)),
                  const SizedBox(height: 4),
                  Text('${_formatTime(times[0], times[1])} - ${_formatTime(times[2], times[3])}',
                    style: TextStyle(fontSize: 12, color: AppColors.theme.mealTypeTextColor)),
                ],
              )),
              Container(width: 56, height: 56,
                decoration: BoxDecoration(
                  color: isCurrently ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor,
                  shape: BoxShape.circle),
                child: Icon(isCurrently ? Icons.menu_book : Icons.schedule,
                  color: Colors.white, size: 28)),
            ]),
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress,
                backgroundColor: AppColors.theme.lightGreyColor,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.theme.primaryColor),
                minHeight: 4)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Expanded(child: Text(message,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
              color: AppColors.theme.mealTypeTextColor))),
          Container(width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.theme.lightGreyColor, shape: BoxShape.circle),
            child: Icon(Icons.event_note, color: AppColors.theme.darkGreyColor, size: 28)),
        ]),
      ),
    );
  }
}
