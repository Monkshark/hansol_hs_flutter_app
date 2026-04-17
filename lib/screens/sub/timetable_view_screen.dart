import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:hansol_high_school/data/analytics_service.dart';
import 'package:hansol_high_school/data/auth_service.dart' show AuthService;
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/data/subject_data_manager.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/sub/timetable_select_screen.dart';
import 'package:hansol_high_school/screens/sub/teacher_timetable_select_screen.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';
import 'package:hansol_high_school/widgets/error_view.dart';
import 'package:hansol_high_school/widgets/setting/grade_and_class_picker.dart';
import 'package:hansol_high_school/screens/sub/timetable_widgets/color_picker_dialog.dart';
import 'package:hansol_high_school/screens/sub/timetable_widgets/conflict_dialog.dart';
import 'package:hansol_high_school/screens/sub/timetable_widgets/timetable_cell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hansol_high_school/widgets/home_widget/widget_service.dart';
import 'dart:convert';

class TimetableViewScreen extends StatefulWidget {
  const TimetableViewScreen({super.key});

  @override
  State<TimetableViewScreen> createState() => _TimetableViewScreenState();
}

class _TimetableViewScreenState extends State<TimetableViewScreen> {
  late Future<_TimetableResult> _future;
  late int _grade;
  late int _classNum;

  Map<String, String> _conflictResolutions = {};
  bool _isShowingConflictDialog = false;
  Map<String, int> _subjectColors = {};
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.trackFirstVisit('timetable');
    _grade = SettingData().grade;
    _classNum = SettingData().classNum;
    _loadConflictResolutions();
    _loadSubjectColors();

