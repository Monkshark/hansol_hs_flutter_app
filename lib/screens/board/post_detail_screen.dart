import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/local_database.dart';
import 'package:hansol_high_school/data/schedule_data.dart';
import 'package:hansol_high_school/screens/auth/login_screen.dart';
import 'package:hansol_high_school/screens/board/write_post_screen.dart';
import 'package:hansol_high_school/screens/chat/chat_utils.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 글 상세 화면 (PostDetailScreen)
///
/// - 게시글 본문, 이미지, 투표 항목을 표시
/// - 추천/비추천 기능 및 일정 공유(내 캘린더 추가) 지원
/// - 댓글 및 대댓글 작성, 익명 댓글 옵션 제공
/// - 부적절한 게시글/댓글 신고 기능
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

  String? _replyToCommentId;
  String? _replyToName;

  DocumentReference<Map<String, dynamic>> get _postRef =>
      FirebaseFirestore.instance.collection('posts').doc(widget.postId);

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
                          tooltip: '저장',
                          onPressed: () => _toggleBookmark(isBookmarked),
                        ),
                      if (!isAuthor && data['isAnonymous'] != true)
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, size: 22),
                          tooltip: '채팅',
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
                final authorName = (isAnon && isManagerView && realName != null)
                    ? '익명 ($realName)'
                    : (post['authorName'] ?? '익명');
                final category = post['category'] ?? '';
                final createdAt = post['createdAt'] as Timestamp?;
                final timeStr = createdAt != null
                    ? DateFormat('M월 d일 (E) HH:mm', 'ko_KR').format(createdAt.toDate())
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

                return ListView(
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
                      ...(post['imageUrls'] as List).map((url) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => _showFullImage(context, url as String),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: url as String,
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              placeholder: (context, url) => Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      )),
                    ],

                    if (hasPoll) ...[
                      const SizedBox(height: 20),
                      _PollCard(
                        options: pollOptions,
                        voters: pollVoters,
                        myVote: myVote as int?,
                        onVote: (index) => _vote(index),
                      ),
                    ],

                    if (hasEvent) ...[
                      const SizedBox(height: 20),
                      _EventAttachCard(
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
                        _VoteButton(
                          icon: Icons.thumb_up_outlined,
                          activeIcon: Icons.thumb_up,
                          count: likesCount,
                          isActive: hasLiked,
                          activeColor: AppColors.theme.primaryColor,
                          onTap: () => _toggleLike(hasLiked, hasDisliked),
                        ),
                        const SizedBox(width: 20),
                        _VoteButton(
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

                    if (category == '분실물' && AuthService.currentUser?.uid == post['authorUid']) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: post['isResolved'] == true ? null : _resolvePost,
                          icon: Icon(post['isResolved'] == true ? Icons.check_circle : Icons.check, size: 18),
                          label: Text(post['isResolved'] == true ? '해결됨' : '찾았어요'),
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
                            Text('댓글 ${comments.length}',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                            const SizedBox(height: 12),
                            if (comments.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text('첫 댓글을 남겨보세요',
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
                        Text('$_replyToName에게 답글',
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
                        child: Text('익명',
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
                          hintText: _replyToName != null ? '@$_replyToName' : '댓글을 입력하세요',
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
              child: Text('취소', style: TextStyle(color: AppColors.theme.darkGreyColor)),
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

  void _showFullImage(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 48)),
            ),
          ),
        ),
      ),
    ));
  }


  Future<void> _toggleBookmark(bool isCurrentlyBookmarked) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    await _postRef.update({
      'bookmarkedBy': isCurrentlyBookmarked
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
    });
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
    if (isAuthor) {
      items.add(_ActionItem(Icons.edit_outlined, '수정', () => _editPost(data)));
      items.add(_ActionItem(Icons.delete_outline, '삭제', _deletePost, isDestructive: true));
    }
    if (!isAuthor && isManager)
      items.add(_ActionItem(Icons.delete_outline, '삭제 (관리자)', _deletePost, isDestructive: true));
    if (isManager && !isPinned)
      items.add(_ActionItem(Icons.push_pin_outlined, '공지 등록', _pinPost));
    if (isManager && isPinned)
      items.add(_ActionItem(Icons.push_pin, '공지 해제', _unpinPost));
    if (!isAuthor) {
      items.add(_ActionItem(Icons.flag_outlined, '신고', _reportPost, isDestructive: true));
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
            Text('신고 사유 선택', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: Theme.of(ctx).textTheme.bodyLarge?.color)),
            const SizedBox(height: 12),
            ...['욕설/비방', '음란물', '광고/스팸', '개인정보 노출', '기타'].map((r) =>
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
                child: const Text('신고'),
              ),
            )),
          ])),
        ),
      ),
    );

    if (reason == null) return;

    final existingReport = await FirebaseFirestore.instance
        .collection('reports')
        .where('postId', isEqualTo: widget.postId)
        .where('reporterUid', isEqualTo: AuthService.currentUser!.uid)
        .limit(1)
        .get();

    if (existingReport.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 신고한 게시글입니다')),
        );
      }
      return;
    }

    await FirebaseFirestore.instance.collection('reports').add({
      'postId': widget.postId,
      'reporterUid': AuthService.currentUser!.uid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고가 접수되었습니다')),
      );
    }
  }

  Future<void> _ensureLikesMap() async {
    final snap = await _postRef.get();
    final data = snap.data();
    if (data == null) return;
    final updates = <String, dynamic>{};
    // int(더미)이면 Map으로 변환하되 값은 유지하지 않음 (첫 투표 시 리셋 불가피)
    // null이면 빈 Map으로 초기화
    if (data['likes'] == null) updates['likes'] = {};
    if (data['dislikes'] == null) updates['dislikes'] = {};
    if (data['likes'] is int) updates['likes'] = {};
    if (data['dislikes'] is int) updates['dislikes'] = {};
    if (updates.isNotEmpty) await _postRef.update(updates);
  }

  Future<void> _toggleLike(bool hasLiked, bool hasDisliked) async {
    if (!AuthService.isLoggedIn) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    await _ensureLikesMap();
    final uid = AuthService.currentUser!.uid;
    if (hasLiked) {
      await _postRef.update({'likes.$uid': FieldValue.delete()});
    } else {
      final updates = <String, dynamic>{'likes.$uid': true};
      if (hasDisliked) updates['dislikes.$uid'] = FieldValue.delete();
      await _postRef.update(updates);
    }
  }

  Future<void> _toggleDislike(bool hasLiked, bool hasDisliked) async {
    if (!AuthService.isLoggedIn) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    await _ensureLikesMap();
    final uid = AuthService.currentUser!.uid;
    if (hasDisliked) {
      await _postRef.update({'dislikes.$uid': FieldValue.delete()});
    } else {
      final updates = <String, dynamic>{'dislikes.$uid': true};
      if (hasLiked) updates['likes.$uid'] = FieldValue.delete();
      await _postRef.update(updates);
    }
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
    await _postRef.update({'pollVoters.$uid': optionIndex});
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
        SnackBar(content: Text('${DateFormat('M/d').format(date)} 일정에 추가되었습니다')),
      );
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (text.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글은 1000자 이내로 입력하세요')),
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

    final suspendMsg = await AuthService.getSuspendedMessage();
    if (suspendMsg != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('계정 정지 상태입니다\n남은 기간: $suspendMsg')),
        );
      }
      return;
    }

    final approved = await AuthService.isApproved();
    if (!approved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('관리자 승인 대기 중입니다')),
        );
      }
      return;
    }

    // Rate limiting: 10 seconds between comments
    final prefs = await SharedPreferences.getInstance();
    final lastCommentTime = prefs.getInt('last_comment_time') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastCommentTime < 10000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글은 10초에 한 번만 작성할 수 있습니다')),
        );
      }
      return;
    }

    final profile = await AuthService.getUserProfile();
    if (profile == null) return;

    setState(() => _sending = true);
    final anonymous = _commentAnonymous;
    _commentController.clear();

    String displayName = anonymous ? '익명' : profile.displayName;

    if (anonymous) {
      final myUid = AuthService.currentUser!.uid;

      // Check if post author
      final postSnap = await _postRef.get();
      final postAuthorUid = postSnap.data()?['authorUid'];

      if (myUid == postAuthorUid) {
        displayName = '익명(글쓴이)';
      } else {
        // Use transaction for atomic anonymous number assignment
        displayName = await FirebaseFirestore.instance.runTransaction<String>((transaction) async {
          final postDoc = await transaction.get(_postRef);
          final data = postDoc.data() ?? {};
          final mapping = Map<String, dynamic>.from(data['anonymousMapping'] ?? {});
          final count = (data['anonymousCount'] as int?) ?? 0;

          if (mapping.containsKey(myUid)) {
            return '익명${mapping[myUid]}';
          } else {
            final newNum = count + 1;
            mapping[myUid] = newNum;
            transaction.update(_postRef, {
              'anonymousMapping': mapping,
              'anonymousCount': newNum,
            });
            return '익명$newNum';
          }
        });
      }
    }

    final commentData = <String, dynamic>{
      'content': text,
      'authorUid': AuthService.currentUser!.uid,
      'authorName': displayName,
      'authorRealName': profile.displayName,
      'isAnonymous': anonymous,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (_replyToCommentId != null) {
      commentData['parentId'] = _replyToCommentId;
      commentData['replyTo'] = _replyToCommentId;
      commentData['replyToName'] = _replyToName;
    }

    await _postRef.collection('comments').add(commentData);
    await _postRef.update({'commentCount': FieldValue.increment(1)});

    final postSnap = await _postRef.get();
    final postData = postSnap.data();
    if (postData != null) {
      final postAuthorUid = postData['authorUid'] as String?;
      final postTitle = postData['title'] as String? ?? '';
      final myUid = AuthService.currentUser!.uid;

      if (_replyToCommentId != null) {
        final origComment = await _postRef.collection('comments').doc(_replyToCommentId).get();
        final origUid = origComment.data()?['authorUid'] as String?;
        if (origUid != null && origUid != myUid) {
          await FirebaseFirestore.instance
              .collection('users').doc(origUid).collection('notifications').add({
            'type': 'reply',
            'postId': widget.postId,
            'postTitle': postTitle,
            'senderName': displayName,
            'content': text,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (postAuthorUid != null && postAuthorUid != myUid) {
        await FirebaseFirestore.instance
            .collection('users').doc(postAuthorUid).collection('notifications').add({
          'type': 'comment',
          'postId': widget.postId,
          'postTitle': postTitle,
          'senderName': displayName,
          'content': text,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Save last comment time for rate limiting
    await prefs.setInt('last_comment_time', DateTime.now().millisecondsSinceEpoch);

    if (mounted) setState(() {
      _sending = false;
      _replyToCommentId = null;
      _replyToName = null;
    });
  }

  List<Widget> _buildThreadedComments(List<QueryDocumentSnapshot> comments) {
    final parents = <QueryDocumentSnapshot>[];
    final childrenMap = <String, List<QueryDocumentSnapshot>>{};

    for (var doc in comments) {
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

    for (var parent in parents) {
      widgets.add(_buildCommentWidget(parent, indent: false));
      handled.add(parent.id);
      for (var child in childrenMap[parent.id] ?? []) {
        widgets.add(_buildCommentWidget(child, indent: true));
        handled.add(child.id);
      }
    }

    // 부모가 삭제된 고아 대댓글
    for (var doc in comments) {
      if (!handled.contains(doc.id)) {
        widgets.add(_buildCommentWidget(doc, indent: true));
      }
    }

    return widgets;
  }

  String? _currentPostAuthorUid;
  Map<String, dynamic> _anonymousMapping = {};

  Widget _buildCommentWidget(QueryDocumentSnapshot doc, {required bool indent}) {
    final c = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
    final isCommentAuthor = AuthService.currentUser?.uid == c['authorUid'];
    final canDelete = isCommentAuthor || (AuthService.cachedProfile?.isManager ?? false);
    final isPostAuthor = c['authorUid'] == _currentPostAuthorUid;

    if (c['isAnonymous'] == true && c['authorUid'] != null) {
      final uid = c['authorUid'] as String;
      if (uid == _currentPostAuthorUid) {
        c['authorName'] = '익명(글쓴이)';
      } else if (_anonymousMapping.containsKey(uid)) {
        c['authorName'] = '익명${_anonymousMapping[uid]}';
      }
    }

    return Padding(
      padding: EdgeInsets.only(left: indent ? 32 : 0),
      child: _CommentItem(
        key: ValueKey(doc.id),
        data: c,
        isAuthor: canDelete,
        isReply: indent,
        isPostAuthor: isPostAuthor,
        onDelete: () => _confirmDeleteComment(doc.id),
        onReply: () {
          setState(() {
            _replyToCommentId = doc.id;
            _replyToName = c['authorName'] ?? '익명';
          });
        },
      ),
    );
  }

  Future<void> _confirmDeleteComment(String commentId) async {
    final confirm = await _showConfirmSheet('댓글 삭제', '댓글을 삭제하시겠습니까?', '삭제');

    if (confirm == true) {
      await _postRef.collection('comments').doc(commentId).delete();
      await _postRef.update({'commentCount': FieldValue.increment(-1)});
    }
  }

  Future<void> _pinPost() async {
    final pinnedSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('isPinned', isEqualTo: true)
        .get();

    if (pinnedSnapshot.docs.length >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공지는 최대 3개까지 가능합니다')),
        );
      }
      return;
    }

    await _postRef.update({
      'isPinned': true,
      'pinnedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공지로 등록되었습니다')),
      );
    }
  }

  Future<void> _unpinPost() async {
    await _postRef.update({
      'isPinned': false,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공지가 해제되었습니다')),
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
    final confirm = await _showConfirmSheet('게시글 삭제', '정말 삭제하시겠습니까?', '삭제');

    if (confirm == true) {
      // 관리자 삭제 로그
      final uid = AuthService.currentUser?.uid;
      final postSnap = await _postRef.get();
      final postData = postSnap.data();
      if (postData != null && uid != null && uid != postData['authorUid']) {
        final profile = await AuthService.getCachedProfile();
        await FirebaseFirestore.instance.collection('admin_logs').add({
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

      final comments = await _postRef.collection('comments').get();
      for (var doc in comments.docs) {
        await doc.reference.delete();
      }
      await _postRef.delete();
      if (mounted) Navigator.pop(context);
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case '자유': return AppColors.theme.primaryColor;
      case '질문': return AppColors.theme.secondaryColor;
      case '정보공유': return AppColors.theme.tertiaryColor;
      case '분실물': return const Color(0xFFFF5722);
      case '학생회': return const Color(0xFF4CAF50);
      case '동아리': return const Color(0xFF9C27B0);
      default: return AppColors.theme.darkGreyColor;
    }
  }

  Future<void> _resolvePost() async {
    await _postRef.update({'isResolved': true});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('해결됨으로 표시되었습니다')),
      );
    }
  }
}

class _EventAttachCard extends StatelessWidget {
  final DateTime eventDate;
  final String eventContent;
  final int startTime;
  final int endTime;
  final VoidCallback onAdd;

  const _EventAttachCard({
    required this.eventDate,
    required this.eventContent,
    required this.startTime,
    required this.endTime,
    required this.onAdd,
  });

  String _formatTime(int minutes) {
    if (minutes < 0) return '';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h < 12 ? '오전' : '오후';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $hour:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTime = startTime >= 0 && endTime >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252830) : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.theme.tertiaryColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, size: 18, color: AppColors.theme.tertiaryColor),
              const SizedBox(width: 6),
              Text('일정 공유', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.theme.tertiaryColor)),
            ],
          ),
          const SizedBox(height: 10),
          Text(eventContent, style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 4),
          Text(
            DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(eventDate) +
                (hasTime ? '  ${_formatTime(startTime)} - ${_formatTime(endTime)}' : ''),
            style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('내 일정에 추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.theme.tertiaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.activeIcon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : AppColors.theme.darkGreyColor.withAlpha(80),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive ? activeColor : AppColors.theme.darkGreyColor,
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : AppColors.theme.darkGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final List<String> options;
  final Map<String, dynamic> voters;
  final int? myVote;
  final Function(int) onVote;

  const _PollCard({
    required this.options,
    required this.voters,
    required this.myVote,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final totalVotes = voters.length;
    final hasVoted = myVote != null;

    final voteCounts = List.filled(options.length, 0);
    for (var v in voters.values) {
      final idx = v as int;
      if (idx >= 0 && idx < options.length) voteCounts[idx]++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252830) : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.theme.secondaryColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll, size: 18, color: AppColors.theme.secondaryColor),
              const SizedBox(width: 6),
              Text('투표', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.theme.secondaryColor)),
              const Spacer(),
              Text('$totalVotes명 참여', style: TextStyle(
                fontSize: 12, color: AppColors.theme.darkGreyColor)),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(options.length, (i) {
            final count = voteCounts[i];
            final ratio = totalVotes > 0 ? count / totalVotes : 0.0;
            final isMyChoice = myVote == i;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: hasVoted ? null : () => onVote(i),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isMyChoice
                          ? AppColors.theme.secondaryColor
                          : (isDark ? const Color(0xFF3A3D45) : const Color(0xFFE0E0E0)),
                      width: isMyChoice ? 1.5 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (hasVoted)
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: isMyChoice
                                  ? AppColors.theme.secondaryColor.withAlpha(30)
                                  : AppColors.theme.darkGreyColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            if (!hasVoted)
                              Container(
                                width: 18, height: 18,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.theme.darkGreyColor),
                                ),
                              )
                            else if (isMyChoice)
                              Container(
                                width: 18, height: 18,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.theme.secondaryColor,
                                ),
                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                            Expanded(
                              child: Text(options[i], style: TextStyle(
                                fontSize: 14,
                                fontWeight: isMyChoice ? FontWeight.w600 : FontWeight.w400,
                                color: textColor,
                              )),
                            ),
                            if (hasVoted)
                              Text('${(ratio * 100).round()}%', style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isMyChoice ? AppColors.theme.secondaryColor : AppColors.theme.darkGreyColor,
                              )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isAuthor;
  final bool isReply;
  final bool isPostAuthor;
  final VoidCallback onDelete;
  final VoidCallback onReply;

  const _CommentItem({super.key, required this.data, required this.isAuthor, this.isReply = false, this.isPostAuthor = false, required this.onDelete, required this.onReply});

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

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  _ActionItem(this.icon, this.label, this.onTap, {this.isDestructive = false});
}
