import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/subject.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherTimetableSelectScreen extends StatefulWidget {
  const TeacherTimetableSelectScreen({Key? key}) : super(key: key);

  @override
  State<TeacherTimetableSelectScreen> createState() =>
      _TeacherTimetableSelectScreenState();
}

class _TeacherTimetableSelectScreenState
    extends State<TeacherTimetableSelectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _hasChanges = false;

  final Map<int, Map<String, List<Subject>>> _gradeSubjectGroups = {};

  final Set<String> _selected = {};

  final Map<int, Map<String, List<_ScheduleInfo>>> _scheduleMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadSaved();

    for (int grade = 1; grade <= 3; grade++) {
      final subjects =
          await TimetableDataApi.getAllSubjectCombinations(grade: grade);
      final groups = <String, List<Subject>>{};
      for (var s in subjects) {
        groups.putIfAbsent(s.subjectName, () => []).add(s);
      }
      _gradeSubjectGroups[grade] = groups;

      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final friday = monday.add(const Duration(days: 4));
      final timetable = await TimetableDataApi.getTimeTable(
        startDate: monday,
        endDate: friday,
        grade: grade.toString(),
      );

      final sMap = <String, List<_ScheduleInfo>>{};
      const dayNames = ['', '월', '화', '수', '목', '금'];

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

        classMap.forEach((classNum, subjectsList) {
          if (classNum == 'error') return;
          final classInt =
              classNum == 'special' ? -1 : (int.tryParse(classNum) ?? -1);
          for (int p = 0; p < subjectsList.length; p++) {
            final name = subjectsList[p];
            if (name.isEmpty ||
                name.contains('[보강]') ||
                name == '토요휴업일') continue;
            final key = '${name}_$classInt';
            sMap.putIfAbsent(key, () => []).add(
              _ScheduleInfo(dayName: dayName, period: p + 1),
            );
          }
        });
      });

      _scheduleMap[grade] = sMap;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('teacher_timetable_selections');
    if (json != null) {
      _selected.addAll(List<String>.from(jsonDecode(json)));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'teacher_timetable_selections', jsonEncode(_selected.toList()));

    if (AuthService.isLoggedIn) {
      try {
        final uid = AuthService.currentUser!.uid;
        for (int grade = 1; grade <= 3; grade++) {
          final subjects = <Subject>[];
          for (var key in _selected) {
            final parts = key.split('_');
            if (parts.length >= 3 && int.parse(parts[0]) == grade) {
              subjects.add(Subject(
                subjectName: parts.sublist(1, parts.length - 1).join('_'),
                subjectClass: int.parse(parts.last),
              ));
            }
          }
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('subjects')
              .doc('teacher_grade_$grade')
              .set({
            'subjects': subjects.map((s) => s.toJson()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        log('TeacherTimetableSelectScreen: save error: $e');
      }
    }

    setState(() => _hasChanges = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.timetable_teacherSaved)),
      );
    }
  }

  String _makeKey(int grade, String subject, int classNum) =>
      '${grade}_${subject}_$classNum';

  String _getScheduleText(int grade, Subject subject) {
    final key = '${subject.subjectName}_${subject.subjectClass}';
    final infos = _scheduleMap[grade]?[key];
    if (infos == null || infos.isEmpty) return '';

    final unique = <String>{};
    final sorted = <_ScheduleInfo>[];
    const dayOrder = {'월': 1, '화': 2, '수': 3, '목': 4, '금': 5};

    for (var info in infos) {
      final tag = '${info.dayName}${info.period}';
      if (unique.add(tag)) sorted.add(info);
    }
    sorted.sort((a, b) {
      final d = (dayOrder[a.dayName] ?? 0) - (dayOrder[b.dayName] ?? 0);
      return d != 0 ? d : a.period - b.period;
    });

    return sorted.map((s) => AppLocalizations.of(context)!.timetable_selectPeriod(s.dayName, s.period)).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.timetable_teacherAlert),
            content: Text(AppLocalizations.of(context)!.timetable_teacherDiscardMsg),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(AppLocalizations.of(context)!.common_cancel)),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child:
                      Text(AppLocalizations.of(context)!.timetable_teacherLeave, style: const TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (discard == true && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: textColor,
          title: Text(AppLocalizations.of(context)!.timetable_teacherSelectTitle),
          centerTitle: true,
          elevation: 0,
          actions: [
            if (_hasChanges)
              IconButton(
                onPressed: _save,
                icon: Icon(Icons.check,
                    color: AppColors.theme.primaryColor, size: 28),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.theme.primaryColor,
            unselectedLabelColor: AppColors.theme.darkGreyColor,
            indicatorColor: AppColors.theme.primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: AppLocalizations.of(context)!.timetable_teacherTab1),
              Tab(text: AppLocalizations.of(context)!.timetable_teacherTab2),
              Tab(text: AppLocalizations.of(context)!.timetable_teacherTab3),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.theme.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.school,
                            size: 20, color: AppColors.theme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.timetable_teacherCount(_selected.length),
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
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGradeTab(1),
                        _buildGradeTab(2),
                        _buildGradeTab(3),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGradeTab(int grade) {
    final groups = _gradeSubjectGroups[grade];
    if (groups == null || groups.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.timetable_teacherLoadError,
            style: TextStyle(color: AppColors.theme.darkGreyColor)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final sortedNames = groups.keys.toList()..sort();

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      itemCount: sortedNames.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final subjectName = sortedNames[index];
        final classes = groups[subjectName]!;

        return _TeacherSubjectCard(
          grade: grade,
          subjectName: subjectName,
          classes: classes,
          selected: _selected,
          makeKey: _makeKey,
          getScheduleText: (s) => _getScheduleText(grade, s),
          isDark: isDark,
          textColor: textColor,
          onChanged: (key, value) {
            setState(() {
              if (value) {
                _selected.add(key);
              } else {
                _selected.remove(key);
              }
              _hasChanges = true;
            });
          },
        );
      },
    );
  }
}

class _ScheduleInfo {
  final String dayName;
  final int period;
  _ScheduleInfo({required this.dayName, required this.period});
}

class _TeacherSubjectCard extends StatefulWidget {
  final int grade;
  final String subjectName;
  final List<Subject> classes;
  final Set<String> selected;
  final String Function(int, String, int) makeKey;
  final String Function(Subject) getScheduleText;
  final bool isDark;
  final Color textColor;
  final void Function(String key, bool value) onChanged;

  const _TeacherSubjectCard({
    required this.grade,
    required this.subjectName,
    required this.classes,
    required this.selected,
    required this.makeKey,
    required this.getScheduleText,
    required this.isDark,
    required this.textColor,
    required this.onChanged,
  });

  @override
  State<_TeacherSubjectCard> createState() => _TeacherSubjectCardState();
}

class _TeacherSubjectCardState extends State<_TeacherSubjectCard> {
  late PageController _pageController;
  int _currentPage = 0;
  static const int _loopMultiplier = 1000;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.classes.length > 1
        ? _loopMultiplier * widget.classes.length
        : 0;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _selectedCount() {
    int count = 0;
    for (var s in widget.classes) {
      if (widget.selected.contains(
          widget.makeKey(widget.grade, widget.subjectName, s.subjectClass))) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final classCount = widget.classes.length;
    final selectedCount = _selectedCount();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E2028) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selectedCount > 0
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
                      onPageChanged: (i) =>
                          setState(() => _currentPage = i % classCount),
                      itemBuilder: (_, i) =>
                          _buildClassTile(widget.classes[i % classCount]),
                    ),
            ),
            if (classCount > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(classCount, (i) {
                    final subject = widget.classes[i];
                    final key = widget.makeKey(
                        widget.grade, widget.subjectName, subject.subjectClass);
                    final isSelected = widget.selected.contains(key);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == i ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? (isSelected
                                ? AppColors.theme.primaryColor
                                : AppColors.theme.darkGreyColor)
                            : (isSelected
                                ? AppColors.theme.primaryColor.withAlpha(120)
                                : AppColors.theme.darkGreyColor.withAlpha(80)),
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
    final key = widget.makeKey(
        widget.grade, widget.subjectName, subject.subjectClass);
    final isChecked = widget.selected.contains(key);
    final scheduleText = widget.getScheduleText(subject);

    return GestureDetector(
      onTap: () => widget.onChanged(key, !isChecked),
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
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.textColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subject.subjectClass < 0
                        ? AppLocalizations.of(context)!.timetable_teacherSpecial
                        : AppLocalizations.of(context)!.timetable_teacherClass(subject.subjectClass),
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.theme.mealTypeTextColor),
                  ),
                  if (scheduleText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        scheduleText,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.theme.primaryColor),
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
                color: isChecked
                    ? AppColors.theme.primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isChecked
                      ? AppColors.theme.primaryColor
                      : AppColors.theme.darkGreyColor,
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
