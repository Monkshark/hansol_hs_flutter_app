import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/post_repository.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

class ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  ActionItem(this.icon, this.label, this.onTap, {this.isDestructive = false});
}

void showPostActionSheet({
  required BuildContext context,
  required String postId,
  required Map<String, dynamic> data,
  required bool isAuthor,
  required bool isManager,
  required bool isPinned,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onPin,
  required VoidCallback onUnpin,
  required VoidCallback onReport,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l = AppLocalizations.of(context)!;
  final items = <ActionItem>[];

  items.add(ActionItem(Icons.share_outlined, l.post_share, () {
    final title = data['title'] ?? '';
    final deepLink = 'https://hansol-high-school-46fc9.web.app/post/$postId';
    SharePlus.instance.share(ShareParams(text: '[한솔고] $title\n$deepLink'));
  }));
  if (isAuthor) {
    items.add(ActionItem(Icons.edit_outlined, l.post_edit, onEdit));
    items.add(ActionItem(Icons.delete_outline, l.post_delete, onDelete, isDestructive: true));
  }
  if (!isAuthor && isManager) {
    items.add(ActionItem(Icons.delete_outline, l.post_deleteByAdmin, onDelete, isDestructive: true));
  }
  if (isManager && !isPinned) {
    items.add(ActionItem(Icons.push_pin_outlined, l.post_pinAsNotice, onPin));
  }
  if (isManager && isPinned) {
    items.add(ActionItem(Icons.push_pin, l.post_unpinNotice, onUnpin));
  }
  if (!isAuthor) {
    items.add(ActionItem(Icons.flag_outlined, l.post_report, onReport, isDestructive: true));
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
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
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => ListTile(
              leading: Icon(item.icon,
                color: item.isDestructive ? Colors.redAccent : (isDark ? Colors.white70 : Colors.black87), size: Responsive.r(context, 22)),
              title: Text(item.label, style: TextStyle(fontSize: Responsive.sp(context, 15), fontWeight: FontWeight.w500,
                color: item.isDestructive ? Colors.redAccent : (isDark ? Colors.white : Colors.black87))),
              onTap: () { Navigator.pop(ctx); item.onTap(); },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

Future<void> showReportSheet({
  required BuildContext context,
  required String postId,
}) async {
  if (!AuthService.isLoggedIn) return;

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l = AppLocalizations.of(context)!;
  String? selected;
  final reason = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Container(
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
          Text(l.post_reportSelectReason, style: TextStyle(fontSize: Responsive.sp(context, 17), fontWeight: FontWeight.w700,
            color: Theme.of(ctx).textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: selected,
            onChanged: (v) => setSheetState(() => selected = v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                l.post_reportReasonSwearing,
                l.post_reportReasonAdult,
                l.post_reportReasonSpam,
                l.post_reportReasonPrivacy,
                l.post_reportReasonOther,
              ].map((r) =>
                RadioListTile<String>(
                  value: r,
                  title: Text(r, style: TextStyle(fontSize: Responsive.sp(context, 14), color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                  activeColor: AppColors.theme.primaryColor,
                  dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ).toList(),
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selected != null ? () => Navigator.pop(ctx, selected) : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(l.post_reportButton),
            ),
          )),
        ])),
      ),
    ),
  );

  if (reason == null) return;

  final repo = PostRepository.instance;
  final existingReport = await FirebaseFirestore.instance.collection('reports')
      .where('postId', isEqualTo: postId)
      .where('reporterUid', isEqualTo: AuthService.currentUser!.uid)
      .limit(1).get();

  if (existingReport.docs.isNotEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.post_reportAlreadyReported)),
      );
    }
    return;
  }

  await repo.reportPost(
    postId: postId,
    reporterUid: AuthService.currentUser!.uid,
    reason: reason,
  );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.post_reportSuccess)),
    );
  }
}

Future<bool?> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmLabel,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<bool>(
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
        Text(title, style: TextStyle(fontSize: Responsive.sp(context, 17), fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(fontSize: Responsive.sp(context, 14), color: AppColors.theme.darkGreyColor)),
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
            child: Text(confirmLabel),
          )),
        ])),
        const SizedBox(height: 12),
      ])),
    ),
  );
}
