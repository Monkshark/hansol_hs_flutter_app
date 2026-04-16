import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/post_repository.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/widgets/error_view.dart';
import 'package:intl/intl.dart';

class BookmarkedPostsScreen extends StatelessWidget {
  const BookmarkedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.uid;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: Text(AppLocalizations.of(context)!.bookmarks_title),
        centerTitle: true,
        elevation: 0,
      ),
      body: uid == null
          ? Center(child: Text(AppLocalizations.of(context)!.common_loginRequired))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: PostRepository.instance.bookmarkedPostsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorView(message: AppLocalizations.of(context)!.error_loadFailed);
                }
                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_border, size: 48,
                            color: AppColors.theme.darkGreyColor),
                        const SizedBox(height: 12),
                        Text(AppLocalizations.of(context)!.bookmarks_empty,
                            style: TextStyle(color: AppColors.theme.darkGreyColor)),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context)!.bookmarks_emptyHelper,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.theme.darkGreyColor)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                      16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final title = data['title'] ?? '';
                    final category = data['category'] ?? '';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final timeStr = createdAt != null
                        ? DateFormat('M/d').format(createdAt.toDate())
                        : '';

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PostDetailScreen(postId: docs[index].id),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E2028)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bookmark,
                                size: 20,
                                color: AppColors.theme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (category.isNotEmpty)
                                    Text(category,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.theme.primaryColor,
                                            fontWeight: FontWeight.w600)),
                                  Text(title,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: textColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Text(timeStr,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.theme.darkGreyColor)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
