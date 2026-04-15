import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/data/grade_manager.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/providers/grade_provider.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/screens/sub/grade_input_screen.dart';
import 'package:hansol_high_school/widgets/grade/grade_chart.dart';
import 'package:hansol_high_school/styles/responsive.dart';
import 'package:intl/intl.dart';

class GradeScreen extends ConsumerStatefulWidget {
  const GradeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends ConsumerState<GradeScreen> {
  int _tabIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
          Container(width: Responsive.w(context, 36), height: 4, decoration: BoxDecoration(
            color: isDark ? Colors.grey[600] : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.grade_deleteTitle, style: TextStyle(fontSize: Responsive.sp(context, 17), fontWeight: FontWeight.w700,
            color: Theme.of(ctx).textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.grade_deleteMsg(exam.localizedDisplayName(AppLocalizations.of(context)!)),
            style: TextStyle(fontSize: Responsive.sp(context, 14), color: AppColors.theme.darkGreyColor)),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            Expanded(child: TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF2A2D35) : const Color(0xFFF0F0F0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(AppLocalizations.of(context)!.common_cancel, style: TextStyle(color: AppColors.theme.darkGreyColor)),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: Text(AppLocalizations.of(context)!.common_delete),
            )),
          ])),
          const SizedBox(height: 12),
        ])),
      ),
    );

    if (confirmed == true) {
      await ref.read(examsProvider.notifier).delete(exam.id);
    }
  }

  void _showGoalSheet(BuildContext context) async {
    final allExams = ref.read(examsProvider).valueOrNull ?? [];
    final filtered = _filterExams(allExams);
    final isJeongsi = _tabIndex == 1;
    final currentGoals = ref.read(goalsProvider).valueOrNull ?? {};
    final currentJGoals = ref.read(jeongsiGoalsProvider).valueOrNull ?? {};

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
          SnackBar(content: Text(AppLocalizations.of(context)!.grade_noDataMsg)),
        );
      }
      return;
    }

    final tempGoals = Map<String, double>.from(isJeongsi ? currentJGoals : currentGoals);

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
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: Responsive.w(context, 40),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      isJeongsi ? AppLocalizations.of(context)!.grade_targetTitle : AppLocalizations.of(context)!.grade_targetGradeTitle,
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 18),
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
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
                              width: Responsive.r(context, 10),
                              height: Responsive.r(context, 10),
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
                                  fontSize: Responsive.sp(context, 15),
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (isJeongsi)
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
                                    child: Icon(Icons.remove_circle_outline, size: Responsive.r(context, 22),
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
                                              Text('$subject 목표 백분위', style: TextStyle(fontSize: Responsive.sp(context, 16), fontWeight: FontWeight.w700, color: textColor)),
                                              const SizedBox(height: 12),
                                              TextField(
                                                controller: ctrl, autofocus: true, keyboardType: TextInputType.number,
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  hintText: AppLocalizations.of(context)!.gradeInput_hintScore, filled: true,
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
                                                child: Text(AppLocalizations.of(context)!.common_confirm),
                                              ),
                                            ])),
                                          ),
                                        ),
                                      );
                                      if (val != null) setSheetState(() => tempGoals[subject] = val);
                                    },
                                    child: Container(
                                      width: Responsive.w(context, 60), alignment: Alignment.center,
                                      child: Text(
                                        currentGoal != null ? '${currentGoal.toInt()}%' : '-',
                                        style: TextStyle(fontSize: Responsive.sp(context, 15), fontWeight: FontWeight.w700,
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
                                    child: Icon(Icons.add_circle_outline, size: Responsive.r(context, 22),
                                      color: currentGoal != null && currentGoal < 100
                                          ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor),
                                  ),
                                if (currentGoal != null) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => setSheetState(() => tempGoals.remove(subject)),
                                    child: Icon(Icons.close, size: Responsive.r(context, 16), color: AppColors.theme.darkGreyColor),
                                  ),
                                ],
                              ],
                            )
                            else
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
                                    child: Icon(Icons.remove_circle_outline, size: Responsive.r(context, 22),
                                      color: currentGoal != null && currentGoal > 1.0
                                          ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor),
                                  ),
                                  Container(
                                    width: Responsive.w(context, 52), alignment: Alignment.center,
                                    child: Text(
                                      currentGoal != null ? currentGoal.toStringAsFixed(1) : '-',
                                      style: TextStyle(fontSize: Responsive.sp(context, 15), fontWeight: FontWeight.w700,
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
                                    child: Icon(Icons.add_circle_outline, size: Responsive.r(context, 22),
                                      color: currentGoal != null && currentGoal < 5.0
                                          ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor),
                                  ),
                                  if (currentGoal != null) ...[
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => setSheetState(() => tempGoals.remove(subject)),
                                      child: Icon(Icons.close, size: Responsive.r(context, 16), color: AppColors.theme.darkGreyColor),
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
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isJeongsi) {
                            await ref.read(jeongsiGoalsProvider.notifier).save(tempGoals);
                          } else {
                            await ref.read(goalsProvider.notifier).save(tempGoals);
                          }
                          if (mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.common_save,
                          style: TextStyle(fontSize: Responsive.sp(context, 16), fontWeight: FontWeight.w600),
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
        title: Text(AppLocalizations.of(context)!.grade_screenTitle),
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
          if (result == true) ref.invalidate(examsProvider);
        },
        backgroundColor: AppColors.theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
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
                  Icon(Icons.info_outline, size: Responsive.r(context, 16), color: AppColors.theme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.grade_notice,
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 12),
                        color: AppColors.theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

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
                          _buildTab(AppLocalizations.of(context)!.grade_sujungTab, 0, isDark),
                          _buildTab(AppLocalizations.of(context)!.grade_jeongsiTab, 1, isDark),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: ref.watch(examsProvider).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.grade_loadFailed(e))),
                  data: (allExams) => PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) => setState(() => _tabIndex = i),
                    children: [
                      _buildExamList(allExams, 0, context, isDark, cardColor, textColor),
                      _buildExamList(allExams, 1, context, isDark, cardColor, textColor),
                    ],
                  ),
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
    final goals = tabIdx == 0
        ? (ref.watch(goalsProvider).valueOrNull ?? const {})
        : (ref.watch(jeongsiGoalsProvider).valueOrNull ?? const {});

    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: Responsive.r(context, 48), color: AppColors.theme.darkGreyColor),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.grade_addPrompt, style: TextStyle(color: AppColors.theme.darkGreyColor)),
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
            goals: goals,
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
            if (result == true) ref.invalidate(examsProvider);
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
                              width: Responsive.r(context, 56),
                              height: Responsive.r(context, 56),
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
                                              fontSize: Responsive.sp(context, 16),
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.theme.primaryColor,
                                            ),
                                          ),
                                          Text(
                                            AppLocalizations.of(context)!.grade_averageLabel,
                                            style: TextStyle(
                                              fontSize: Responsive.sp(context, 10),
                                              color: AppColors.theme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Icon(
                                        Icons.edit_note,
                                        size: Responsive.r(context, 24),
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
                                    exam.localizedDisplayName(AppLocalizations.of(context)!),
                                    style: TextStyle(
                                      fontSize: Responsive.sp(context, 16),
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
                                          fontSize: Responsive.sp(context, 13),
                                          color: AppColors.theme.mealTypeTextColor,
                                        ),
                                      ),
                                      if (avgRank != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: Responsive.r(context, 4),
                                          height: Responsive.r(context, 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.theme.darkGreyColor.withAlpha(80),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(context)!.grade_averageRank(avgRank.toStringAsFixed(1)),
                                          style: TextStyle(
                                            fontSize: Responsive.sp(context, 13),
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
                                              fontSize: Responsive.sp(context, 11),
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
                                fontSize: Responsive.sp(context, 12),
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
          child: Center(child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: Responsive.sp(context, 14),
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
