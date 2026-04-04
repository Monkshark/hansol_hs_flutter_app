import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 알림 목록 화면 (NotificationScreen)
///
/// - 댓글 및 답글 알림을 시간순으로 표시
/// - 알림 탭 시 해당 게시글 상세로 이동
/// - 개별 알림 읽음 처리 및 전체 읽음 기능
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.uid;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('알림')),
        body: const Center(child: Text('로그인이 필요합니다')),
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
        title: const Text('알림'),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _markAllRead(uid),
            child: Text('모두 읽음', style: TextStyle(fontSize: 13, color: AppColors.theme.primaryColor)),
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
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 40, color: AppColors.theme.darkGreyColor),
                  const SizedBox(height: 8),
                  Text('알림이 없습니다', style: TextStyle(color: AppColors.theme.darkGreyColor)),
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
              final timeStr = createdAt != null ? _formatTime(createdAt.toDate()) : '';

              final isAccount = type == 'account';
              final icon = type == 'comment'
                  ? Icons.chat_bubble_outline
                  : isAccount
                      ? Icons.person_outline
                      : Icons.reply;
              final message = type == 'comment'
                  ? '$senderName님이 댓글을 남겼습니다'
                  : isAccount
                      ? postTitle
                      : '$senderName님이 답글을 남겼습니다';

              return GestureDetector(
                onTap: () {
                  if (!isRead) docs[index].reference.update({'read': true});
                  if (!isAccount && postId.isNotEmpty) {
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
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.theme.primaryColor.withAlpha(isRead ? 15 : 30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 18, color: AppColors.theme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message, style: TextStyle(
                              fontSize: 13,
                              fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                              color: textColor)),
                            const SizedBox(height: 2),
                            Text(content, style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('$postTitle · $timeStr',
                              style: TextStyle(fontSize: 11, color: AppColors.theme.darkGreyColor)),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8, height: 8,
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

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }
}
