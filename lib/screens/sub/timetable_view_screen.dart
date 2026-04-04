import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/data/subject_data_manager.dart';
import 'package:hansol_high_school/screens/sub/timetable_select_screen.dart';
import 'package:hansol_high_school/screens/sub/teacher_timetable_select_screen.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/widgets/setting/grade_and_class_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:convert';

/// 시간표 그리드 뷰 화면 (TimetableViewScreen)
///
/// - 요일별 교시 그리드로 주간 시간표 표시
/// - 과목별 커스텀 컬러 설정 및 저장
/// - 선택과목 충돌 시 해결 다이얼로그 제공
/// - 학년/반 변경 시 시간표 자동 갱신
class TimetableViewScreen extends StatefulWidget {
  const TimetableViewScreen({Key? key}) : super(key: key);

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
    _grade = SettingData().grade;
    _classNum = SettingData().classNum;
    _loadConflictResolutions();
    _loadSubjectColors();

    // 캐시된 프로필로 동기적 체크
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
    // 비동기 재확인
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
      builder: (_) => _ColorPickerDialog(
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
          builder: (_) => _ConflictDialog(
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
      title = '수업을 설정하면 시간표가 표시됩니다';
      buttonLabel = '수업 설정'; buttonIcon = Icons.settings;
      onPressed = () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeacherTimetableSelectScreen()));
        _future = _buildTeacherTimetable(); setState(() {});
      };
    } else if (notSet) {
      title = '학년/반을 먼저 설정해주세요';
      buttonLabel = '학년/반 설정';
      buttonIcon = Icons.school;
      onPressed = () => _showClassPicker();
    } else if (is1st) {
      title = '학년/반을 설정하면 시간표가 표시됩니다';
      buttonLabel = '학년/반 설정';
      buttonIcon = Icons.school;
      onPressed = () => _showClassPicker();
    } else {
      title = '선택과목을 설정하면 시간표가 표시됩니다';
      buttonLabel = '선택과목 설정';
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
            Icon(Icons.edit_calendar_outlined, size: 56,
                color: AppColors.theme.darkGreyColor),
            const SizedBox(height: 16),
            Text(title,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
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
    // 설정에서 학년/반 변경 후 돌아왔을 때 자동 새로고침
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
        title: Text(_isTeacher ? '내 수업 시간표' : SettingData().isGradeSet ? '$_grade학년 $_classNum반 시간표' : '시간표'),
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
              tooltip: '수업 설정',
            ),
          if (!_isTeacher && _grade == 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: _showClassPicker,
              tooltip: '반 변경',
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
              tooltip: '새로고침',
            ),
        ],
      ),
      body: FutureBuilder<_TimetableResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('시간표를 불러올 수 없습니다'));
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
    final days = ['월', '화', '수', '목', '금'];
    int maxPeriod = 0;
    for (int d = 0; d < 5; d++) for (int p = 6; p >= 0; p--) if (result.grid[d][p].isNotEmpty) { if (p + 1 > maxPeriod) maxPeriod = p + 1; break; }
    if (maxPeriod == 0) maxPeriod = 7;

    return Column(children: [Expanded(child: Padding(
      padding: EdgeInsets.fromLTRB(10, 8, 10, MediaQuery.of(context).padding.bottom + 12),
      child: Column(children: [
        Row(children: [
          const SizedBox(width: 30),
          ...List.generate(5, (i) {
            final isToday = todayWeekday == i + 1;
            return Expanded(child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: isToday ? BoxDecoration(color: AppColors.theme.primaryColor, borderRadius: BorderRadius.circular(12)) : null,
              child: Text(days[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: isToday ? Colors.white : AppColors.theme.darkGreyColor)),
            )));
          }),
        ]),
        const SizedBox(height: 8),
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(width: 30, child: Column(children: List.generate(maxPeriod, (p) => Expanded(
            child: Center(child: Text('${p + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.theme.darkGreyColor))))))),
          ...List.generate(5, (day) {
            final isToday = todayWeekday == day + 1;
            return Expanded(child: Container(
              decoration: isToday ? BoxDecoration(color: (isDark ? Colors.white : AppColors.theme.primaryColor).withAlpha(8), borderRadius: BorderRadius.circular(10)) : null,
              child: Column(children: List.generate(maxPeriod, (p) {
                final name = result.grid[day][p];
                final slot = '${days[day]}_${p + 1}';
                return Expanded(child: _Cell(subject: name, isConflict: result.conflicts.containsKey(slot), isDark: isDark, isToday: isToday,
                  customColor: _subjectColors.containsKey(name) ? Color(_subjectColors[name]! | 0xFF000000) : null,
                  onLongPress: name.isEmpty ? null : () => _showColorPicker(name)));
              })),
            ));
          }),
        ])),
      ]),
    ))]);
  }
}

