import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/data/grade_manager.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/providers/grade_provider.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';

/// 성적 목표 설정 바텀시트.
/// [showGoalSettingSheet]를 호출하여 사용.
Future<void> showGoalSettingSheet({
  required BuildContext context,
  required WidgetRef ref,
  required bool isJeongsi,
  required List<Exam> filteredExams,
}) async {
  final currentGoals = ref.read(isJeongsi ? jeongsiGoalsProvider : goalsProvider).valueOrNull ?? {};

  const absoluteGradeSubjects = {'영어', '한국사'};
  final subjects = <String>[];
  for (final exam in filteredExams) {
    for (final score in exam.scores) {
      if (!subjects.contains(score.subject)) {
        if (isJeongsi && absoluteGradeSubjects.contains(score.subject)) continue;
        subjects.add(score.subject);
      }
    }
  }

  if (subjects.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.grade_noDataMsg)),
    );
    return;
  }

  final tempGoals = Map<String, double>.from(currentGoals);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _GoalSettingSheetContent(
      ref: ref,
      isJeongsi: isJeongsi,
      subjects: subjects,
      tempGoals: tempGoals,
    ),
  );
}

class _GoalSettingSheetContent extends StatefulWidget {
  final WidgetRef ref;
  final bool isJeongsi;
  final List<String> subjects;
  final Map<String, double> tempGoals;

  const _GoalSettingSheetContent({
    required this.ref,
    required this.isJeongsi,
    required this.subjects,
    required this.tempGoals,
  });

  @override
  State<_GoalSettingSheetContent> createState() => _GoalSettingSheetContentState();
}

class _GoalSettingSheetContentState extends State<_GoalSettingSheetContent> {
  late final Map<String, double> _tempGoals = Map.from(widget.tempGoals);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1E2028) : Colors.white;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
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
              widget.isJeongsi
                  ? AppLocalizations.of(context)!.grade_targetTitle
                  : AppLocalizations.of(context)!.grade_targetGradeTitle,
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
              itemCount: widget.subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final subject = widget.subjects[i];
                final color = Color(GradeManager.getSubjectColor(subject));
                final currentGoal = _tempGoals[subject];

                return Row(
                  children: [
                    Container(
                      width: Responsive.r(context, 10),
                      height: Responsive.r(context, 10),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(subject,
                        style: TextStyle(fontSize: Responsive.sp(context, 15), fontWeight: FontWeight.w500, color: textColor)),
                    ),
                    if (widget.isJeongsi)
                      _buildJeongsiControls(subject, currentGoal, textColor, sheetColor, isDark)
                    else
                      _buildSujungControls(subject, currentGoal, textColor),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (widget.isJeongsi) {
                    await widget.ref.read(jeongsiGoalsProvider.notifier).save(_tempGoals);
                  } else {
                    await widget.ref.read(goalsProvider.notifier).save(_tempGoals);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text(AppLocalizations.of(context)!.common_save,
                  style: TextStyle(fontSize: Responsive.sp(context, 16), fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJeongsiControls(String subject, double? currentGoal, Color? textColor, Color sheetColor, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            if (currentGoal == null) {
              _tempGoals[subject] = 90;
            } else if (currentGoal > 0) {
              _tempGoals[subject] = (currentGoal - 1).clamp(0, 100);
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
              context: context,
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
                    Text(AppLocalizations.of(context)!.grade_goalPercentileTitle(subject),
                      style: TextStyle(fontSize: Responsive.sp(context, 16), fontWeight: FontWeight.w700, color: textColor)),
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
            if (val != null) setState(() => _tempGoals[subject] = val);
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
          onTap: () => setState(() {
            if (currentGoal == null) {
              _tempGoals[subject] = 90;
            } else if (currentGoal < 100) {
              _tempGoals[subject] = (currentGoal + 1).clamp(0, 100);
            }
          }),
          child: Icon(Icons.add_circle_outline, size: Responsive.r(context, 22),
            color: currentGoal != null && currentGoal < 100
                ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor),
        ),
        if (currentGoal != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _tempGoals.remove(subject)),
            child: Icon(Icons.close, size: Responsive.r(context, 16), color: AppColors.theme.darkGreyColor),
          ),
        ],
      ],
    );
  }

  Widget _buildSujungControls(String subject, double? currentGoal, Color? textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            if (currentGoal == null) {
              _tempGoals[subject] = 5.0;
            } else if (currentGoal > 1.0) {
              _tempGoals[subject] = ((currentGoal - 0.1) * 10).round() / 10;
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
          onTap: () => setState(() {
            if (currentGoal == null) {
              _tempGoals[subject] = 1.0;
            } else if (currentGoal < 5.0) {
              _tempGoals[subject] = ((currentGoal + 0.1) * 10).round() / 10;
            }
          }),
          child: Icon(Icons.add_circle_outline, size: Responsive.r(context, 22),
            color: currentGoal != null && currentGoal < 5.0
                ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor),
        ),
        if (currentGoal != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _tempGoals.remove(subject)),
            child: Icon(Icons.close, size: Responsive.r(context, 16), color: AppColors.theme.darkGreyColor),
          ),
        ],
      ],
    );
  }
}
