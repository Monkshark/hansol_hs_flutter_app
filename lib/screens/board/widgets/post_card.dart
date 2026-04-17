import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/board_categories.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class PostCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onTap;

  const PostCard({required this.doc, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final data = doc.data();

    final title = data['title'] ?? '';
    final content = data['content'] ?? '';
    final isAnon = data['isAnonymous'] == true;
    final isManagerView = AuthService.cachedProfile?.isManager ?? false;
    final realName = data['authorRealName'] as String?;
    final rawAuthorName = (data['authorName'] ?? AppLocalizations.of(context)!.post_anonymous) as String;
    final authorName = (isAnon && isManagerView && realName != null)
        ? '$rawAuthorName ($realName)'
        : rawAuthorName;
    final category = data['category'] ?? '';
    final commentCount = data['commentCount'] ?? 0;
    final rawLikes = data['likes'];
    final rawDislikes = data['dislikes'];
    final likeCount = data['likeCount'] is int
        ? data['likeCount'] as int
        : (rawLikes is int ? rawLikes : (rawLikes is Map ? rawLikes.length : 0));
    final dislikeCount = data['dislikeCount'] is int
        ? data['dislikeCount'] as int
        : (rawDislikes is int ? rawDislikes : (rawDislikes is Map ? rawDislikes.length : 0));
    final imageUrls = (data['imageUrls'] is List)
        ? (data['imageUrls'] as List).cast<String>()
        : const <String>[];
    final hasImages = imageUrls.isNotEmpty;
    final firstImage = hasImages ? imageUrls.first : null;
    final hasPoll = data['pollOptions'] != null && (data['pollOptions'] as List).isNotEmpty;
    final createdAt = data['createdAt'] as Timestamp?;
    final timeStr = createdAt != null ? _formatTime(context, createdAt.toDate()) : '';

    return RepaintBoundary(
      child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2028) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (data['isPinned'] == true)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.push_pin, size: 14, color: Colors.red),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: BoardCategories.color(category).withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(BoardCategories.localizedName(AppLocalizations.of(context)!, category),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: BoardCategories.color(category))),
                ),
                if (data['isResolved'] == true && category == BoardCategories.lostFound)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(AppLocalizations.of(context)!.post_resolved,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
                    ),
                  ),
                const Spacer(),
                if (hasImages)
                  Padding(padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.image, size: 14, color: AppColors.theme.darkGreyColor)),
                if (hasPoll)
                  Padding(padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.poll, size: 14, color: AppColors.theme.darkGreyColor)),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.theme.darkGreyColor),
                  const SizedBox(width: 3),
                  Text('$commentCount', style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor)),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (content.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(content, style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor, height: 1.3),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                if (firstImage != null) ...[
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.136,
                      height: MediaQuery.of(context).size.width * 0.136,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: firstImage,
                            fit: BoxFit.cover,
                            memCacheWidth: 400,
                            memCacheHeight: 400,
                            placeholder: (_, __) => Container(
                              color: isDark ? const Color(0xFF252830) : const Color(0xFFEAEAEA),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: isDark ? const Color(0xFF252830) : const Color(0xFFEAEAEA),
                              child: const Icon(Icons.broken_image, size: 18, color: Colors.grey),
                            ),
                          ),
                          if (imageUrls.length > 1)
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('+${imageUrls.length - 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$authorName · $timeStr',
                  style: TextStyle(fontSize: 11, color: AppColors.theme.darkGreyColor)),
                const Spacer(),
                if (likeCount > 0) ...[
                  Icon(Icons.thumb_up, size: 12, color: AppColors.theme.primaryColor),
                  const SizedBox(width: 2),
                  Text('$likeCount', style: TextStyle(fontSize: 11, color: AppColors.theme.primaryColor)),
                ],
                if (dislikeCount > 0) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.thumb_down, size: 12, color: Colors.redAccent),
                  const SizedBox(width: 2),
                  Text('$dislikeCount', style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                ],
              ],
            ),
          ],
        ),
      ),
    ));
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final l = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l.common_justNow;
    if (diff.inMinutes < 60) return l.common_minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.common_hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l.common_daysAgo(diff.inDays);
    return DateFormat('M/d').format(dt);
  }
}
