import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:hansol_high_school/data/subject.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/data/subject_data_manager.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 선택과목 설정 화면 (TimetableSelectScreen)
///
/// - 학년별 선택과목 목록에서 수강 과목 선택
/// - 선택 과목 간 시간표 충돌 자동 감지 및 경고
/// - 변경사항 저장 시 확인 다이얼로그 표시

class SubjectScheduleInfo {
  final String dayName;
  final int period;

  SubjectScheduleInfo({required this.dayName, required this.period});
}

class TimetableSelectScreen extends StatefulWidget {
  const TimetableSelectScreen({Key? key}) : super(key: key);

  @override
  State<TimetableSelectScreen> createState() => _TimetableSelectScreenState();
}

class _TimetableSelectScreenState extends State<TimetableSelectScreen> {
  late Future<Map<String, List<Subject>>> _subjectGroupsFuture;
  List<Subject> selectedSubjects = [];
  late int grade;
  bool _hasChanges = false;

  Map<String, List<SubjectScheduleInfo>> scheduleMap = {};
  Map<String, String> conflictMap = {};

  @override
  void initState() {
    super.initState();
    grade = SettingData().grade;
    _subjectGroupsFuture = _getSubjectGroups(grade);
    _initData(grade);
  }

  Future<void> _initData(int g) async {
    await Future.wait([
      _loadSelectedSubjects(g),
      _buildScheduleMap(g),
    ]);
    _checkConflicts();
    setState(() {});
  }

  Future<void> _loadSelectedSubjects(int g) async {
    selectedSubjects = await SubjectDataManager.loadSelectedSubjects(g);
  }

  Future<void> _saveSelectedSubjects() async {
    await SubjectDataManager.saveSelectedSubjects(grade, selectedSubjects);
  }

  Future<Map<String, List<Subject>>> _getSubjectGroups(int g) async {
    final allSubjects =
        await TimetableDataApi.getAllSubjectCombinations(grade: g);
    final groups = <String, List<Subject>>{};
    for (var subject in allSubjects) {
      groups.putIfAbsent(subject.subjectName, () => []).add(subject);
    }
    return groups;
  }

  Future<void> _buildScheduleMap(int g) async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final friday = monday.add(const Duration(days: 4));

    final timetable = await TimetableDataApi.getTimeTable(
      startDate: monday,
      endDate: friday,
      grade: g.toString(),
      classNum: null,
    );

