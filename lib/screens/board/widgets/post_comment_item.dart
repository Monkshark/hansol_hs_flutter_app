import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';

/// 게시글 댓글 1개
///
/// - `data`: Firestore 댓글 doc 데이터
/// - `isAuthor`: 현재 사용자가 작성자인지 (삭제 버튼 표시)
/// - `isReply`: 대댓글 여부 (들여쓰기/배경)
/// - `isPostAuthor`: 게시글 작성자가 단 댓글인지 (글쓴이 배지)
class PostCommentItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isAuthor;
  final bool isReply;
  final bool isPostAuthor;
  final VoidCallback onDelete;
  final VoidCallback onReply;

  const PostCommentItem({
    super.key,
    required this.data,
    required this.isAuthor,
    this.isReply = false,
    this.isPostAuthor = false,
    required this.onDelete,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isAnon = data['isAnonymous'] == true;
    final isManagerView = AuthService.cachedProfile?.isManager ?? false;
    final realName = data['authorRealName'] as String?;
    final name = (isAnon && isManagerView && realName != null)
        ? '익명 ($realName)'
        : (data['authorName'] ?? '익명');
    final content = data['content'] ?? '';
    final replyToName = data['replyToName'] as String?;
    final createdAt = data['createdAt'] as Timestamp?;
    final timeStr = createdAt != null ? _formatTime(createdAt.toDate()) : '';

    return Padding(
      padding: EdgeInsets.only(bottom: isReply ? 6 : 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPostAuthor
              ? (isDark ? const Color(0xFF1E2840) : const Color(0xFFEBF0FF))
              : (isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(12),
          border: isReply ? Border(
            left: BorderSide(color: AppColors.theme.primaryColor.withAlpha(100), width: 2),
          ) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                if (isPostAuthor) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.theme.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('글쓴이', style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.theme.primaryColor)),
                  ),
                ],
                const SizedBox(width: 8),
                Text(timeStr, style: TextStyle(fontSize: 11, color: AppColors.theme.darkGreyColor)),
                const Spacer(),
                GestureDetector(
                  onTap: onReply,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.reply, size: 16, color: AppColors.theme.darkGreyColor),
                  ),
                ),
                if (isAuthor)
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.close, size: 16, color: AppColors.theme.darkGreyColor),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (replyToName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('@$replyToName', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.theme.primaryColor)),
              ),
            Text(content, style: TextStyle(fontSize: 14, color: textColor, height: 1.4)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('M/d').format(dt);
  }
}
