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
  Map<String, int> _goals = {};

  @override
  void initState() {
    super.initState();
    _examsFuture = GradeManager.loadExams();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await GradeManager.loadGoals();
    if (mounted) setState(() => _goals = goals);
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
    final confirmed = await showDialog<bool>(
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
                Text(
                  '시험 삭제',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(ctx).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${exam.displayName}을(를) 삭제하시겠습니까?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.theme.darkGreyColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('취소', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('삭제'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await GradeManager.deleteExam(exam.id);
      _reload();
    }
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const GradeInputScreen()),
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

          // Tab toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTab('내신', 0, isDark),
                  _buildTab('모의고사', 1, isDark),
                ],
              ),
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
                final exams = _filterExams(allExams);

                if (exams.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_outlined, size: 48, color: AppColors.theme.darkGreyColor),
                        const SizedBox(height: 12),
                        Text(
                          '시험을 추가하세요',
                          style: TextStyle(color: AppColors.theme.darkGreyColor),
                        ),
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
                      return GradeChart(exams: exams, goals: _goals);
                    }
                    final realIndex = exams.length >= 2 ? index - 1 : index;
                    final exam = exams[realIndex];
                    final avgRank = _averageRank(exam);

                    return GestureDetector(
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, bool isDark) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFF1E2028) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 40 : 15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? AppColors.theme.primaryColor
                    : AppColors.theme.darkGreyColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
