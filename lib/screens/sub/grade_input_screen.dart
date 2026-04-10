import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hansol_high_school/data/grade_manager.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 시험 추가/수정 화면
class GradeInputScreen extends StatefulWidget {
  final Exam? exam;
  final bool isMock;

  const GradeInputScreen({Key? key, this.exam, this.isMock = false}) : super(key: key);

  @override
  State<GradeInputScreen> createState() => _GradeInputScreenState();
}

class _GradeInputScreenState extends State<GradeInputScreen> {
  static const _mockMonthKeys = ['3월', '6월', '9월', '11월'];

  bool get _isEdit => widget.exam != null;
  bool get _isMock => _type == 'mock' || _type == 'private_mock';

  Map<String, String> _localizedMonths(AppLocalizations l) => {
    '3월': l.gradeInput_monthMar,
    '6월': l.gradeInput_monthJun,
    '9월': l.gradeInput_monthSep,
    '11월': l.gradeInput_monthNov,
  };

  late String _type;
  late int _year;
  int _semester = 1;
  int _grade = 1;
  String _mockMonth = '3월';
  final _privateLabelController = TextEditingController();

  final List<_SubjectEntry> _subjects = [];
  bool _saving = false;

  Map<String, String> _availableTypes(AppLocalizations l) {
    if (widget.isMock) {
      return {'mock': l.gradeInput_typeMock, 'private_mock': l.gradeInput_typePrivateMock};
    }
    return {'midterm': l.gradeInput_typeMidterm, 'final': l.gradeInput_typeFinal};
  }

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    _type = widget.isMock ? 'mock' : 'midterm';
    if (_isEdit) {
      _prefill(widget.exam!);
    }
  }

  void _prefill(Exam exam) {
    _type = exam.type;
    _year = exam.year;
    _semester = exam.semester;
    _grade = exam.grade;
    if (exam.type == 'mock') {
      _mockMonth = exam.mockLabel ?? '3월';
    } else if (exam.type == 'private_mock') {
      _privateLabelController.text = exam.mockLabel ?? '';
    }
    for (final s in exam.scores) {
      _subjects.add(_SubjectEntry(
        name: s.subject,
        rawScoreCtrl: TextEditingController(text: s.rawScore?.toString() ?? ''),
        averageCtrl: TextEditingController(text: s.average?.toString() ?? ''),
        rankCtrl: TextEditingController(text: s.rank?.toString() ?? ''),
        standardScoreCtrl: TextEditingController(text: s.standardScore?.toString() ?? ''),
        percentileCtrl: TextEditingController(text: s.percentile?.toString() ?? ''),
        achievement: s.achievement,
      ));
    }
  }

  @override
  void dispose() {
    _privateLabelController.dispose();
    for (final s in _subjects) {
      s.dispose();
    }
    super.dispose();
  }

  /// 시간표에서 과목 불러오기
  Future<void> _loadFromTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final gridData = prefs.getStringList('widget_timetable_grid');
    if (gridData == null || gridData.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.gradeInput_noTimetable)),
        );
      }
      return;
    }

    // 모든 요일에서 과목 추출 → 중복 제거
    final allSubjects = <String>{};
    for (final dayStr in gridData) {
      for (final subj in dayStr.split(',')) {
        final trimmed = subj.trim();
        if (trimmed.isNotEmpty) allSubjects.add(trimmed);
      }
    }
    if (allSubjects.isEmpty) return;

    final existing = _subjects.map((s) => s.name).toSet();
    final available = allSubjects.where((s) => !existing.contains(s)).toList()..sort();
    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.gradeInput_allSubjectsAdded)),
        );
      }
      return;
    }

    final selected = await _showSubjectPicker(available, AppLocalizations.of(context)!.gradeInput_selectSubjects);
    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (final name in selected) {
          _subjects.add(_SubjectEntry(name: name));
        }
      });
    }
  }

  /// 모의고사 과목 선택
  Future<void> _loadMockSubjects() async {
    final existing = _subjects.map((s) => s.name).toSet();
    final available = <String>[];
    for (final list in GradeManager.mockSubjects.values) {
      for (final s in list) {
        if (!existing.contains(s)) available.add(s);
      }
    }
    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.gradeInput_allMockAdded)),
        );
      }
      return;
    }

    final selected = await _showMockSubjectPicker(existing);
    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (final name in selected) {
          _subjects.add(_SubjectEntry(name: name));
        }
      });
    }
  }

  /// 과목 선택 다이얼로그 (내신용)
  Future<List<String>?> _showSubjectPicker(List<String> available, String title) async {
    final checked = <String, bool>{for (final s in available) s: false};
    return showDialog<List<String>>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(builder: (ctx, setDlg) {
          return Dialog(
            backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Theme.of(ctx).textTheme.bodyLarge?.color,
                  )),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: available.map((s) {
                          final on = checked[s]!;
                          return FilterChip(
                            label: Text(s),
                            selected: on,
                            selectedColor: Color(GradeManager.getSubjectColor(s)).withAlpha(40),
                            checkmarkColor: Color(GradeManager.getSubjectColor(s)),
                            onSelected: (v) => setDlg(() => checked[s] = v),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(AppLocalizations.of(context)!.common_cancel, style: TextStyle(color: AppColors.theme.darkGreyColor)),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(
                      onPressed: () {
                        final result = checked.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();
                        Navigator.pop(ctx, result);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(AppLocalizations.of(context)!.dday_addButton),
                    )),
                  ]),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  /// 모의고사 과목 선택 (카테고리별)
  Future<List<String>?> _showMockSubjectPicker(Set<String> existing) async {
    final checked = <String, bool>{};
    for (final list in GradeManager.mockSubjects.values) {
      for (final s in list) {
        if (!existing.contains(s)) checked[s] = false;
      }
    }

    return showDialog<List<String>>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(builder: (ctx, setDlg) {
          return Dialog(
            backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
              child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.gradeInput_mockSubjectPicker, style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Theme.of(ctx).textTheme.bodyLarge?.color,
                  )),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: GradeManager.mockSubjects.entries.map((cat) {
                          final available = cat.value.where((s) => checked.containsKey(s)).toList();
                          if (available.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.key, style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: AppColors.theme.darkGreyColor,
                                )),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: available.map((s) {
                                    final on = checked[s]!;
                                    return FilterChip(
                                      label: Text(s),
                                      selected: on,
                                      selectedColor: Color(GradeManager.getSubjectColor(s)).withAlpha(40),
                                      checkmarkColor: Color(GradeManager.getSubjectColor(s)),
                                      onSelected: (v) => setDlg(() => checked[s] = v),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(AppLocalizations.of(context)!.common_cancel, style: TextStyle(color: AppColors.theme.darkGreyColor)),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(
                      onPressed: () {
                        final result = checked.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .toList();
                        Navigator.pop(ctx, result);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(AppLocalizations.of(context)!.dday_addButton),
                    )),
                  ]),
                ],
              ),
            ),
            ),
          );
        });
      },
    );
  }

  /// 수동 과목 추가
  Future<void> _addManualSubject() async {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2028) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 36, height: 4, decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.gradeInput_addSubject, style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: Theme.of(ctx).textTheme.bodyLarge?.color,
                )),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.gradeInput_subjectName,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (t) {
                    if (t.trim().isNotEmpty) Navigator.pop(ctx, t.trim());
                  },
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(context)!.common_cancel, style: TextStyle(color: AppColors.theme.darkGreyColor)),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    onPressed: () {
                      final t = ctrl.text.trim();
                      if (t.isNotEmpty) Navigator.pop(ctx, t);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(AppLocalizations.of(context)!.dday_addButton),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );

    if (name != null && name.isNotEmpty) {
      if (_subjects.any((s) => s.name == name)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.gradeInput_addSubjectDuplicate(name))),
          );
        }
        return;
      }
      setState(() => _subjects.add(_SubjectEntry(name: name)));
    }
  }

  /// 시험 저장
  Future<void> _save() async {
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.gradeInput_addMinSubjects)),
      );
      return;
    }
    if (_type == 'private_mock' && _privateLabelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.gradeInput_privateNameRequired)),
      );
      return;
    }

    setState(() => _saving = true);

    String? mockLabel;
    if (_type == 'mock') mockLabel = _mockMonth;
    if (_type == 'private_mock') mockLabel = _privateLabelController.text.trim();

    final scores = _subjects.map((s) {
      return SubjectScore(
        subject: s.name,
        rawScore: int.tryParse(s.rawScoreCtrl.text),
        average: double.tryParse(s.averageCtrl.text),
        rank: int.tryParse(s.rankCtrl.text),
        standardScore: double.tryParse(s.standardScoreCtrl.text),
        percentile: double.tryParse(s.percentileCtrl.text),
        achievement: s.achievement,
      );
    }).toList();

    final exam = Exam(
      id: _isEdit ? widget.exam!.id : const Uuid().v4(),
      type: _type,
      year: _year,
      semester: _semester,
      grade: _grade,
      mockLabel: mockLabel,
      scores: scores,
      createdAt: _isEdit ? widget.exam!.createdAt : DateTime.now(),
    );

    if (_isEdit) {
      await GradeManager.updateExam(exam);
    } else {
      await GradeManager.addExam(exam);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = isDark ? const Color(0xFF1E2028) : Colors.white;
    final fieldFill = isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: Text(_isEdit ? AppLocalizations.of(context)!.gradeInput_screenEdit : AppLocalizations.of(context)!.gradeInput_screenTitle),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: _saving
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
                : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // ── 시험 유형 ──
            _sectionLabel(AppLocalizations.of(context)!.gradeInput_typeSection),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _availableTypes(AppLocalizations.of(context)!).entries.map((e) {
                final selected = _type == e.key;
                return ChoiceChip(
                  label: Text(e.value),
                  selected: selected,
                  selectedColor: AppColors.theme.primaryColor.withAlpha(30),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.theme.primaryColor : textColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  onSelected: (v) {
                    if (!v) return;
                    final old = !_isEdit ? List.of(_subjects) : <_SubjectEntry>[];
                    setState(() {
                      _type = e.key;
                      if (!_isEdit) _subjects.clear();
                    });
                    for (final s in old) s.dispose();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── 시험 정보 ──
            _sectionLabel(AppLocalizations.of(context)!.gradeInput_infoSection),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // 연도 / 학기 / 학년
                  Row(children: [
                    Expanded(child: _dropdown<int>(
                      label: AppLocalizations.of(context)!.gradeInput_year,
                      value: _year,
                      items: List.generate(5, (i) => DateTime.now().year - 2 + i),
                      itemLabel: (v) => AppLocalizations.of(context)!.gradeInput_yearSuffix(v),
                      onChanged: (v) => setState(() => _year = v!),
                      fillColor: fieldFill,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _dropdown<int>(
                      label: AppLocalizations.of(context)!.gradeInput_semester,
                      value: _semester,
                      items: [1, 2],
                      itemLabel: (v) => AppLocalizations.of(context)!.gradeInput_semesterSuffix(v),
                      onChanged: (v) => setState(() => _semester = v!),
                      fillColor: fieldFill,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _dropdown<int>(
                      label: AppLocalizations.of(context)!.gradeInput_grade,
                      value: _grade,
                      items: [1, 2, 3],
                      itemLabel: (v) => AppLocalizations.of(context)!.gradeInput_gradeSuffix(v),
                      onChanged: (v) => setState(() => _grade = v!),
                      fillColor: fieldFill,
                    )),
                  ]),
                  // 모의: 월 선택
                  if (_type == 'mock') ...[
                    const SizedBox(height: 12),
                    _dropdown<String>(
                      label: AppLocalizations.of(context)!.gradeInput_month,
                      value: _mockMonth,
                      items: _mockMonthKeys,
                      itemLabel: (v) => AppLocalizations.of(context)!.gradeInput_mockMonthSuffix(_localizedMonths(AppLocalizations.of(context)!)[v] ?? v),
                      onChanged: (v) => setState(() => _mockMonth = v!),
                      fillColor: fieldFill,
                    ),
                  ],
                  // 사설: 직접 입력
                  if (_type == 'private_mock') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _privateLabelController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.gradeInput_privateHint,
                        labelText: AppLocalizations.of(context)!.gradeInput_privateLabel,
                        filled: true,
                        fillColor: fieldFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 과목 추가 버튼 ──
            _sectionLabel(AppLocalizations.of(context)!.gradeInput_subjectSection),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (!_isMock)
                  _actionChip(
                    icon: Icons.calendar_today,
                    label: AppLocalizations.of(context)!.gradeInput_fromTimetable,
                    onTap: _loadFromTimetable,
                  ),
                if (_isMock)
                  _actionChip(
                    icon: Icons.list_alt,
                    label: AppLocalizations.of(context)!.gradeInput_mockSubjects,
                    onTap: _loadMockSubjects,
                  ),
                _actionChip(
                  icon: Icons.add,
                  label: AppLocalizations.of(context)!.gradeInput_addManual,
                  onTap: _addManualSubject,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── 점수 입력 ──
            if (_subjects.isNotEmpty) ...[
              // 헤더
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  const SizedBox(width: 36), // dot + gap
                  Expanded(flex: 3, child: Text(AppLocalizations.of(context)!.gradeInput_subjectCol, style: _headerStyle)),
                  if (!_isMock) ...[
                    Expanded(flex: 2, child: Text(AppLocalizations.of(context)!.gradeInput_rawScore, style: _headerStyle, textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text(AppLocalizations.of(context)!.gradeInput_average, style: _headerStyle, textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text(AppLocalizations.of(context)!.gradeInput_rank, style: _headerStyle, textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text(AppLocalizations.of(context)!.gradeInput_achievement, style: _headerStyle, textAlign: TextAlign.center)),
                  ],
                  if (_isMock) ...[
                    Expanded(flex: 2, child: Text(AppLocalizations.of(context)!.gradeInput_percentile, style: _headerStyle, textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text(AppLocalizations.of(context)!.gradeInput_standard, style: _headerStyle, textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text(AppLocalizations.of(context)!.gradeInput_rank, style: _headerStyle, textAlign: TextAlign.center)),
                  ],
                  const SizedBox(width: 32), // delete button
                ]),
              ),
              const Divider(height: 1),
              ..._subjects.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final color = Color(GradeManager.getSubjectColor(s.name));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      // 과목명 (18px 여유)
                      Expanded(
                        flex: 3,
                        child: Text(
                          s.name,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!_isMock) ...[
                        Expanded(flex: 2, child: _scoreField(s.rawScoreCtrl, fieldFill, isInt: true)),
                        Expanded(flex: 2, child: _scoreField(s.averageCtrl, fieldFill)),
                        Expanded(flex: 2, child: _miniDropdown<int>(
                          value: int.tryParse(s.rankCtrl.text),
                          items: [1, 2, 3, 4, 5],
                          onChanged: (v) => setState(() => s.rankCtrl.text = v?.toString() ?? ''),
                          fillColor: fieldFill,
                        )),
                        Expanded(flex: 2, child: _miniDropdown<String>(
                          value: s.achievement,
                          items: SubjectScore.achievements,
                          onChanged: (v) => setState(() => s.achievement = v),
                          fillColor: fieldFill,
                        )),
                      ],
                      if (_isMock) ...[
                        Expanded(flex: 2, child: _scoreField(s.percentileCtrl, fieldFill)),
                        Expanded(flex: 2, child: _scoreField(s.standardScoreCtrl, fieldFill)),
                        Expanded(flex: 2, child: _scoreField(s.rankCtrl, fieldFill, isInt: true)),
                      ],
                      SizedBox(
                        width: 32,
                        child: IconButton(
                          icon: Icon(Icons.close, size: 16, color: AppColors.theme.darkGreyColor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final old = _subjects[idx];
                            setState(() => _subjects.removeAt(idx));
                            old.dispose();
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            if (_subjects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.gradeInput_noSubjects,
                    style: TextStyle(fontSize: 14, color: AppColors.theme.darkGreyColor),
                  ),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.theme.darkGreyColor,
  );

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).textTheme.bodyLarge?.color,
    ),
  );

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    required Color fillColor,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(itemLabel(v), style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _actionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.theme.primaryColor),
      label: Text(label, style: TextStyle(fontSize: 13, color: AppColors.theme.primaryColor)),
      backgroundColor: AppColors.theme.primaryColor.withAlpha(15),
      side: BorderSide(color: AppColors.theme.primaryColor.withAlpha(40)),
      onPressed: onTap,
    );
  }

  Widget _miniDropdown<T>({required T? value, required List<T> items, required ValueChanged<T?> onChanged, required Color fillColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: items.contains(value) ? value : null,
            isExpanded: true,
            isDense: true,
            alignment: Alignment.center,
            hint: Text('-', style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor), textAlign: TextAlign.center),
            items: items.map((e) => DropdownMenuItem<T>(
              value: e,
              alignment: Alignment.center,
              child: Text('$e', style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _scoreField(TextEditingController ctrl, Color fillColor, {bool isInt = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
        inputFormatters: isInt
            ? [FilteringTextInputFormatter.digitsOnly]
            : [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

/// 과목별 점수 입력 상태
class _SubjectEntry {
  final String name;
  final TextEditingController rawScoreCtrl;
  final TextEditingController averageCtrl;
  final TextEditingController rankCtrl;
  final TextEditingController standardScoreCtrl;
  final TextEditingController percentileCtrl;
  String? achievement; // 성취도 A~E

  _SubjectEntry({
    required this.name,
    TextEditingController? rawScoreCtrl,
    TextEditingController? averageCtrl,
    TextEditingController? rankCtrl,
    TextEditingController? standardScoreCtrl,
    TextEditingController? percentileCtrl,
    this.achievement,
  })  : rawScoreCtrl = rawScoreCtrl ?? TextEditingController(),
        averageCtrl = averageCtrl ?? TextEditingController(),
        rankCtrl = rankCtrl ?? TextEditingController(),
        standardScoreCtrl = standardScoreCtrl ?? TextEditingController(),
        percentileCtrl = percentileCtrl ?? TextEditingController();

  void dispose() {
    rawScoreCtrl.dispose();
    averageCtrl.dispose();
    rankCtrl.dispose();
    standardScoreCtrl.dispose();
    percentileCtrl.dispose();
  }
}
