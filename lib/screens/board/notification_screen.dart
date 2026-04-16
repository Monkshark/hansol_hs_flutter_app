import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/admin_screen.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.uid;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.notification_title)),
        body: Center(child: Text(AppLocalizations.of(context)!.common_loginRequired)),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: Text(AppLocalizations.of(context)!.notification_title),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _markAllRead(uid),
            child: Text(AppLocalizations.of(context)!.notification_markAllRead, style: TextStyle(fontSize: Responsive.sp(context, 13), color: AppColors.theme.primaryColor)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users').doc(uid).collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('오류가 발생했습니다'));
          }
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: Responsive.r(context, 40), color: AppColors.theme.darkGreyColor),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.notification_empty, style: TextStyle(color: AppColors.theme.darkGreyColor)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final type = data['type'] ?? '';
              final postId = data['postId'] ?? '';
              final senderName = data['senderName'] ?? '';
              final content = data['content'] ?? '';
              final postTitle = data['postTitle'] ?? '';
              final isRead = data['read'] == true;
              final createdAt = data['createdAt'] as Timestamp?;
              final timeStr = createdAt != null ? _formatTime(context, createdAt.toDate()) : '';

              final isAccount = type == 'account';
              final icon = type == 'comment'
                  ? Icons.chat_bubble_outline
                  : isAccount
                      ? Icons.person_outline
                      : Icons.reply;
              final message = type == 'comment'
                  ? AppLocalizations.of(context)!.notification_typeComment(senderName)
                  : isAccount
                      ? postTitle
                      : AppLocalizations.of(context)!.notification_typeReply(senderName);

              return GestureDetector(
                onTap: () {
                  if (!isRead) docs[index].reference.update({'read': true});
                  if (isAccount) {
                    final isManager = AuthService.cachedProfile?.isManager ?? false;
                    if (isManager) {
                      Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminScreen()));
                    }
                  } else if (postId.isNotEmpty) {
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isRead
                        ? (isDark ? const Color(0xFF1E2028) : Colors.white)
                        : (isDark ? const Color(0xFF252830) : const Color(0xFFF0F4FF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: Responsive.r(context, 36), height: Responsive.r(context, 36),
                        decoration: BoxDecoration(
                          color: AppColors.theme.primaryColor.withAlpha(isRead ? 15 : 30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: Responsive.r(context, 18), color: AppColors.theme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message, style: TextStyle(
                              fontSize: Responsive.sp(context, 13),
                              fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                              color: textColor)),
                            const SizedBox(height: 2),
                            Text(content, style: TextStyle(fontSize: Responsive.sp(context, 12), color: AppColors.theme.darkGreyColor),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('$postTitle · $timeStr',
                              style: TextStyle(fontSize: Responsive.sp(context, 11), color: AppColors.theme.darkGreyColor)),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: Responsive.r(context, 8), height: Responsive.r(context, 8),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
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
    );
  }

  Future<void> _markAllRead(String uid) async {
    final docs = await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    for (var doc in docs.docs) {
      await doc.reference.update({'read': true});
    }
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final l = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l.common_justNow;
    if (diff.inMinutes < 60) return l.common_minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.common_hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l.common_daysAgo(diff.inDays);
    return '${dt.month}/${dt.day}';
  }
}
