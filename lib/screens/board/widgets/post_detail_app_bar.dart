import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/widgets/post_action_sheet.dart';
import 'package:hansol_high_school/screens/chat/chat_utils.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';

class PostDetailAppBarActions extends StatelessWidget {
  final Stream<DocumentSnapshot<Map<String, dynamic>>> postStream;
  final String postId;
  final Future<void> Function(bool) onToggleBookmark;
  final void Function(Map<String, dynamic>) onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onUnpin;

  const PostDetailAppBarActions({
    super.key,
    required this.postStream,
    required this.postId,
    required this.onToggleBookmark,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: postStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        final data = snapshot.data?.data();
        if (data == null) return const SizedBox.shrink();
        final isAuthor = AuthService.currentUser?.uid == data['authorUid'];

        return FutureBuilder<UserProfile?>(
          future: AuthService.getCachedProfile(),
          builder: (context, profileSnap) {
            if (profileSnap.hasError) return const SizedBox.shrink();
            final isManager = profileSnap.data?.isManager ?? false;

            final isPinned = data['isPinned'] == true;

            final bookmarkedBy = List<String>.from(data['bookmarkedBy'] ?? []);
            final isBookmarked = AuthService.currentUser != null &&
                bookmarkedBy.contains(AuthService.currentUser!.uid);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (AuthService.isLoggedIn)
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: Responsive.r(context, 22),
                      color: isBookmarked ? AppColors.theme.primaryColor : null,
                    ),
                    tooltip: AppLocalizations.of(context)!.post_bookmark,
                    onPressed: () => onToggleBookmark(isBookmarked),
                  ),
                if (!isAuthor && data['isAnonymous'] != true)
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline, size: Responsive.r(context, 22)),
                    tooltip: AppLocalizations.of(context)!.post_chat,
                    onPressed: () => startChat(context, data['authorUid'], data['authorName'] ?? ''),
                  ),
                IconButton(
                  icon: Icon(Icons.more_vert, size: Responsive.r(context, 22)),
                  onPressed: () => showPostActionSheet(
                    context: context,
                    postId: postId,
                    data: data,
                    isAuthor: isAuthor,
                    isManager: isManager,
                    isPinned: isPinned,
                    onEdit: () => onEdit(data),
                    onDelete: onDelete,
                    onPin: onPin,
                    onUnpin: onUnpin,
                    onReport: () => showReportSheet(context: context, postId: postId),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
