import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/board_categories.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/widgets/event_attach_card.dart';
import 'package:hansol_high_school/screens/board/widgets/poll_card.dart';
import 'package:hansol_high_school/screens/board/widgets/post_comment_item.dart';
import 'package:hansol_high_school/screens/board/widgets/post_image_gallery.dart';
import 'package:hansol_high_school/screens/board/widgets/vote_button.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';
import 'package:hansol_high_school/widgets/error_view.dart';
import 'package:intl/intl.dart';

class PostDetailBody extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> post;
  final int refreshTick;
  final String? currentPostAuthorUid;
  final Map<String, dynamic> anonymousMapping;
  final Stream<QuerySnapshot> commentsStream;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int) onVote;
  final Future<void> Function(bool, bool) onToggleLike;
  final Future<void> Function(bool, bool) onToggleDislike;
  final VoidCallback onReport;
  final VoidCallback onResolve;
  final Future<void> Function(DateTime, String, int, int) onAddEvent;
  final void Function(String, String) onReplyTap;
  final Future<void> Function(String) onDeleteComment;

  const PostDetailBody({
    super.key,
    required this.postId,
    required this.post,
    required this.refreshTick,
    required this.currentPostAuthorUid,
    required this.anonymousMapping,
    required this.commentsStream,
    required this.onRefresh,
    required this.onVote,
    required this.onToggleLike,
    required this.onToggleDislike,
    required this.onReport,
    required this.onResolve,
    required this.onAddEvent,
    required this.onReplyTap,
    required this.onDeleteComment,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final l = AppLocalizations.of(context)!;

    final title = post['title'] ?? '';
    final content = post['content'] ?? '';
    final isAnon = post['isAnonymous'] == true;
    final isManagerView = AuthService.cachedProfile?.isManager ?? false;
    final realName = post['authorRealName'] as String?;
    final rawAuthorName = (post['authorName'] ?? l.post_anonymous) as String;
    final authorName = (isAnon && isManagerView && realName != null)
        ? '$rawAuthorName ($realName)'
        : rawAuthorName;
    final category = post['category'] ?? '';
    final createdAt = post['createdAt'] as Timestamp?;
    final timeStr = createdAt != null
        ? DateFormat(l.common_dateMdEHm, Localizations.localeOf(context).toString()).format(createdAt.toDate())
        : '';

    final hasEvent = post['eventDate'] != null;
    final eventDate = hasEvent ? DateTime.parse(post['eventDate']) : null;
    final eventContent = post['eventContent'] as String? ?? '';
    final eventStartTime = post['eventStartTime'] as int? ?? -1;
    final eventEndTime = post['eventEndTime'] as int? ?? -1;

    final rawLikes = post['likes'];
    final rawDislikes = post['dislikes'];
    final likes = rawLikes is Map<String, dynamic> ? rawLikes : <String, dynamic>{};
    final dislikes = rawDislikes is Map<String, dynamic> ? rawDislikes : <String, dynamic>{};
    final likesCount = rawLikes is int ? rawLikes : likes.length;
    final dislikesCount = rawDislikes is int ? rawDislikes : dislikes.length;
    final myUid = AuthService.currentUser?.uid;
    final hasLiked = myUid != null && likes.containsKey(myUid);
    final hasDisliked = myUid != null && dislikes.containsKey(myUid);

    final pollOptions = (post['pollOptions'] as List<dynamic>?)?.cast<String>();
    final hasPoll = pollOptions != null && pollOptions.isNotEmpty;
    final rawPollVoters = post['pollVoters'];
    final pollVoters = rawPollVoters is Map<String, dynamic> ? rawPollVoters : <String, dynamic>{};
    final myVote = AuthService.currentUser != null
        ? pollVoters[AuthService.currentUser!.uid]
        : null;

    final categoryColor = BoardCategories.color(category);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.theme.primaryColor,
      child: ListView(
        key: ValueKey('post_list_$refreshTick'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(category,
                style: TextStyle(fontSize: Responsive.sp(context, 12), fontWeight: FontWeight.w600, color: categoryColor)),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: Responsive.sp(context, 20), fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 8),
          Text('$authorName · $timeStr',
            style: TextStyle(fontSize: Responsive.sp(context, 13), color: AppColors.theme.darkGreyColor)),
          const SizedBox(height: 16),
          Divider(color: isDark ? const Color(0xFF2A2D35) : const Color(0xFFE5E5EA)),
          const SizedBox(height: 16),
          Text(content, style: TextStyle(fontSize: Responsive.sp(context, 15), height: 1.7, color: textColor)),

          if (post['imageUrls'] != null && (post['imageUrls'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            PostImageGallery(
              imageUrls: (post['imageUrls'] as List).cast<String>(),
              heroTagPrefix: 'post-$postId',
            ),
          ],

          if (hasPoll) ...[
            const SizedBox(height: 20),
            PollCard(
              options: pollOptions,
              voters: pollVoters,
              myVote: myVote as int?,
              onVote: (index) => onVote(index),
            ),
          ],

          if (hasEvent) ...[
            const SizedBox(height: 20),
            EventAttachCard(
              eventDate: eventDate!,
              eventContent: eventContent,
              startTime: eventStartTime,
              endTime: eventEndTime,
              onAdd: () => onAddEvent(eventDate, eventContent, eventStartTime, eventEndTime),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              VoteButton(
                icon: Icons.thumb_up_outlined,
                activeIcon: Icons.thumb_up,
                count: likesCount,
                isActive: hasLiked,
                activeColor: AppColors.theme.primaryColor,
                onTap: () => onToggleLike(hasLiked, hasDisliked),
              ),
              const SizedBox(width: 20),
              VoteButton(
                icon: Icons.thumb_down_outlined,
                activeIcon: Icons.thumb_down,
                count: dislikesCount,
                isActive: hasDisliked,
                activeColor: Colors.redAccent,
                onTap: () => onToggleDislike(hasLiked, hasDisliked),
              ),
              if (AuthService.currentUser?.uid != post['authorUid']) ...[
                const SizedBox(width: 20),
                Semantics(
                  button: true,
                  label: l.post_report,
                  child: GestureDetector(
                    onTap: onReport,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.theme.darkGreyColor.withAlpha(80)),
                      ),
                      child: Icon(Icons.flag_outlined, size: Responsive.r(context, 20), color: AppColors.theme.darkGreyColor),
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (category == BoardCategories.lostFound && AuthService.currentUser?.uid == post['authorUid']) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: post['isResolved'] == true ? null : onResolve,
                icon: Icon(post['isResolved'] == true ? Icons.check_circle : Icons.check, size: Responsive.r(context, 18)),
                label: Text(post['isResolved'] == true ? l.post_resolvedLabel : l.post_found),
                style: ElevatedButton.styleFrom(
                  backgroundColor: post['isResolved'] == true ? Colors.grey : const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          Divider(color: isDark ? const Color(0xFF2A2D35) : const Color(0xFFE5E5EA)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: commentsStream,
            builder: (context, commentSnapshot) {
              if (commentSnapshot.hasError) {
                return ErrorView(message: l.error_loadFailed);
              }
              final comments = commentSnapshot.data?.docs ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.post_comments(comments.length),
                    style: TextStyle(fontSize: Responsive.sp(context, 15), fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 12),
                  if (comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(l.post_firstComment,
                          style: TextStyle(fontSize: Responsive.sp(context, 13), color: AppColors.theme.darkGreyColor)),
                      ),
                    )
                  else
                    ..._buildThreadedComments(context, comments),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildThreadedComments(BuildContext context, List<QueryDocumentSnapshot> comments) {
    final parents = <QueryDocumentSnapshot>[];
    final childrenMap = <String, List<QueryDocumentSnapshot>>{};
    final byId = <String, QueryDocumentSnapshot>{};

    for (var doc in comments) {
      byId[doc.id] = doc;
      final data = doc.data() as Map<String, dynamic>;
      final parentRef = data['parentId'] as String? ?? data['replyTo'] as String?;
      if (parentRef == null) {
        parents.add(doc);
      } else {
        childrenMap.putIfAbsent(parentRef, () => []).add(doc);
      }
    }

    int getTs(QueryDocumentSnapshot d) {
      final data = d.data() as Map<String, dynamic>;
      final ts = data['createdAt'];
      if (ts is Timestamp) return ts.millisecondsSinceEpoch;
      return 0;
    }
    parents.sort((a, b) => getTs(a).compareTo(getTs(b)));
    childrenMap.forEach((_, list) => list.sort((a, b) => getTs(a).compareTo(getTs(b))));

    final widgets = <Widget>[];
    final handled = <String>{};

    void addDescendants(String parentId) {
      for (var child in childrenMap[parentId] ?? []) {
        if (handled.contains(child.id)) continue;
        widgets.add(_buildCommentWidget(context, child, indent: true));
        handled.add(child.id);
        addDescendants(child.id);
      }
    }

    for (var parent in parents) {
      widgets.add(_buildCommentWidget(context, parent, indent: false));
      handled.add(parent.id);
      addDescendants(parent.id);
    }

    for (var doc in comments) {
      if (handled.contains(doc.id)) continue;
      widgets.add(_buildCommentWidget(context, doc, indent: true));
      handled.add(doc.id);
      addDescendants(doc.id);
    }

    return widgets;
  }

  Widget _buildCommentWidget(BuildContext context, QueryDocumentSnapshot doc, {required bool indent}) {
    final String docId = doc.id;
    final c = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
    final isCommentAuthor = AuthService.currentUser?.uid == c['authorUid'];
    final canDelete = isCommentAuthor || (AuthService.cachedProfile?.isManager ?? false);
    final isPostAuthor = c['authorUid'] == currentPostAuthorUid;
    final l = AppLocalizations.of(context)!;

    if (c['isAnonymous'] == true && c['authorUid'] != null) {
      final uid = c['authorUid'] as String;
      if (uid == currentPostAuthorUid) {
        c['authorName'] = l.post_anonymousAuthor;
      } else if (anonymousMapping.containsKey(uid)) {
        c['authorName'] = l.post_anonymousNum(anonymousMapping[uid]);
      }
    }
    final String resolvedName = (c['authorName'] ?? l.post_anonymous) as String;

    return Padding(
      padding: EdgeInsets.only(left: indent ? 32 : 0),
      child: PostCommentItem(
        key: ValueKey(docId),
        data: c,
        isAuthor: canDelete,
        isReply: indent,
        isPostAuthor: isPostAuthor,
        onDelete: () => onDeleteComment(docId),
        onReply: () => onReplyTap(docId, resolvedName),
      ),
    );
  }
}
