import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class ConflictDialog extends StatelessWidget {
  final String dayName;
  final String period;
  final List<String> subjects;

  const ConflictDialog({
    super.key,
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
              AppLocalizations.of(context)!.timetable_conflictTitle(dayName, period),
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.timetable_conflictQuestion,
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
