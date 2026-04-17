import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/grade_manager.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

Future<List<String>?> showSubjectPicker(BuildContext context, List<String> available, String title) {
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
                      final result = checked.entries.where((e) => e.value).map((e) => e.key).toList();
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

Future<List<String>?> showMockSubjectPicker(BuildContext context, Set<String> existing) {
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
                      final result = checked.entries.where((e) => e.value).map((e) => e.key).toList();
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

Future<String?> showAddManualSubjectSheet(BuildContext context) {
  final ctrl = TextEditingController();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<String>(
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
}
