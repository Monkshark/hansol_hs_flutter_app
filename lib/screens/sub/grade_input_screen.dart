import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/grade_manager.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/sub/grade_input_widgets/subject_entry.dart';
import 'package:hansol_high_school/screens/sub/grade_input_widgets/grade_form_fields.dart';
import 'package:hansol_high_school/screens/sub/grade_input_widgets/subject_pickers.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class GradeInputScreen extends StatefulWidget {
  final Exam? exam;
  final bool isMock;

  const GradeInputScreen({super.key, this.exam, this.isMock = false});

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

  final List<SubjectEntry> _subjects = [];
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
      _subjects.add(SubjectEntry(
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

    if (!mounted) return;
    final selected = await showSubjectPicker(context, available, AppLocalizations.of(context)!.gradeInput_selectSubjects);
    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (final name in selected) {
          _subjects.add(SubjectEntry(name: name));
        }
      });
    }
  }

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

    final selected = await showMockSubjectPicker(context, existing);
    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (final name in selected) {
          _subjects.add(SubjectEntry(name: name));
        }
      });
    }
  }

  Future<void> _addManualSubject() async {
    final name = await showAddManualSubjectSheet(context);
    if (name != null && name.isNotEmpty) {
      if (_subjects.any((s) => s.name == name)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.gradeInput_addSubjectDuplicate(name))),
          );
        }
        return;
      }
      setState(() => _subjects.add(SubjectEntry(name: name)));
    }
  }

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
                    final old = !_isEdit ? List.of(_subjects) : <SubjectEntry>[];
                    setState(() {
                      _type = e.key;
                      if (!_isEdit) _subjects.clear();
                    });
                    for (final s in old) { s.dispose(); }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

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
                  Row(children: [
                    Expanded(child: GradeDropdown<int>(
                      label: AppLocalizations.of(context)!.gradeInput_year,
                      value: _year,
                      items: List.generate(5, (i) => DateTime.now().year - 2 + i),
                      itemLabel: (v) => AppLocalizations.of(context)!.gradeInput_yearSuffix(v),
                      onChanged: (v) => setState(() => _year = v!),
                      fillColor: fieldFill,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: GradeDropdown<int>(
                      label: AppLocalizations.of(context)!.gradeInput_semester,
                      value: _semester,
                      items: [1, 2],
                      itemLabel: (v) => AppLocalizations.of(context)!.gradeInput_semesterSuffix(v),
                      onChanged: (v) => setState(() => _semester = v!),
                      fillColor: fieldFill,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: GradeDropdown<int>(
                      label: AppLocalizations.of(context)!.gradeInput_grade,
                      value: _grade,
                      items: [1, 2, 3],
                      itemLabel: (v) => AppLocalizations.of(context)!.gradeInput_gradeSuffix(v),
                      onChanged: (v) => setState(() => _grade = v!),
                      fillColor: fieldFill,
                    )),
                  ]),
                  if (_type == 'mock') ...[
                    const SizedBox(height: 12),
                    GradeDropdown<String>(
                      label: AppLocalizations.of(context)!.gradeInput_month,
                      value: _mockMonth,
                      items: _mockMonthKeys,
                      itemLabel: (v) => AppLocalizations.of(context)!.gradeInput_mockMonthSuffix(_localizedMonths(AppLocalizations.of(context)!)[v] ?? v),
                      onChanged: (v) => setState(() => _mockMonth = v!),
                      fillColor: fieldFill,
                    ),
                  ],
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

            if (_subjects.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  const SizedBox(width: 36),
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
                  const SizedBox(width: 32),
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
                      Expanded(
                        flex: 3,
                        child: Text(
                          s.name,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!_isMock) ...[
                        Expanded(flex: 2, child: GradeScoreField(controller: s.rawScoreCtrl, fillColor: fieldFill, isInt: true)),
                        Expanded(flex: 2, child: GradeScoreField(controller: s.averageCtrl, fillColor: fieldFill)),
                        Expanded(flex: 2, child: GradeMiniDropdown<int>(
                          value: int.tryParse(s.rankCtrl.text),
                          items: [1, 2, 3, 4, 5],
                          onChanged: (v) => setState(() => s.rankCtrl.text = v?.toString() ?? ''),
                          fillColor: fieldFill,
                        )),
                        Expanded(flex: 2, child: GradeMiniDropdown<String>(
                          value: s.achievement,
                          items: SubjectScore.achievements,
                          onChanged: (v) => setState(() => s.achievement = v),
                          fillColor: fieldFill,
                        )),
                      ],
                      if (_isMock) ...[
                        Expanded(flex: 2, child: GradeScoreField(controller: s.percentileCtrl, fillColor: fieldFill)),
                        Expanded(flex: 2, child: GradeScoreField(controller: s.standardScoreCtrl, fillColor: fieldFill)),
                        Expanded(flex: 2, child: GradeScoreField(controller: s.rankCtrl, fillColor: fieldFill, isInt: true)),
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

  TextStyle get _headerStyle => TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.theme.darkGreyColor);

  Widget _sectionLabel(String text) => Text(text,
    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color));

  Widget _actionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.theme.primaryColor),
      label: Text(label, style: TextStyle(fontSize: 13, color: AppColors.theme.primaryColor)),
      backgroundColor: AppColors.theme.primaryColor.withAlpha(15),
      side: BorderSide(color: AppColors.theme.primaryColor.withAlpha(40)),
      onPressed: onTap,
    );
  }
}
