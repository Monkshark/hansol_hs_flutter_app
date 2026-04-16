import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/widgets/error_view.dart';

class DeleteLogsTab extends StatefulWidget {
  const DeleteLogsTab({super.key});

  @override
  State<DeleteLogsTab> createState() => DeleteLogsTabState();
}

class DeleteLogsTabState extends State<DeleteLogsTab> {
  late Future<QuerySnapshot<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetch() =>
      FirebaseFirestore.instance
          .collection('admin_logs')
          .where('action', whereIn: ['delete_post', 'delete_feedback'])
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: AppLocalizations.of(context)!.error_loadFailed,
            onRetry: () { setState(() => _future = _fetch()); },
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(AppLocalizations.of(context)!.admin_logsEmpty,
                  style: TextStyle(color: AppColors.theme.darkGreyColor)),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final action = data['action'] ?? '';
            final l = AppLocalizations.of(context)!;
            final adminName = data['adminName'] ?? 'Admin';
            final isFeedback = action == 'delete_feedback';
            final title = isFeedback
                ? (data['feedbackContent'] ?? l.admin_logsNoContent)
                : (data['postTitle'] ?? l.admin_logsNoTitle);
            final authorName = isFeedback
                ? (data['feedbackAuthorName'] ?? l.admin_logsUnknown)
                : (data['postAuthorName'] ?? l.admin_logsUnknown);
            final label = isFeedback ? l.admin_logsFeedbackDeleted : l.admin_logsPostDeleted;
            final labelColor = isFeedback ? Colors.orange : Colors.red;
            final createdAt = data['createdAt'] as Timestamp?;
            final timeStr = createdAt != null
                ? '${createdAt.toDate().month}/${createdAt.toDate().day} ${createdAt.toDate().hour}:${createdAt.toDate().minute.toString().padLeft(2, '0')}'
                : '';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2028) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: labelColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(label, style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: labelColor)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(title, style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(l.admin_logsAuthor(authorName), style: TextStyle(
                      fontSize: 12, color: AppColors.theme.darkGreyColor)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(l.admin_logsDeletedBy(adminName), style: TextStyle(
                          fontSize: 12, color: AppColors.theme.primaryColor)),
                      const Spacer(),
                      Text(timeStr, style: TextStyle(
                          fontSize: 11, color: AppColors.theme.darkGreyColor)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
