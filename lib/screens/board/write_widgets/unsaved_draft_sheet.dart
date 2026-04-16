import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

Future<String?> showUnsavedDraftSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = Theme.of(context).textTheme.bodyLarge?.color;

  return showModalBottomSheet<String>(
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
        Text(AppLocalizations.of(context)!.write_unsavedChanges, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          Expanded(child: TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: Text(AppLocalizations.of(context)!.write_draftDelete, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.theme.primaryColor, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: Text(AppLocalizations.of(context)!.write_draftSave),
          )),
        ])),
        const SizedBox(height: 12),
      ])),
    ),
  );
}
