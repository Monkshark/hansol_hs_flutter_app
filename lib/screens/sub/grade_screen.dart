import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/grade_manager.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/screens/sub/grade_input_screen.dart';
import 'package:hansol_high_school/widgets/grade/grade_chart.dart';
import 'package:intl/intl.dart';

/// 성적 관리 화면
class GradeScreen extends StatefulWidget {
  const GradeScreen({Key? key}) : super(key: key);

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen> {
  /// 0 = 내신, 1 = 모의고사
  int _tabIndex = 0;
  late Future<List<Exam>> _examsFuture;
  Map<String, double> _goals = {};
  Map<String, double> _jeongsiGoals = {};
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _examsFuture = GradeManager.loadExams();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await GradeManager.loadGoals();
    final jGoals = await GradeManager.loadJeongsiGoals();
    if (mounted) setState(() { _goals = goals; _jeongsiGoals = jGoals; });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _examsFuture = GradeManager.loadExams();
    });
  }

  List<Exam> _filterExams(List<Exam> exams) {
    if (_tabIndex == 0) {
      return exams.where((e) => e.type == 'midterm' || e.type == 'final').toList();
    } else {
      return exams.where((e) => e.type == 'mock' || e.type == 'private_mock').toList();
    }
  }

  double? _averageRank(Exam exam) {
    final ranks = exam.scores.where((s) => s.rank != null).map((s) => s.rank!).toList();
    if (ranks.isEmpty) return null;
    return ranks.reduce((a, b) => a + b) / ranks.length;
  }

  Future<void> _deleteExam(Exam exam) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2028) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4, decoration: BoxDecoration(
            color: isDark ? Colors.grey[600] : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('시험 삭제', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
            color: Theme.of(ctx).textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          Text('${exam.displayName}을(를) 삭제하시겠습니까?',
            style: TextStyle(fontSize: 14, color: AppColors.theme.darkGreyColor)),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            Expanded(child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF2A2D35) : const Color(0xFFF0F0F0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('취소', style: TextStyle(color: AppColors.theme.darkGreyColor)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('삭제'),
            )),
          ])),
          const SizedBox(height: 12),
        ])),
      ),
    );

    if (confirmed == true) {
      await GradeManager.deleteExam(exam.id);
      _reload();
    }
  }

  void _showGoalSheet(BuildContext context) async {
    final allExams = await _examsFuture;
    final filtered = _filterExams(allExams);
    final isJeongsi = _tabIndex == 1;

    // Collect unique subjects in order of first appearance
    const absoluteGradeSubjects = {'영어', '한국사'};
    final subjects = <String>[];
    for (final exam in filtered) {
      for (final score in exam.scores) {
        if (!subjects.contains(score.subject)) {
          if (isJeongsi && absoluteGradeSubjects.contains(score.subject)) continue;
          subjects.add(score.subject);
        }
      }
    }

    if (subjects.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('시험 데이터가 없습니다')),
        );
      }
      return;
    }

    // Local copy of goals for editing
    final tempGoals = Map<String, double>.from(isJeongsi ? _jeongsiGoals : _goals);

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetColor = isDark ? const Color(0xFF1E2028) : Colors.white;
        final textColor = Theme.of(ctx).textTheme.bodyLarge?.color;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      isJeongsi ? '과목별 목표 백분위' : '과목별 목표 등급',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Subject list
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: subjects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final subject = subjects[i];
                        final color = Color(GradeManager.getSubjectColor(subject));
                        final currentGoal = tempGoals[subject];

                        return Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (isJeongsi)
                              // 정시: 백분위 1씩 조절 또는 직접 입력
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => setSheetState(() {
                                      if (currentGoal == null) {
                                        tempGoals[subject] = 90;
                                      } else if (currentGoal > 0) {
                                        tempGoals[subject] = (currentGoal - 1).clamp(0, 100);
                                      }
                                    }),
                                    child: Icon(Icons.remove_circle_outline, size: 22,
                                      color: currentGoal != null && currentGoal > 0
                                          ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final ctrl = TextEditingController(text: currentGoal?.toInt().toString() ?? '');
                                      final val = await showModalBottomSheet<double>(
                                        context: ctx,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (c) => Padding(
                                          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
                                          child: Container(
                                            margin: const EdgeInsets.all(12),
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: sheetColor, borderRadius: BorderRadius.circular(16)),
                                            child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                                              Text('$subject 목표 백분위', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                                              const SizedBox(height: 12),
                                              TextField(
                                                controller: ctrl, autofocus: true, keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  hintText: '0~100', filled: true,
                                                  fillColor: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                                ),
                                                onSubmitted: (t) { final v = double.tryParse(t); if (v != null) Navigator.pop(c, v.clamp(0, 100)); },
                                              ),
                                              const SizedBox(height: 12),
                                              ElevatedButton(
                                                onPressed: () { final v = double.tryParse(ctrl.text); if (v != null) Navigator.pop(c, v.clamp(0, 100)); },
                                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.theme.primaryColor, foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0, minimumSize: const Size(double.infinity, 44)),
                                                child: const Text('확인'),
                                              ),
                                            ])),
                                          ),
                                        ),
                                      );
                                      if (val != null) setSheetState(() => tempGoals[subject] = val);
                                    },
                                    child: Container(
                                      width: 60, alignment: Alignment.center,
                                      child: Text(
                                        currentGoal != null ? '${currentGoal.toInt()}%' : '-',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                          color: currentGoal != null ? textColor : AppColors.theme.darkGreyColor),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setSheetState(() {
                                      if (currentGoal == null) {
                                        tempGoals[subject] = 90;
                                      } else if (currentGoal < 100) {
                                        tempGoals[subject] = (currentGoal + 1).clamp(0, 100);
                                      }
                                    }),
                                    child: Icon(Icons.add_circle_outline, size: 22,
                                      color: currentGoal != null && currentGoal < 100
                                          ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor),
                                  ),
                                if (currentGoal != null) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => setSheetState(() => tempGoals.remove(subject)),
                                    child: Icon(Icons.close, size: 16, color: AppColors.theme.darkGreyColor),
                                  ),
                                ],
                              ],
                            )
                            else
                              // 수시: 등급 0.1씩 조절
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => setSheetState(() {
                                      if (currentGoal == null) {
                                        tempGoals[subject] = 5.0;
                                      } else if (currentGoal > 1.0) {
                                        tempGoals[subject] = ((currentGoal - 0.1) * 10).round() / 10;
                                      }
                                    }),
                                    child: Icon(Icons.remove_circle_outline, size: 22,
                                      color: currentGoal != null && currentGoal > 1.0
                                          ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor),
                                  ),
                                  Container(
                                    width: 52, alignment: Alignment.center,
                                    child: Text(
                                      currentGoal != null ? currentGoal.toStringAsFixed(1) : '-',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                        color: currentGoal != null ? textColor : AppColors.theme.darkGreyColor),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setSheetState(() {
                                      if (currentGoal == null) {
                                        tempGoals[subject] = 1.0;
                                      } else if (currentGoal < 5.0) {
                                        tempGoals[subject] = ((currentGoal + 0.1) * 10).round() / 10;
                                      }
                                    }),
                                    child: Icon(Icons.add_circle_outline, size: 22,
                                      color: currentGoal != null && currentGoal < 5.0
                                          ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor),
                                  ),
                                  if (currentGoal != null) ...[
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => setSheetState(() => tempGoals.remove(subject)),
                                      child: Icon(Icons.close, size: 16, color: AppColors.theme.darkGreyColor),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  // Save button
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isJeongsi) {
                            await GradeManager.saveJeongsiGoals(tempGoals);
                          } else {
                            await GradeManager.saveGoals(tempGoals);
                          }
                          if (mounted) {
                            Navigator.pop(ctx);
                            _loadGoals();
                            _reload();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = isDark ? const Color(0xFF1E2028) : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: const Text('성적 관리'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: '목표 설정',
            onPressed: () => _showGoalSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => GradeInputScreen(isMock: _tabIndex == 1)),
          );
          if (result == true) _reload();
        },
        backgroundColor: AppColors.theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Notice banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.theme.primaryColor.withAlpha(20)
                    : AppColors.theme.primaryColor.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.theme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '성적 점수는 서버에 저장되지 않습니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab toggle with sliding indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = (constraints.maxWidth - 8) / 2;
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        left: _tabIndex * tabWidth,
                        top: 0, bottom: 0,
                        width: tabWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2028) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(isDark ? 40 : 15),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _buildTab('수시', 0, isDark),
                          _buildTab('정시', 1, isDark),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Exam list
          Expanded(
            child: FutureBuilder<List<Exam>>(
              future: _examsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allExams = snapshot.data ?? [];

                return PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _tabIndex = i),
                  children: [
                    _buildExamList(allExams, 0, context, isDark, cardColor, textColor),
                    _buildExamList(allExams, 1, context, isDark, cardColor, textColor),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamList(List<Exam> allExams, int tabIdx, BuildContext context, bool isDark, Color cardColor, Color? textColor) {
    final exams = allExams.where((e) {
      if (tabIdx == 0) return e.type == 'midterm' || e.type == 'final';
      return e.type == 'mock' || e.type == 'private_mock';
    }).toList();

    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: AppColors.theme.darkGreyColor),
            const SizedBox(height: 12),
            Text('시험을 추가하세요', style: TextStyle(color: AppColors.theme.darkGreyColor)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 80),
      itemCount: exams.length + (exams.length >= 2 ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (exams.length >= 2 && index == 0) {
          return GradeChart(
            exams: exams,
            goals: tabIdx == 0 ? _goals : _jeongsiGoals,
            maxRank: tabIdx == 0 ? 5 : 9,
            isJeongsi: tabIdx == 1,
          );
        }
        final realIndex = exams.length >= 2 ? index - 1 : index;
        final exam = exams[realIndex];
        final avgRank = _averageRank(exam);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => GradeInputScreen(exam: exam)),
            );
            if (result == true) _reload();
          },
          onLongPress: () => _deleteExam(exam),
          child: Container(
            padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.theme.primaryColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: avgRank != null
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            avgRank.toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.theme.primaryColor,
                                            ),
                                          ),
                                          Text(
                                            '평균',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.theme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Icon(
                                        Icons.edit_note,
                                        size: 24,
                                        color: AppColors.theme.primaryColor,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exam.displayName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${exam.scores.length}과목',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.theme.mealTypeTextColor,
                                        ),
                                      ),
                                      if (avgRank != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: AppColors.theme.darkGreyColor.withAlpha(80),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '평균 ${avgRank.toStringAsFixed(1)}등급',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.theme.mealTypeTextColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (exam.type == 'midterm' || exam.type == 'final') ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: exam.scores
                                          .where((s) => s.achievement != null)
                                          .map((s) {
                                        const achievementColors = <String, MaterialColor>{
                                          'A': Colors.green,
                                          'B': Colors.blue,
                                          'C': Colors.orange,
                                          'D': Colors.red,
                                          'E': Colors.grey,
                                        };
                                        final color = achievementColors[s.achievement] ?? Colors.grey;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withAlpha(isDark ? 40 : 25),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${s.subject} ${s.achievement}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? color.shade300 : color.shade700,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('yy.M.d').format(exam.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.theme.darkGreyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
  }

  Widget _buildTab(String label, int index, bool isDark) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _tabIndex = index);
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          // 기존 boxShadow 제거 — AnimatedPositioned 인디케이터가 대신 처리
          child: Center(child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
            child: Text(label),
          )),
        ),
      ),
    );
  }
}