class _TimetableResult {
  final List<List<String>> grid;
  final Map<String, List<String>> conflicts;
  _TimetableResult({required this.grid, required this.conflicts});
}

class _ConflictDialog extends StatelessWidget {
  final String dayName;
  final String period;
  final List<String> subjects;

  const _ConflictDialog({
    required this.dayName,
    required this.period,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz, size: 40,
                color: AppColors.theme.primaryColor),
            const SizedBox(height: 12),
            Text(
              '$dayName요일 $period교시',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '어떤 과목을 듣나요?',
              style: TextStyle(
                  fontSize: 14, color: AppColors.theme.darkGreyColor),
            ),
            const SizedBox(height: 20),
            ...subjects.map((subject) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(subject),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(subject,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String subject;
  final bool isConflict;
  final bool isDark;
  final bool isToday;
  final Color? customColor;
  final VoidCallback? onLongPress;

  const _Cell({
    required this.subject,
    required this.isConflict,
    required this.isDark,
    this.isToday = false,
    this.customColor,
    this.onLongPress,
  });

  static const _lightPastels = [
    Color(0xFFDCE8F5), Color(0xFFD5ECD4), Color(0xFFF5DDD5),
    Color(0xFFE3D5F0), Color(0xFFF0E4D0), Color(0xFFD0ECE8),
    Color(0xFFF5E0E8), Color(0xFFE8E4D0), Color(0xFFD8E0F0),
    Color(0xFFE0F0D8), Color(0xFFF0D8D8), Color(0xFFD8F0F0),
  ];

  static const _darkPastels = [
    Color(0xFF2A3A4A), Color(0xFF2A3F2A), Color(0xFF4A3530),
    Color(0xFF3A2D48), Color(0xFF443D2D), Color(0xFF2A4240),
    Color(0xFF482D38), Color(0xFF3A382D), Color(0xFF303548),
    Color(0xFF354830), Color(0xFF483030), Color(0xFF304848),
  ];

  static const _textColors = [
    Color(0xFF4A6A8A), Color(0xFF4A7A4A), Color(0xFF8A5A4A),
    Color(0xFF6A4A8A), Color(0xFF7A6A4A), Color(0xFF4A7A75),
    Color(0xFF8A4A60), Color(0xFF6A654A), Color(0xFF4A508A),
    Color(0xFF5A7A4A), Color(0xFF8A4A4A), Color(0xFF4A7A8A),
  ];

  int _colorIndex(String s) => s.hashCode.abs() % _lightPastels.length;

  @override
  Widget build(BuildContext context) {
    if (subject.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1C22) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }

    Color bg;
    Color textColor;

    if (customColor != null) {
      bg = isDark
          ? HSLColor.fromColor(customColor!).withLightness(0.15).withSaturation(0.3).toColor()
          : HSLColor.fromColor(customColor!).withLightness(0.92).withSaturation(0.4).toColor();
      textColor = isDark
          ? HSLColor.fromColor(customColor!).withLightness(0.75).toColor()
          : HSLColor.fromColor(customColor!).withLightness(0.35).toColor();
    } else {
      final idx = _colorIndex(subject);
      bg = isDark ? _darkPastels[idx] : _lightPastels[idx];
      textColor = isDark ? _lightPastels[idx] : _textColors[idx];
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: Text(
              subject,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final String subjectName;
  final Color? currentColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerDialog({
    required this.subjectName,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  double _hue = 0;
  double _lightness = 0.5;

  @override
  void initState() {
    super.initState();
    if (widget.currentColor != null) {
      final hsl = HSLColor.fromColor(widget.currentColor!);
      _hue = hsl.hue;
      _lightness = hsl.lightness.clamp(0.2, 0.8);
    }
  }

  Color get _selectedColor => HSLColor.fromAHSL(1, _hue, 0.7, _lightness).toColor();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewBg = isDark
        ? HSLColor.fromAHSL(1, _hue, 0.4, 0.15).toColor()
        : _selectedColor;
    final previewText = isDark
        ? HSLColor.fromAHSL(1, _hue, 0.7, 0.75).toColor()
        : HSLColor.fromAHSL(1, _hue, 0.7, 0.35).toColor();

    const size = 220.0;
    const center = Offset(size / 2, size / 2);
    const radius = size / 2;
    const innerR = radius * 0.38;

    String? _dragZone;

    void startDrag(Offset pos) {
      final dx = pos.dx - center.dx;
      final dy = pos.dy - center.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist > radius) return;
      _dragZone = dist <= innerR ? 'inner' : 'outer';
    }

    void updateFromPos(Offset pos) {
      final dx = pos.dx - center.dx;
      final dy = pos.dy - center.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist > radius) return;
      setState(() {
        if (_dragZone == 'inner') {
          _lightness = (1 - (pos.dy / size)).clamp(0.2, 0.8);
        } else if (_dragZone == 'outer') {
          _hue = (180 / math.pi * math.atan2(dy, dx) + 360) % 360;
        }
      });
    }

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(widget.subjectName, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: previewText))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: size, height: size,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) { startDrag(d.localPosition); updateFromPos(d.localPosition); },
                onPanUpdate: (d) => updateFromPos(d.localPosition),
                onPanEnd: (_) => _dragZone = null,
                onTapDown: (d) { startDrag(d.localPosition); updateFromPos(d.localPosition); },
                child: CustomPaint(
                  size: const Size(size, size),
                  painter: _TimetableColorPainter(selectedHue: _hue, lightness: _lightness),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.theme.darkGreyColor),
                      ),
                    ),
                    child: Text('취소', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onColorSelected(_selectedColor);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
            if (widget.currentColor != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    widget.onColorSelected(const Color(0x00000000));
                    Navigator.of(context).pop();
                  },
                  child: Text('기본 색상으로 초기화', style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimetableColorPainter extends CustomPainter {
  final double selectedHue;
  final double lightness;
  _TimetableColorPainter({required this.selectedHue, required this.lightness});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerR = radius * 0.38;

    for (double angle = 0; angle < 360; angle += 1) {
      final paint = Paint()
        ..color = HSLColor.fromAHSL(1, angle, 0.7, lightness).toColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.35;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.82),
        angle * math.pi / 180, math.pi / 180 + 0.02, false, paint,
      );
    }

    final selectedColor = HSLColor.fromAHSL(1, selectedHue, 0.7, 0.5);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        selectedColor.withLightness(0.8).toColor(),
        selectedColor.withLightness(0.5).toColor(),
        selectedColor.withLightness(0.2).toColor(),
      ],
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: innerR)));
    final rect = Rect.fromCircle(center: center, radius: innerR);
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
    canvas.restore();

    final lY = center.dy - innerR + (1 - lightness) * innerR * 2;
    canvas.drawLine(
      Offset(center.dx - innerR * 0.6, lY),
      Offset(center.dx + innerR * 0.6, lY),
      Paint()..color = Colors.white..strokeWidth = 2..strokeCap = StrokeCap.round,
    );

    final indicatorRad = selectedHue * math.pi / 180;
    final ix = center.dx + radius * 0.82 * math.cos(indicatorRad);
    final iy = center.dy + radius * 0.82 * math.sin(indicatorRad);
    canvas.drawCircle(Offset(ix, iy), 8, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _TimetableColorPainter old) =>
      old.selectedHue != selectedHue || old.lightness != lightness;
}