    final map = <String, List<SubjectScheduleInfo>>{};
    const dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];

    timetable.forEach((dateStr, classMap) {
      if (dateStr == 'error') return;
      final date = DateTime(
        int.parse(dateStr.substring(0, 4)),
        int.parse(dateStr.substring(4, 6)),
        int.parse(dateStr.substring(6, 8)),
      );
      final weekday = date.weekday;
      if (weekday > 5) return;
      final dayName = dayNames[weekday];

      classMap.forEach((classNum, subjects) {
        if (classNum == 'error') return;
        final classInt = classNum == 'special' ? -1 : (int.tryParse(classNum) ?? -1);
        final normalizedClassNum = classInt.toString();
        for (int period = 0; period < subjects.length; period++) {
          final subjectName = subjects[period];
          if (subjectName.contains('[보강]') || subjectName == '토요휴업일') continue;

          final classInt = int.tryParse(normalizedClassNum) ?? -1;
          final key = '${subjectName}_$classInt';
          map.putIfAbsent(key, () => []).add(
            SubjectScheduleInfo(dayName: dayName, period: period + 1),
          );
        }
      });
    });

    setState(() => scheduleMap = map);
  }

  void _checkConflicts() {
    conflictMap.clear();
    if (selectedSubjects.length < 2) return;

    for (int i = 0; i < selectedSubjects.length; i++) {
      final a = selectedSubjects[i];
      final aKey = '${a.subjectName}_${a.subjectClass}';
      final aInfos = scheduleMap[aKey];
      if (aInfos == null) continue;

      for (int j = i + 1; j < selectedSubjects.length; j++) {
        final b = selectedSubjects[j];
        if (a.subjectName == b.subjectName) continue;

        final bKey = '${b.subjectName}_${b.subjectClass}';
        final bInfos = scheduleMap[bKey];
        if (bInfos == null) continue;

        for (var aInfo in aInfos) {
          for (var bInfo in bInfos) {
            if (aInfo.dayName == bInfo.dayName && aInfo.period == bInfo.period) {
              conflictMap[a.subjectName] =
                  '${aInfo.dayName} ${aInfo.period}교시에 ${b.subjectName}과(와) 겹침';
              conflictMap[b.subjectName] =
                  '${bInfo.dayName} ${bInfo.period}교시에 ${a.subjectName}과(와) 겹침';
              return; // 첫 번째 충돌만 표시
            }
          }
        }
      }
    }
  }

  String _getScheduleText(Subject subject) {
    final key = '${subject.subjectName}_${subject.subjectClass}';
    final infos = scheduleMap[key];
    if (infos == null || infos.isEmpty) return '';

    final unique = <String>{};
    final sorted = <SubjectScheduleInfo>[];
    const dayOrder = {'월': 1, '화': 2, '수': 3, '목': 4, '금': 5};

    for (var info in infos) {
      final tag = '${info.dayName}${info.period}';
      if (unique.add(tag)) sorted.add(info);
    }
    sorted.sort((a, b) {
      final dayDiff = (dayOrder[a.dayName] ?? 0) - (dayOrder[b.dayName] ?? 0);
      if (dayDiff != 0) return dayDiff;
      return a.period - b.period;
    });

    return sorted.map((s) => '${s.dayName} ${s.period}교시').join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('변경사항이 있습니다', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 12),
                    Text('저장하지 않고 나가시겠습니까?', style: TextStyle(
                      fontSize: 14, color: AppColors.theme.mealTypeTextColor)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('취소', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('나가기'),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
        if (discard == true && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        title: const Text('선택과목 설정'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_hasChanges)
            IconButton(
              onPressed: () async {
                await _saveSelectedSubjects();
                setState(() => _hasChanges = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('저장되었습니다')),
                  );
                }
              },
              icon: Icon(Icons.check, color: AppColors.theme.primaryColor, size: 28),
            ),
        ],
      ),
      body: FutureBuilder<Map<String, List<Subject>>>(
        future: _subjectGroupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined, size: 48, color: AppColors.theme.darkGreyColor),
                  const SizedBox(height: 12),
                  Text('과목을 불러올 수 없습니다', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                ],
              ),
            );
          }

          final groups = snapshot.data!;
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.theme.primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 20, color: AppColors.theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '${selectedSubjects.length}개 과목 선택됨',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 20),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final subjectName = groups.keys.elementAt(index);
                    final classes = groups[subjectName]!;
                    return _SubjectGroupCard(
                      subjectName: subjectName,
                      classes: classes,
                      selectedSubjects: selectedSubjects,
                      getScheduleText: _getScheduleText,
                      conflictText: conflictMap[subjectName],
                      onChanged: (subject, selected) {
                        setState(() {
                          selectedSubjects.removeWhere((s) => s.subjectName == subjectName);
                          if (selected) selectedSubjects.add(subject);
                          _hasChanges = true;
                          _checkConflicts();
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}

class _SubjectGroupCard extends StatelessWidget {
  final String subjectName;
  final List<Subject> classes;
  final List<Subject> selectedSubjects;
  final String Function(Subject) getScheduleText;
  final String? conflictText;
  final void Function(Subject subject, bool selected) onChanged;

  const _SubjectGroupCard({
    required this.subjectName,
    required this.classes,
    required this.selectedSubjects,
    required this.getScheduleText,
    required this.onChanged,
    this.conflictText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2028) : Colors.white;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final selected = selectedSubjects.where((s) => s.subjectName == subjectName).toList();

    return _SubjectSwipeCard(
      subjectName: subjectName,
      classes: classes,
      selected: selected.isNotEmpty ? selected.first : null,
      cardColor: cardColor,
      textColor: textColor,
      getScheduleText: getScheduleText,
      conflictText: conflictText,
      onChanged: onChanged,
    );
  }
}

class _SubjectSwipeCard extends StatefulWidget {
  final String subjectName;
  final List<Subject> classes;
  final Subject? selected;
  final Color cardColor;
  final Color textColor;
  final String Function(Subject) getScheduleText;
  final String? conflictText;
  final void Function(Subject subject, bool selected) onChanged;

  const _SubjectSwipeCard({
    required this.subjectName,
    required this.classes,
    required this.selected,
    required this.cardColor,
    required this.textColor,
    required this.getScheduleText,
    required this.onChanged,
    this.conflictText,
  });

  @override
  State<_SubjectSwipeCard> createState() => _SubjectSwipeCardState();
}

class _SubjectSwipeCardState extends State<_SubjectSwipeCard> {
  late PageController _pageController;
  late int _currentPage;
  static const int _loopMultiplier = 1000;

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) {
      _currentPage = widget.classes.indexWhere((s) => s == widget.selected);
      if (_currentPage == -1) _currentPage = 0;
    } else {
      _currentPage = 0;
    }
    final initialPage = widget.classes.length > 1
        ? _loopMultiplier * widget.classes.length + _currentPage
        : _currentPage;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isChecked = widget.selected != null;
    final classCount = widget.classes.length;

    final hasConflict = widget.conflictText != null;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasConflict
                ? const Color(0xFFFF9800).withAlpha(150)
                : isChecked
                    ? AppColors.theme.primaryColor.withAlpha(100)
                    : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 96,
              child: classCount <= 1
                  ? _buildClassTile(widget.classes.first)
                  : PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i % classCount),
                      itemBuilder: (_, i) => _buildClassTile(widget.classes[i % classCount]),
                    ),
            ),
            if (classCount > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(classCount, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == i ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? AppColors.theme.primaryColor
                            : AppColors.theme.darkGreyColor.withAlpha(80),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildClassTile(Subject subject) {
    final checked = widget.selected == subject;
    final scheduleText = widget.getScheduleText(subject);

    return GestureDetector(
      onTap: () => widget.onChanged(subject, !checked),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subjectName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: widget.textColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subject.subjectClass < 0 ? '특별실' : '${subject.subjectClass}반',
                    style: TextStyle(fontSize: 13, color: AppColors.theme.mealTypeTextColor),
                  ),
                  if (scheduleText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        scheduleText,
                        style: TextStyle(fontSize: 11, color: AppColors.theme.primaryColor),
                      ),
                    ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: checked ? AppColors.theme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: checked ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor,
                  width: 2,
                ),
              ),
              child: checked ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
            ),
          ],
        ),
      ),
    );
  }
}
