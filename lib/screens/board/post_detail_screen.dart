import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/widgets/error_view.dart';
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/analytics_service.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/local_database.dart';
import 'package:hansol_high_school/data/schedule_data.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/auth/login_screen.dart';
import 'package:hansol_high_school/screens/board/widgets/event_attach_card.dart';
import 'package:hansol_high_school/screens/board/widgets/poll_card.dart';
import 'package:hansol_high_school/screens/board/widgets/post_comment_item.dart';
import 'package:hansol_high_school/screens/board/widgets/post_image_gallery.dart';
import 'package:hansol_high_school/screens/board/widgets/vote_button.dart';
import 'package:hansol_high_school/screens/board/write_post_screen.dart';
import 'package:hansol_high_school/screens/chat/chat_utils.dart';
import 'package:hansol_high_school/data/board_categories.dart';
import 'package:hansol_high_school/data/post_repository.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({required this.postId, Key? key}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}


class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;
  bool _commentAnonymous = false;
  int _refreshTick = 0;
  String _prevCommentText = '';

  String? _replyToCommentId;
  String? _replyToName;

  final _repo = PostRepository.instance;

  DocumentReference<Map<String, dynamic>> get _postRef =>
      _repo.postRef(widget.postId);

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onCommentChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onCommentChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _onCommentChanged() {
    final text = _commentController.text;
    final prev = _prevCommentText;
    _prevCommentText = text;
    if (text.length >= prev.length) return;
    final mentionPattern = RegExp(r'@[\w가-힣]+');
    for (final m in mentionPattern.allMatches(prev)) {
      final cursorPos = _commentController.selection.baseOffset;
      if (cursorPos > m.start && cursorPos <= m.end && !text.contains(m.group(0)!)) {
        final newText = prev.substring(0, m.start) + prev.substring(m.end);
        _commentController.removeListener(_onCommentChanged);
        _commentController.text = newText;
        _commentController.selection = TextSelection.collapsed(offset: m.start);
        _prevCommentText = newText;
        _commentController.addListener(_onCommentChanged);
        return;
      }
    }
  }

  Future<void> _refresh() async {
    try {
      await _repo.refreshFromServer(widget.postId);
    } catch (e) {
      log('PostDetailScreen: refresh error: $e');
    }
    if (mounted) setState(() => _refreshTick++);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _postRef.snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              if (data == null) return const SizedBox.shrink();
              final isAuthor = AuthService.currentUser?.uid == data['authorUid'];

              return FutureBuilder<UserProfile?>(
                future: AuthService.getCachedProfile(),
                builder: (context, profileSnap) {
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
                            size: 22,
                            color: isBookmarked ? AppColors.theme.primaryColor : null,
                          ),
                          tooltip: AppLocalizations.of(context)!.post_bookmark,
                          onPressed: () => _toggleBookmark(isBookmarked),
                        ),
                      if (!isAuthor && data['isAnonymous'] != true)
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, size: 22),
                          tooltip: AppLocalizations.of(context)!.post_chat,
                          onPressed: () => startChat(context, data['authorUid'], data['authorName'] ?? ''),
                        ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 22),
                        onPressed: () => _showActionSheet(
                          context, data, isAuthor, isManager, isPinned,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _postRef.snapshots(),
              builder: (context, postSnapshot) {
                if (postSnapshot.hasError) {
                  return ErrorView(
                    message: AppLocalizations.of(context)!.error_loadFailed,
                    onRetry: () => setState(() {}),
                  );
                }
                if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
                  return const Center(child: CircularProgressIndicator());
                }

                final post = postSnapshot.data!.data()!;
                _currentPostAuthorUid = post['authorUid'] as String?;
                _anonymousMapping = Map<String, dynamic>.from(post['anonymousMapping'] ?? {});
                final title = post['title'] ?? '';
                final content = post['content'] ?? '';
                final isAnon = post['isAnonymous'] == true;
                final isManagerView = AuthService.cachedProfile?.isManager ?? false;
                final realName = post['authorRealName'] as String?;
                final rawAuthorName = (post['authorName'] ?? AppLocalizations.of(context)!.post_anonymous) as String;
                final authorName = (isAnon && isManagerView && realName != null)
                    ? '$rawAuthorName ($realName)'
                    : rawAuthorName;
                final category = post['category'] ?? '';
                final createdAt = post['createdAt'] as Timestamp?;
                final timeStr = createdAt != null
                    ? DateFormat(AppLocalizations.of(context)!.common_dateMdEHm, Localizations.localeOf(context).toString()).format(createdAt.toDate())
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

                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.theme.primaryColor,
                  child: ListView(
                  key: ValueKey('post_list_$_refreshTick'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _categoryColor(category).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(category,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _categoryColor(category))),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 8),
                    Text('$authorName · $timeStr',
                      style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor)),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? const Color(0xFF2A2D35) : const Color(0xFFE5E5EA)),
                    const SizedBox(height: 16),
                    Text(content, style: TextStyle(fontSize: 15, height: 1.7, color: textColor)),

                    if (post['imageUrls'] != null && (post['imageUrls'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      PostImageGallery(
                        imageUrls: (post['imageUrls'] as List).cast<String>(),
                        heroTagPrefix: 'post-${widget.postId}',
                      ),
                    ],

                    if (hasPoll) ...[
                      const SizedBox(height: 20),
                      PollCard(
                        options: pollOptions,
                        voters: pollVoters,
                        myVote: myVote as int?,
                        onVote: (index) => _vote(index),
                      ),
                    ],

                    if (hasEvent) ...[
                      const SizedBox(height: 20),
                      EventAttachCard(
                        eventDate: eventDate!,
                        eventContent: eventContent,
                        startTime: eventStartTime,
                        endTime: eventEndTime,
                        onAdd: () => _addEventToCalendar(eventDate, eventContent, eventStartTime, eventEndTime),
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
                          onTap: () => _toggleLike(hasLiked, hasDisliked),
                        ),
                        const SizedBox(width: 20),
                        VoteButton(
                          icon: Icons.thumb_down_outlined,
                          activeIcon: Icons.thumb_down,
                          count: dislikesCount,
                          isActive: hasDisliked,
                          activeColor: Colors.redAccent,
                          onTap: () => _toggleDislike(hasLiked, hasDisliked),
                        ),
                        if (AuthService.currentUser?.uid != post['authorUid']) ...[
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: _reportPost,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.theme.darkGreyColor.withAlpha(80)),
                              ),
                              child: Icon(Icons.flag_outlined, size: 20, color: AppColors.theme.darkGreyColor),
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
                          onPressed: post['isResolved'] == true ? null : _resolvePost,
                          icon: Icon(post['isResolved'] == true ? Icons.check_circle : Icons.check, size: 18),
                          label: Text(post['isResolved'] == true ? AppLocalizations.of(context)!.post_resolvedLabel : AppLocalizations.of(context)!.post_found),
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
                      stream: _postRef.collection('comments').orderBy('createdAt').snapshots(),
                      builder: (context, commentSnapshot) {
                        final comments = commentSnapshot.data?.docs ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.post_comments(comments.length),
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                            const SizedBox(height: 12),
                            if (comments.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(AppLocalizations.of(context)!.post_firstComment,
                                    style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor)),
                                ),
                              )
                            else
                              ..._buildThreadedComments(comments),
                          ],
                        );
                      },
                    ),
                  ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 0, 8, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2028) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF2A2D35) : const Color(0xFFE5E5EA))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyToName != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
                    child: Row(
                      children: [
                        Icon(Icons.reply, size: 14, color: AppColors.theme.primaryColor),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context)!.post_replyTo(_replyToName!),
                          style: TextStyle(fontSize: 12, color: AppColors.theme.primaryColor)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() { _replyToCommentId = null; _replyToName = null; }),
                          child: Icon(Icons.close, size: 16, color: AppColors.theme.darkGreyColor),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _commentAnonymous = !_commentAnonymous),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _commentAnonymous
                              ? AppColors.theme.primaryColor.withAlpha(20)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _commentAnonymous
                                ? AppColors.theme.primaryColor
                                : AppColors.theme.darkGreyColor,
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.post_anonymous,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: _commentAnonymous
                                ? AppColors.theme.primaryColor
                                : AppColors.theme.darkGreyColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: TextStyle(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          hintText: _replyToName != null ? '@$_replyToName' : AppLocalizations.of(context)!.post_commentPlaceholder,
                          hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _sending ? null : _submitComment,
                  icon: Icon(Icons.send, color: AppColors.theme.primaryColor),
                ),
              ],
            ),
            ],
          ),
          ),
        ],
      ),
    ),
    );
  }

  Future<bool?> _showConfirmSheet(String title, String content, String confirmLabel) {
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
          Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 14, color: AppColors.theme.darkGreyColor)),
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

  Future<void> _toggleBookmark(bool isCurrentlyBookmarked) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    await _repo.toggleBookmark(widget.postId, uid, isCurrentlyBookmarked);
  }

  void _showActionSheet(
    BuildContext context,
    Map<String, dynamic> data,
    bool isAuthor,
    bool isManager,
    bool isPinned,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = <_ActionItem>[];
    items.add(_ActionItem(Icons.share_outlined, AppLocalizations.of(context)!.post_share, () {
      final title = data['title'] ?? '';
      final deepLink = 'https://hansol-high-school-46fc9.web.app/post/${widget.postId}';
      Share.share('[한솔고] $title\n$deepLink');
    }));
    if (isAuthor) {
      items.add(_ActionItem(Icons.edit_outlined, AppLocalizations.of(context)!.post_edit, () => _editPost(data)));
      items.add(_ActionItem(Icons.delete_outline, AppLocalizations.of(context)!.post_delete, _deletePost, isDestructive: true));
    }
    if (!isAuthor && isManager)
      items.add(_ActionItem(Icons.delete_outline, AppLocalizations.of(context)!.post_deleteByAdmin, _deletePost, isDestructive: true));
    if (isManager && !isPinned)
      items.add(_ActionItem(Icons.push_pin_outlined, AppLocalizations.of(context)!.post_pinAsNotice, _pinPost));
    if (isManager && isPinned)
      items.add(_ActionItem(Icons.push_pin, AppLocalizations.of(context)!.post_unpinNotice, _unpinPost));
    if (!isAuthor) {
      items.add(_ActionItem(Icons.flag_outlined, AppLocalizations.of(context)!.post_report, _reportPost, isDestructive: true));
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
                  color: item.isDestructive ? Colors.redAccent : (isDark ? Colors.white70 : Colors.black87), size: 22),
                title: Text(item.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
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

  Future<void> _reportPost() async {
    if (!AuthService.isLoggedIn) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            Text(AppLocalizations.of(context)!.post_reportSelectReason, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: Theme.of(ctx).textTheme.bodyLarge?.color)),
            const SizedBox(height: 12),
            ...[
              AppLocalizations.of(context)!.post_reportReasonSwearing,
              AppLocalizations.of(context)!.post_reportReasonAdult,
              AppLocalizations.of(context)!.post_reportReasonSpam,
              AppLocalizations.of(context)!.post_reportReasonPrivacy,
              AppLocalizations.of(context)!.post_reportReasonOther,
            ].map((r) =>
              RadioListTile<String>(
                value: r, groupValue: selected,
                title: Text(r, style: TextStyle(fontSize: 14, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                activeColor: AppColors.theme.primaryColor,
                onChanged: (v) => setSheetState(() => selected = v),
                dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selected != null ? () => Navigator.pop(ctx, selected) : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text(AppLocalizations.of(context)!.post_reportButton),
              ),
            )),
          ])),
        ),
      ),
    );

    if (reason == null) return;

    final existingReport = await FirebaseFirestore.instance.collection('reports')
        .where('postId', isEqualTo: widget.postId)
        .where('reporterUid', isEqualTo: AuthService.currentUser!.uid)
        .limit(1).get();

    if (existingReport.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.post_reportAlreadyReported)),
        );
      }
      return;
    }

    await _repo.reportPost(
      postId: widget.postId,
      reporterUid: AuthService.currentUser!.uid,
      reason: reason,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.post_reportSuccess)),
      );
    }
  }

  Future<void> _toggleLike(bool hasLiked, bool hasDisliked) async {
    if (!AuthService.isLoggedIn) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    final uid = AuthService.currentUser!.uid;
    await _repo.toggleLike(widget.postId, uid, hasLiked: hasLiked, hasDisliked: hasDisliked);
  }

  Future<void> _toggleDislike(bool hasLiked, bool hasDisliked) async {
    if (!AuthService.isLoggedIn) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    final uid = AuthService.currentUser!.uid;
    await _repo.toggleDislike(widget.postId, uid, hasLiked: hasLiked, hasDisliked: hasDisliked);
  }

  Future<void> _vote(int optionIndex) async {
    if (!AuthService.isLoggedIn) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (result != true) return;
    }

    final uid = AuthService.currentUser!.uid;
    await _repo.votePoll(widget.postId, uid, optionIndex);
  }

  Future<void> _addEventToCalendar(DateTime date, String content, int startTime, int endTime) async {
    await GetIt.I<LocalDataBase>().insertSchedule(Schedule(
      startTime: startTime,
      endTime: endTime,
      content: content,
      date: date.toIso8601String(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.post_eventAdded(DateFormat('M/d').format(date)))),
      );
    }
  }

  Future<void> _submitComment() async {
    FocusScope.of(context).unfocus();
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (text.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.post_commentTooLong)),
      );
      return;
    }

    if (!AuthService.isLoggedIn) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (result != true) return;
    }

    final suspendDuration = await AuthService.getSuspendedDuration();
    if (suspendDuration != null) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        final formatted = BoardCategories.formatSuspendDuration(l, suspendDuration);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.board_accountSuspended}\n${l.board_suspendedRemaining(formatted)}')),
        );
      }
      return;
    }

    final approved = await AuthService.isApproved();
    if (!approved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.board_awaitingAdminApproval)),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastCommentTime = prefs.getInt('last_comment_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastCommentTime < 10000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.post_commentRateLimit)),
        );
      }
      return;
    }

    final profile = await AuthService.getUserProfile();
    if (profile == null) return;

    setState(() => _sending = true);
    final anonymous = _commentAnonymous;
    _commentController.clear();

    final l = AppLocalizations.of(context)!;
    String displayName = anonymous ? l.post_anonymous : profile.name;

    if (anonymous) {
      final myUid = AuthService.currentUser!.uid;
      displayName = await _repo.resolveAnonymousName(
        widget.postId,
        myUid,
        l.post_anonymousAuthor,
        (num) => l.post_anonymousNum(num),
      );
    }

    final mentionPattern = RegExp(r'@([\w가-힣]+)');
    final mentionNames = mentionPattern
        .allMatches(text)
        .map((m) => m.group(1))
        .whereType<String>()
        .toSet();
    final mentionedUids = <String>{};
    if (mentionNames.isNotEmpty) {
      final commentsSnap = await _repo.commentsRef(widget.postId).get();
      for (final doc in commentsSnap.docs) {
        final d = doc.data();
        final n = d['authorName']?.toString();
        final u = d['authorUid']?.toString();
        if (n != null && u != null && mentionNames.contains(n)) {
          mentionedUids.add(u);
        }
      }
      mentionedUids.remove(AuthService.currentUser!.uid);
    }

    final commentData = <String, dynamic>{
      'content': text,
      'authorUid': AuthService.currentUser!.uid,
      'authorName': displayName,
      'authorRealName': profile.displayName,
      'isAnonymous': anonymous,
      'createdAt': FieldValue.serverTimestamp(),
      if (mentionedUids.isNotEmpty) 'mentions': mentionedUids.toList(),
    };

    if (_replyToCommentId != null) {
      commentData['parentId'] = _replyToCommentId;
      commentData['replyTo'] = _replyToCommentId;
      commentData['replyToName'] = _replyToName;
    }
    await _repo.addComment(widget.postId, commentData);
    unawaited(AnalyticsService.logCommentCreate(
      postId: widget.postId,
      isReply: _replyToCommentId != null,
    ));

    final postSnap = await _repo.getPost(widget.postId);
    final postData = postSnap.data();
    if (postData != null) {
      final postAuthorUid = postData['authorUid'] as String?;
      final postTitle = postData['title'] as String? ?? '';
      final myUid = AuthService.currentUser!.uid;

      String? replyNotifiedUid;
      if (_replyToCommentId != null) {
        final origComment = await _repo.commentsRef(widget.postId).doc(_replyToCommentId).get();
        final origUid = origComment.data()?['authorUid'] as String?;
        if (origUid != null && origUid != myUid) {
          replyNotifiedUid = origUid;
          await _repo.sendNotification(
            targetUid: origUid, type: 'reply', postId: widget.postId,
            postTitle: postTitle, senderName: displayName, content: text,
          );
        }
      }

      if (postAuthorUid != null && postAuthorUid != myUid && postAuthorUid != replyNotifiedUid) {
        await _repo.sendNotification(
          targetUid: postAuthorUid, type: 'comment', postId: widget.postId,
          postTitle: postTitle, senderName: displayName, content: text,
        );
      }

      for (final mentionedUid in mentionedUids) {
        if (mentionedUid == postAuthorUid) continue;
        await _repo.sendNotification(
          targetUid: mentionedUid, type: 'mention', postId: widget.postId,
          postTitle: postTitle, senderName: displayName, content: text,
        );
      }
    }

    await prefs.setInt('last_comment_time', DateTime.now().millisecondsSinceEpoch);

    if (mounted) {
      setState(() {
        _sending = false;
        _replyToCommentId = null;
        _replyToName = null;
      });
    }
  }

  List<Widget> _buildThreadedComments(List<QueryDocumentSnapshot> comments) {
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
        widgets.add(_buildCommentWidget(child, indent: true));
        handled.add(child.id);
        addDescendants(child.id);
      }
    }

    for (var parent in parents) {
      widgets.add(_buildCommentWidget(parent, indent: false));
      handled.add(parent.id);
      addDescendants(parent.id);
    }

    for (var doc in comments) {
      if (handled.contains(doc.id)) continue;
      widgets.add(_buildCommentWidget(doc, indent: true));
      handled.add(doc.id);
      addDescendants(doc.id);
    }

    return widgets;
  }

  String? _currentPostAuthorUid;
  Map<String, dynamic> _anonymousMapping = {};

  Widget _buildCommentWidget(QueryDocumentSnapshot doc, {required bool indent}) {
    final String docId = doc.id;
    final c = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
    final isCommentAuthor = AuthService.currentUser?.uid == c['authorUid'];
    final canDelete = isCommentAuthor || (AuthService.cachedProfile?.isManager ?? false);
    final isPostAuthor = c['authorUid'] == _currentPostAuthorUid;

    if (c['isAnonymous'] == true && c['authorUid'] != null) {
      final uid = c['authorUid'] as String;
      if (uid == _currentPostAuthorUid) {
        c['authorName'] = AppLocalizations.of(context)!.post_anonymousAuthor;
      } else if (_anonymousMapping.containsKey(uid)) {
        c['authorName'] = AppLocalizations.of(context)!.post_anonymousNum(_anonymousMapping[uid]);
      }
    }
    final String resolvedName = (c['authorName'] ?? AppLocalizations.of(context)!.post_anonymous) as String;

    return Padding(
      padding: EdgeInsets.only(left: indent ? 32 : 0),
      child: PostCommentItem(
        key: ValueKey(docId),
        data: c,
        isAuthor: canDelete,
        isReply: indent,
        isPostAuthor: isPostAuthor,
        onDelete: () => _confirmDeleteComment(docId),
        onReply: () => _onReplyTap(docId, resolvedName),
      ),
    );
  }

  void _onReplyTap(String parentId, String parentName) {
    setState(() {
      _replyToCommentId = parentId;
      _replyToName = parentName;
    });
    final mentionPrefix = '@$parentName ';
    final current = _commentController.text;
    if (current.startsWith(mentionPrefix)) return;
    final existingMention = RegExp(r'^@\S+\s').firstMatch(current);
    final rest = existingMention != null
        ? current.substring(existingMention.end)
        : current;
    _commentController.text = '$mentionPrefix$rest';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }

  Future<void> _confirmDeleteComment(String commentId) async {
    final confirm = await _showConfirmSheet(AppLocalizations.of(context)!.post_confirmDeleteComment, AppLocalizations.of(context)!.post_confirmDeleteCommentMessage, AppLocalizations.of(context)!.common_delete);

    if (confirm == true) {
      await _repo.deleteComment(widget.postId, commentId);
    }
  }

  Future<void> _pinPost() async {
    try {
      await _repo.pinPost(widget.postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.post_pinSuccess)),
        );
      }
    } on StateError {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.post_pinMaxed)),
        );
      }
    }
  }

  Future<void> _unpinPost() async {
    await _repo.unpinPost(widget.postId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.post_unpinSuccess)),
      );
    }
  }

  void _editPost(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WritePostScreen(
          postId: widget.postId,
          initialTitle: data['title'],
          initialContent: data['content'],
          initialCategory: data['category'],
        ),
      ),
    );
  }

  Future<void> _deletePost() async {
    final confirm = await _showConfirmSheet(AppLocalizations.of(context)!.post_deleteConfirm, AppLocalizations.of(context)!.post_deleteConfirmMessage, AppLocalizations.of(context)!.common_delete);

    if (confirm == true) {
      final uid = AuthService.currentUser?.uid;
      final postSnap = await _repo.getPost(widget.postId);
      final postData = postSnap.data();
      if (postData != null && uid != null && uid != postData['authorUid']) {
        final profile = await AuthService.getCachedProfile();
        await _repo.logAdminAction({
          'action': 'delete_post',
          'adminUid': uid,
          'adminName': profile?.displayName ?? '',
          'postId': widget.postId,
          'postTitle': postData['title'] ?? '',
          'postAuthorUid': postData['authorUid'] ?? '',
          'postAuthorName': postData['authorName'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        });
      }

      await _repo.deletePost(widget.postId);
      if (mounted) Navigator.pop(context);
    }
  }

  Color _categoryColor(String category) => BoardCategories.color(category);

  Future<void> _resolvePost() async {
    await _repo.resolvePost(widget.postId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.post_resolvedMarked)),
      );
    }
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  _ActionItem(this.icon, this.label, this.onTap, {this.isDestructive = false});
}
