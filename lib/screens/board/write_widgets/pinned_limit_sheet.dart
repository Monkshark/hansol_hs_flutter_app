import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/data/post_repository.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

Future<String?> showPinnedLimitSheet(
  BuildContext context,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> pinnedDocs,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = Theme.of(context).textTheme.bodyLarge?.color;

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            )),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.write_pinLimitExceeded, style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.write_pinLimitMessage,
              style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor),
              textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ...pinnedDocs.map((doc) {
              final data = doc.data();
              final title = data['title'] ?? AppLocalizations.of(context)!.write_noTitle;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: GestureDetector(
                  onTap: () async {
                    try {
                      await PostRepository.instance.unpinPost(doc.id);
                      if (ctx.mounted) Navigator.pop(ctx, 'unpinned');
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(ctx)!.write_unpinFailed)),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(title, style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.write_pinUnpinAction, style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, 'cancel'),
                  child: Text(AppLocalizations.of(context)!.write_registerWithoutPin, style: TextStyle(
                    color: AppColors.theme.darkGreyColor, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