    final cached = AuthService.cachedProfile;
    if (cached?.isTeacher == true) {
      _isTeacher = true;
      _future = _buildTeacherTimetable();
    } else if (SettingData().isGradeSet) {
      _future = _buildTimetable();
    } else {
      _future = Future.value(_TimetableResult(
        grid: List.generate(5, (_) => List.filled(7, '')),
        conflicts: {},
      ));
    }
    _checkTeacher();
  }

  Future<void> _loadSubjectColors() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('subject_colors');
    if (json != null) {
      _subjectColors = Map<String, int>.from(jsonDecode(json));
    }
  }

  Future<void> _saveSubjectColors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subject_colors', jsonEncode(_subjectColors));
  }

  void _showColorPicker(String subject) {
    showDialog(
      context: context,
      builder: (_) => TimetableColorPickerDialog(
        subjectName: subject,
        currentColor: _subjectColors.containsKey(subject)
            ? Color(_subjectColors[subject]!)
            : null,
        onColorSelected: (color) {
          setState(() {
            if (color == const Color(0x00000000)) {
              _subjectColors.remove(subject);
            } else {
              _subjectColors[subject] = color.toARGB32();
            }
          });
          _saveSubjectColors();
        },
      ),
    );
  }

  Future<void> _loadConflictResolutions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('conflict_resolutions_$_grade');
    if (json != null) {
      _conflictResolutions = Map<String, String>.from(jsonDecode(json));
    }
  }

  Future<void> _saveConflictResolutions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'conflict_resolutions_$_grade', jsonEncode(_conflictResolutions));
  }

  Future<void> _checkTeacher() async {
    final profile = await AuthService.getCachedProfile();
    if (profile?.isTeacher == true && mounted) {
      setState(() => _isTeacher = true);
      _future = _buildTeacherTimetable();
      setState(() {});
    }
  }

  Future<_TimetableResult> _buildTeacherTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('teacher_timetable_selections');
    if (json == null) return _TimetableResult(grid: List.generate(5, (_) => List.filled(7, '')), conflicts: {});
    final selectedKeys = Set<String>.from(jsonDecode(json));
    final teacherSubjects = <int, Map<String, Set<int>>>{};
    for (var key in selectedKeys) {
      final parts = key.split('_');
      if (parts.length < 3) continue;
      final g = int.tryParse(parts[0]);
      final c = int.tryParse(parts.last);
      if (g == null || c == null) continue;
      final name = parts.sublist(1, parts.length - 1).join('_');
      teacherSubjects.putIfAbsent(g, () => {}).putIfAbsent(name, () => {}).add(c);
    }
    const maxPeriods = 7;
    final grid = List.generate(5, (_) => List.filled(maxPeriods, ''));
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final friday = monday.add(const Duration(days: 4));
    for (var entry in teacherSubjects.entries) {
      final timetable = await TimetableDataApi.getTimeTable(startDate: monday, endDate: friday, grade: entry.key.toString());
      timetable.forEach((dateStr, classMap) {
        if (dateStr == 'error') return;
        final weekday = DateTime(int.parse(dateStr.substring(0, 4)), int.parse(dateStr.substring(4, 6)), int.parse(dateStr.substring(6, 8))).weekday;
        if (weekday > 5) return;
        classMap.forEach((classNum, subjects) {
          if (classNum == 'error') return;
          final classInt = classNum == 'special' ? -1 : (int.tryParse(classNum) ?? -1);
          for (int p = 0; p < subjects.length && p < maxPeriods; p++) {
            final name = subjects[p];
            if (name.isEmpty || name.contains('[보강]') || name == '토요휴업일') continue;
            if (entry.value.containsKey(name) && entry.value[name]!.contains(classInt)) {
              final label = classInt < 0 ? '특' : '$classInt';
              grid[weekday - 1][p] = '$name\n(${entry.key}-$label)';
            }
          }
        });
      });
    }
    return _TimetableResult(grid: grid, conflicts: {});
  }

  Future<_TimetableResult> _buildTimetable() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final friday = monday.add(const Duration(days: 4));

    if (_grade == 1) {
      return _buildClassTimetable(monday, friday);
    } else {
      return _buildSelectedTimetable(monday, friday);
    }
  }

  Future<_TimetableResult> _buildClassTimetable(
      DateTime monday, DateTime friday) async {
    final timetable = await TimetableDataApi.getTimeTable(
      startDate: monday,
      endDate: friday,
      grade: _grade.toString(),
      classNum: _classNum.toString(),
    );

    const maxPeriods = 7;
    final grid = List.generate(5, (_) => List.filled(maxPeriods, ''));

    timetable.forEach((dateStr, classMap) {
      if (dateStr == 'error') return;
      final weekday = DateTime(
        int.parse(dateStr.substring(0, 4)),
        int.parse(dateStr.substring(4, 6)),
        int.parse(dateStr.substring(6, 8)),
      ).weekday;
      if (weekday > 5) return;

      classMap.forEach((_, subjects) {
        for (int p = 0; p < subjects.length && p < maxPeriods; p++) {
          final name = subjects[p];
          if (name.isEmpty || name.contains('[보강]') || name == '토요휴업일') continue;
          grid[weekday - 1][p] = name;
        }
      });
    });

    return _TimetableResult(grid: grid, conflicts: {});
  }

  Future<_TimetableResult> _buildSelectedTimetable(
      DateTime monday, DateTime friday) async {
    final selected = await SubjectDataManager.loadSelectedSubjects(_grade);

    final timetable = await TimetableDataApi.getTimeTable(
      startDate: monday,
      endDate: friday,
      grade: _grade.toString(),
    );

    const maxPeriods = 7;
    final grid = List.generate(5, (_) => List.filled(maxPeriods, ''));
    final conflictSlots = <String, List<String>>{};

    final selectedMap = <String, int>{};
    for (var s in selected) {
      selectedMap[s.subjectName] = s.subjectClass;
    }

    timetable.forEach((dateStr, classMap) {
      if (dateStr == 'error') return;
      final weekday = DateTime(
        int.parse(dateStr.substring(0, 4)),
        int.parse(dateStr.substring(4, 6)),
        int.parse(dateStr.substring(6, 8)),
      ).weekday;
      if (weekday > 5) return;
      final dayName = ['월', '화', '수', '목', '금'][weekday - 1];

      classMap.forEach((classNum, subjects) {
        if (classNum == 'error') return;
        final classInt = classNum == 'special' ? -1 : (int.tryParse(classNum) ?? -1);
        for (int p = 0; p < subjects.length && p < maxPeriods; p++) {
          final name = subjects[p];
          if (name.isEmpty || name.contains('[보강]') || name == '토요휴업일') continue;
          if (selectedMap.containsKey(name) && selectedMap[name] == classInt) {
            final slot = '${dayName}_${p + 1}';

            if (grid[weekday - 1][p].isNotEmpty &&
                grid[weekday - 1][p] != name) {
              final existing = grid[weekday - 1][p];
              conflictSlots.putIfAbsent(slot, () => [existing]);
              if (!conflictSlots[slot]!.contains(name)) {
                conflictSlots[slot]!.add(name);
              }

              if (_conflictResolutions.containsKey(slot)) {
                grid[weekday - 1][p] = _conflictResolutions[slot]!;
              }
            } else {
              grid[weekday - 1][p] = name;
            }
          }
        }
      });
    });

    return _TimetableResult(grid: grid, conflicts: conflictSlots);
  }

  Future<void> _showConflictResolver(_TimetableResult result) async {
    if (_isShowingConflictDialog) return;
    _isShowingConflictDialog = true;

    try {
      final unresolved = <String, List<String>>{};
      for (var entry in result.conflicts.entries) {
        if (!_conflictResolutions.containsKey(entry.key)) {
          unresolved[entry.key] = entry.value;
        }
      }

      if (unresolved.isEmpty) return;

      for (var entry in unresolved.entries) {
        final slot = entry.key;
        final parts = slot.split('_');
        final dayName = parts[0];
        final period = parts[1];

        if (!mounted) return;
        final chosen = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ConflictDialog(
            dayName: dayName,
            period: period,
            subjects: entry.value,
          ),
        );

        if (chosen != null) {
          _conflictResolutions[slot] = chosen;
        }
      }

      await _saveConflictResolutions();
      _future = _buildTimetable();
      if (mounted) setState(() {});
    } finally {
      _isShowingConflictDialog = false;
    }
  }

  Widget _buildEmptyView(bool hasConflicts, int conflictCount) {
    final notSet = !SettingData().isGradeSet;
    final is1st = _grade == 1;

    String title;
    String buttonLabel;
    IconData buttonIcon;
    VoidCallback onPressed;

    if (_isTeacher) {
      title = AppLocalizations.of(context)!.timetable_setTeachingMsg;
      buttonLabel = AppLocalizations.of(context)!.timetable_setSetting; buttonIcon = Icons.settings;
      onPressed = () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeacherTimetableSelectScreen()));
        _future = _buildTeacherTimetable(); setState(() {});
      };
    } else if (notSet) {
      title = AppLocalizations.of(context)!.timetable_setGradeMsg;
      buttonLabel = AppLocalizations.of(context)!.timetable_setGrade;
      buttonIcon = Icons.school;
      onPressed = () => _showClassPicker();
    } else if (is1st) {
      title = AppLocalizations.of(context)!.timetable_set1stMsg;
      buttonLabel = AppLocalizations.of(context)!.timetable_setGrade;
      buttonIcon = Icons.school;
      onPressed = () => _showClassPicker();
    } else {
      title = AppLocalizations.of(context)!.timetable_setSubjectMsg;
      buttonLabel = AppLocalizations.of(context)!.timetable_setSubject;
      buttonIcon = Icons.settings;
      onPressed = () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TimetableSelectScreen()),
        );
        setState(() => _future = _buildTimetable());
      };
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_calendar_outlined, size: Responsive.r(context, 56),
                color: AppColors.theme.darkGreyColor),
            const SizedBox(height: 16),
            Text(title,
              style: TextStyle(fontSize: Responsive.sp(context, 17), fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon),
              label: Text(buttonLabel),
              style: _buttonStyle(),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.theme.primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    );
  }

  Future<void> _showClassPicker() async {
    final pickerGrade = _grade > 0 ? _grade : 1;
    final pickerClass = _classNum > 0 ? _classNum : 1;
    final classCount = await TimetableDataApi.getClassCount(pickerGrade);
    if (!mounted) return;
    final result = await showDialog<List<int>>(
      context: context,
      builder: (_) => GradeAndClassPickerDialog(
        initialGrade: pickerGrade,
        initialClass: pickerClass,
        classCount: classCount > 0 ? classCount : 10,
      ),
    );
    if (result != null && result.length == 2) {
      _grade = result[0];
      _classNum = result[1];
      SettingData().grade = _grade;
      SettingData().classNum = _classNum;
      _syncGradeToFirestore(_grade, _classNum);

      if (_grade >= 2) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TimetableSelectScreen()),
        );
      }
      _conflictResolutions.clear();
      _future = _buildTimetable();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTeacher && SettingData().isGradeSet &&
        (_grade != SettingData().grade || _classNum != SettingData().classNum)) {
      _grade = SettingData().grade;
      _classNum = SettingData().classNum;
      _future = _buildTimetable();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        title: Text(_isTeacher ? AppLocalizations.of(context)!.timetable_teacherScreenTitle : SettingData().isGradeSet ? AppLocalizations.of(context)!.timetable_classTitle(_grade, _classNum) : AppLocalizations.of(context)!.timetable_screenTitle),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_isTeacher)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeacherTimetableSelectScreen()));
                _future = _buildTeacherTimetable(); setState(() {});
              },
              tooltip: AppLocalizations.of(context)!.timetable_setting,
            ),
          if (!_isTeacher && _grade == 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: _showClassPicker,
              tooltip: AppLocalizations.of(context)!.timetable_changeClass,
            ),
          if (!_isTeacher && _grade >= 2)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _conflictResolutions.clear();
                _saveConflictResolutions();
                _future = _buildTimetable();
                setState(() {});
              },
              tooltip: AppLocalizations.of(context)!.timetable_refresh,
            ),
        ],
      ),
      body: FutureBuilder<_TimetableResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: AppLocalizations.of(context)!.timetable_loadError,
              onRetry: () { setState(() => _future = _buildTimetable()); },
            );
          }
          if (!snapshot.hasData) {
            return Center(child: Text(AppLocalizations.of(context)!.timetable_loadError));
          }

          final result = snapshot.data!;
          final isEmpty = result.grid.every(
              (day) => day.every((s) => s.isEmpty));

          if (isEmpty) return _buildEmptyView(false, 0);

          if (result.conflicts.isNotEmpty && !_isShowingConflictDialog) {
            final hasUnresolved = result.conflicts.keys
                .any((k) => !_conflictResolutions.containsKey(k));
            if (hasUnresolved) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showConflictResolver(result);
              });
            }
          }

          return _buildGridView(result, isDark);
        },
      ),
    ),
    );
  }

  Widget _buildGridView(_TimetableResult result, bool isDark) {
    final todayWeekday = DateTime.now().weekday;
    final l10n = AppLocalizations.of(context)!;
    final days = [l10n.timetable_dayMon, l10n.timetable_dayTue, l10n.timetable_dayWed, l10n.timetable_dayThu, l10n.timetable_dayFri];
    int maxPeriod = 0;
    for (int d = 0; d < 5; d++) {
      for (int p = 6; p >= 0; p--) {
        if (result.grid[d][p].isNotEmpty) {
          if (p + 1 > maxPeriod) { maxPeriod = p + 1; }
          break;
        }
      }
    }
    if (maxPeriod == 0) maxPeriod = 7;

    return Column(children: [Expanded(child: Padding(
      padding: EdgeInsets.fromLTRB(10, 8, 10, MediaQuery.of(context).padding.bottom + 12),
      child: Column(children: [
        Row(children: [
          SizedBox(width: Responsive.w(context, 30)),
          ...List.generate(5, (i) {
            final isToday = todayWeekday == i + 1;
            return Expanded(child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: isToday ? BoxDecoration(color: AppColors.theme.primaryColor, borderRadius: BorderRadius.circular(12)) : null,
              child: Text(days[i], style: TextStyle(fontSize: Responsive.sp(context, 13), fontWeight: FontWeight.w700,
                color: isToday ? Colors.white : AppColors.theme.darkGreyColor)),
            )));
          }),
        ]),
        const SizedBox(height: 8),
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(width: Responsive.w(context, 30), child: Column(children: List.generate(maxPeriod, (p) => Expanded(
            child: Center(child: Text('${p + 1}', style: TextStyle(fontSize: Responsive.sp(context, 12), fontWeight: FontWeight.w600, color: AppColors.theme.darkGreyColor))))))),
          ...List.generate(5, (day) {
            final isToday = todayWeekday == day + 1;
            return Expanded(child: Container(
              decoration: isToday ? BoxDecoration(color: (isDark ? Colors.white : AppColors.theme.primaryColor).withAlpha(8), borderRadius: BorderRadius.circular(10)) : null,
              child: Column(children: List.generate(maxPeriod, (p) {
                final name = result.grid[day][p];
                final slot = '${days[day]}_${p + 1}';
                return Expanded(child: TimetableCell(subject: name, isConflict: result.conflicts.containsKey(slot), isDark: isDark, isToday: isToday,
                  customColor: _subjectColors.containsKey(name) ? Color(_subjectColors[name]! | 0xFF000000) : null,
                  onLongPress: name.isEmpty ? null : () => _showColorPicker(name)));
              })),
            ));
          }),
        ])),
      ]),
    ))]);
  }

  Future<void> _syncGradeToFirestore(int g, int c) async {
    if (!AuthService.isLoggedIn) return;
    try {
      final uid = AuthService.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'grade': g,
        'classNum': c,
      });
    } catch (e) {
      log('TimetableViewScreen: Firestore grade sync error: $e');
    }
  }
}

class _TimetableResult {
  final List<List<String>> grid;
  final Map<String, List<String>> conflicts;
  _TimetableResult({required this.grid, required this.conflicts}) {
    _saveGridAndUpdateWidget(grid);
  }

  static Future<void> _saveGridAndUpdateWidget(List<List<String>> grid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = grid.map((row) => row.join(',')).toList();
      await prefs.setStringList('widget_timetable_grid', encoded);
      await WidgetService.updateTimetableWidget();
    } catch (e) {
      log('TimetableViewScreen: save grid error: $e');
    }
  }
}
