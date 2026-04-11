import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';

class FeedbackListScreen extends StatelessWidget {
  final String type;
  final bool showAppBar;

  const FeedbackListScreen({Key? key, required this.type, this.showAppBar = false}) : super(key: key);

  String _title(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return type == 'app' ? l.feedback_listTitle : l.feedback_listCouncilTitle;
  }
  String get _collection => type == 'app' ? 'app_feedbacks' : 'council_feedbacks';

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final body = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(_collection)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.feedback_empty,
                style: TextStyle(color: AppColors.theme.darkGreyColor)),
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
              final content = data['content'] ?? '';
              final authorName = data['authorName'] ?? AppLocalizations.of(context)!.feedback_unknown;
              final createdAt = data['createdAt'] as Timestamp?;
              final status = data['status'] ?? 'pending';
              final imageUrls = List<String>.from(data['imageUrls'] ?? []);
              final timeStr = createdAt != null
                  ? DateFormat('M/d HH:mm').format(createdAt.toDate())
                  : '';

              return GestureDetector(
                onTap: () => _showDetail(context, docs[index]),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2028) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: status == 'resolved' ? Border.all(
                      color: const Color(0xFF4CAF50).withAlpha(80),
                    ) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusBadge(status: status),
                          const SizedBox(width: 8),
                          Text(authorName, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                          const Spacer(),
                          Text(timeStr, style: TextStyle(
                            fontSize: 11, color: AppColors.theme.darkGreyColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(content, style: TextStyle(fontSize: 14, color: textColor),
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                      if (imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.photo, size: 14, color: AppColors.theme.darkGreyColor),
                            const SizedBox(width: 4),
                            Text(AppLocalizations.of(context)!.feedback_photoCount(imageUrls.length), style: TextStyle(
                              fontSize: 12, color: AppColors.theme.darkGreyColor)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

    if (!showAppBar) return body;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: Text(_title(context)),
        centerTitle: true,
        elevation: 0,
      ),
      body: body,
    );
  }

  Future<void> _deleteFeedback(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data()!;
    final profile = await AuthService.getCachedProfile();
    await FirebaseFirestore.instance.collection('admin_logs').add({
      'action': 'delete_feedback',
      'adminUid': AuthService.currentUser?.uid ?? '',
      'adminName': profile?.displayName ?? '',
      'feedbackType': type,
      'feedbackContent': (data['content'] ?? '').toString().substring(0, (data['content'] ?? '').toString().length.clamp(0, 100)),
      'feedbackAuthorName': data['authorName'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    });
    await doc.reference.delete();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.feedback_deleted)));
    }
  }

  void _showDetail(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final status = data['status'] ?? 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2028) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusBadge(status: status),
                        const SizedBox(width: 8),
                        Text(data['authorName'] ?? '', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(data['content'] ?? '', style: TextStyle(
                      fontSize: 14, color: textColor, height: 1.6)),
                    if (imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...imageUrls.map((url) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      )),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (status != 'reviewed')
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                doc.reference.update({'status': 'reviewed'});
                                Navigator.pop(ctx);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(AppLocalizations.of(context)!.feedback_reviewed),
                            ),
                          ),
                        if (status != 'reviewed' && status != 'resolved')
                          const SizedBox(width: 10),
                        if (status != 'resolved')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                doc.reference.update({'status': 'resolved'});
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                              child: Text(AppLocalizations.of(context)!.feedback_resolved),
                            ),
                          ),
                      ],
                    ),
                    if (status == 'resolved') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _deleteFeedback(context, doc);
                          },
                          child: Text(AppLocalizations.of(context)!.feedback_delete, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Color color;
    String label;
    switch (status) {
      case 'reviewed':
        color = Colors.orange;
        label = l.feedback_reviewed;
        break;
      case 'resolved':
        color = const Color(0xFF4CAF50);
        label = l.feedback_resolved;
        break;
      default:
        color = AppColors.theme.darkGreyColor;
        label = l.feedback_pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
