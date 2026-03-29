import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/data/subject_data_manager.dart';
import 'package:hansol_high_school/screens/sub/timetable_select_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/widgets/setting/grade_and_class_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:convert';

/**
 * 시간표 그리드 뷰 화면 (TimetableViewScreen)
 *
 * - 요일별 교시 그리드로 주간 시간표 표시
 * - 과목별 커스텀 컬러 설정 및 저장
 * - 선택과목 충돌 시 해결 다이얼로그 제공
 * - 학년/반 변경 시 시간표 자동 갱신
 */
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
  Map<String, int> _subjectColors = {}; // 과목명 → Color value

  @override
  void initState() {
    super.initState();
    _grade = SettingData().grade;
    _classNum = SettingData().classNum;
    _loadConflictResolutions();
    _loadSubjectColors();
    if (SettingData().isGradeSet) {
      _future = _buildTimetable();
    } else {
      _future = Future.value(_TimetableResult(
        grid: List.generate(5, (_) => List.filled(7, '')),
        conflicts: {},
      ));
    }
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
    // 충돌 슬롯: "월_3" → [과목A, 과목B]
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
              // 충돌 발생
              final existing = grid[weekday - 1][p];
              conflictSlots.putIfAbsent(slot, () => [existing]);
              if (!conflictSlots[slot]!.contains(name)) {
                conflictSlots[slot]!.add(name);
              }

              // 이전에 해결한 선택이 있으면 적용
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

    if (notSet) {
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
      setState(() => _future = _buildTimetable());
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(SettingData().isGradeSet
            ? '$_grade학년 $_classNum반 시간표'
            : '시간표'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_grade == 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: _showClassPicker,
              tooltip: '반 변경',
            ),
          if (_grade >= 2)
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

          // 미해결 충돌이 있으면 다이얼로그 표시 (한 번만)
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
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, MediaQuery.of(context).padding.bottom + 12),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 28),
                    ...['월', '화', '수', '목', '금'].map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.theme.darkGreyColor,
                        )),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Column(
                          children: List.generate(7, (p) => Expanded(
                            child: Center(
                              child: Text('${p + 1}', style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: AppColors.theme.darkGreyColor,
                              )),
                            ),
                          )),
                        ),
                      ),
                      ...List.generate(5, (day) => Expanded(
                        child: Column(
                          children: List.generate(7, (p) {
                            final name = result.grid[day][p];
                            final slot =
                                '${['월', '화', '수', '목', '금'][day]}_${p + 1}';
                            final isConflict =
                                result.conflicts.containsKey(slot);
                            return Expanded(
                              child: _Cell(
                                subject: name,
                                isConflict: isConflict,
                                isDark: isDark,
                                customColor: _subjectColors.containsKey(name)
                                    ? Color(_subjectColors[name]! | 0xFF000000)
                                    : null,
                                onLongPress: name.isEmpty
                                    ? null
                                    : () => _showColorPicker(name),
                              ),
                            );
                          }),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimetableResult {
  final List<List<String>> grid;
  final Map<String, List<String>> conflicts; // "월_3" → ["지구과학", "정보과학"]
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
  final Color? customColor;
  final VoidCallback? onLongPress;

  const _Cell({
    required this.subject,
    required this.isConflict,
    required this.isDark,
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
          color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(8),
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              subject,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textColor,
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
  double _saturation = 0.35;
  double _lightness = 0.82;
  int _selectedRow = -1;
  int _selectedCol = -1;

  @override
  void initState() {
    super.initState();
    if (widget.currentColor != null) {
      final hsl = HSLColor.fromColor(widget.currentColor!);
      _hue = hsl.hue;
      _saturation = hsl.saturation.clamp(0.15, 0.6);
      _lightness = hsl.lightness.clamp(0.7, 0.92);
    }
  }

  Color get _selectedColor =>
      HSLColor.fromAHSL(1, _hue, _saturation, _lightness).toColor();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewBg = isDark
        ? HSLColor.fromAHSL(1, _hue, _saturation * 0.6, 0.15).toColor()
        : _selectedColor;
    final previewText = isDark
        ? HSLColor.fromAHSL(1, _hue, _saturation, 0.75).toColor()
        : HSLColor.fromAHSL(1, _hue, _saturation, 0.35).toColor();

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 미리보기
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  widget.subjectName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: previewText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 6x6 원형 컬러피커 버튼
            _buildCircleGrid(),
            const SizedBox(height: 12),
            // 버튼
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
                      backgroundColor: AppColors.theme.primaryColor,
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

  Widget _buildCircleGrid() {
    const gridSize = 12;
    const totalSize = 230.0;
    const cellSize = totalSize / gridSize;
    const center = totalSize / 2;

    return Container(
      width: totalSize,
      height: totalSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.theme.darkGreyColor.withAlpha(60),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: Column(
          children: List.generate(gridSize, (row) {
            return Expanded(
              child: Row(
                children: List.generate(gridSize, (col) {
                  final dx = (col + 0.5) * cellSize - center;
                  final dy = (row + 0.5) * cellSize - center;
                  final dist = math.sqrt(dx * dx + dy * dy);
                  final hue = (math.atan2(dy, dx) * 180 / math.pi + 360) % 360;
                  final t = (dist / center).clamp(0.0, 1.0);
                  final lightness = 0.90 - t * 0.26;
                  final sat = 0.25 + t * 0.30;
                  final color = HSLColor.fromAHSL(1, hue, sat, lightness).toColor();

                  final isSelected = _selectedRow == row && _selectedCol == col;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _hue = hue;
                        _saturation = sat;
                        _lightness = lightness;
                        _selectedRow = row;
                        _selectedCol = col;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                                  width: 2.5,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? const Center(child: Icon(Icons.check, color: Colors.white, size: 16))
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

