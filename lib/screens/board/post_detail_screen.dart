import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/widgets/error_snackbar.dart';
import 'package:hansol_high_school/widgets/error_view.dart';
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/analytics_service.dart';
import 'package:hansol_high_school/data/input_sanitizer.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/local_database.dart';
import 'package:hansol_high_school/data/schedule_data.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/auth/login_screen.dart';
import 'package:hansol_high_school/screens/board/widgets/comment_input_bar.dart';
import 'package:hansol_high_school/screens/board/widgets/post_action_sheet.dart';
import 'package:hansol_high_school/screens/board/widgets/post_detail_app_bar.dart';
import 'package:hansol_high_school/screens/board/widgets/post_detail_body.dart';
import 'package:hansol_high_school/screens/board/write_post_screen.dart';
import 'package:hansol_high_school/data/board_categories.dart';
import 'package:hansol_high_school/data/post_repository.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({required this.postId, super.key});

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
          PostDetailAppBarActions(
            postStream: _postRef.snapshots(),
            postId: widget.postId,
            onToggleBookmark: _toggleBookmark,
            onEdit: _editPost,
            onDelete: _deletePost,
            onPin: _pinPost,
            onUnpin: _unpinPost,
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

                return PostDetailBody(
                  postId: widget.postId,
                  post: post,
                  refreshTick: _refreshTick,
                  currentPostAuthorUid: _currentPostAuthorUid,
                  anonymousMapping: _anonymousMapping,
                  commentsStream: _postRef.collection('comments').orderBy('createdAt').snapshots(),
                  onRefresh: _refresh,
                  onVote: _vote,
                  onToggleLike: _toggleLike,
                  onToggleDislike: _toggleDislike,
                  onReport: () => showReportSheet(context: context, postId: widget.postId),
                  onResolve: _resolvePost,
                  onAddEvent: _addEventToCalendar,
                  onReplyTap: _onReplyTap,
                  onDeleteComment: _confirmDeleteComment,
                );
              },
            ),
          ),
          CommentInputBar(
            controller: _commentController,
            sending: _sending,
            commentAnonymous: _commentAnonymous,
            replyToName: _replyToName,
            onToggleAnonymous: () => setState(() => _commentAnonymous = !_commentAnonymous),
            onCancelReply: () => setState(() { _replyToCommentId = null; _replyToName = null; }),
            onSubmit: _submitComment,
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _toggleBookmark(bool isCurrentlyBookmarked) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    try {
      await _repo.toggleBookmark(widget.postId, uid, isCurrentlyBookmarked);
    } catch (e) {
      log('PostDetailScreen: toggleBookmark error: $e');
      if (mounted) showErrorSnackbar(context, e);
    }
  }

  Future<void> _toggleLike(bool hasLiked, bool hasDisliked) async {
    if (!AuthService.isLoggedIn) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    try {
      final uid = AuthService.currentUser!.uid;
      await _repo.toggleLike(widget.postId, uid, hasLiked: hasLiked, hasDisliked: hasDisliked);
    } catch (e) {
      log('PostDetailScreen: toggleLike error: $e');
      if (mounted) showErrorSnackbar(context, e);
    }
  }

  Future<void> _toggleDislike(bool hasLiked, bool hasDisliked) async {
    if (!AuthService.isLoggedIn) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    try {
      final uid = AuthService.currentUser!.uid;
      await _repo.toggleDislike(widget.postId, uid, hasLiked: hasLiked, hasDisliked: hasDisliked);
    } catch (e) {
      log('PostDetailScreen: toggleDislike error: $e');
      if (mounted) showErrorSnackbar(context, e);
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

    try {
      final uid = AuthService.currentUser!.uid;
      await _repo.votePoll(widget.postId, uid, optionIndex);
    } catch (e) {
      log('PostDetailScreen: vote error: $e');
      if (mounted) showErrorSnackbar(context, e);
    }
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
    final text = InputSanitizer.sanitize(_commentController.text.trim());
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
    if (!mounted) return;

    setState(() => _sending = true);
    final anonymous = _commentAnonymous;
    _commentController.clear();

    try {
      final l = AppLocalizations.of(context)!;
      String displayName = anonymous ? l.post_anonymous : profile.name;

      if (anonymous) {
        final myUid = AuthService.currentUser!.uid;
        displayName = await _repo.resolveAnonymousName(
          widget.postId,
          myUid,
          l.post_anonymousAuthor,
          (value) => l.post_anonymousNum(value),
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
    } catch (e) {
      log('PostDetailScreen: submitComment error: $e');
      if (mounted) showErrorSnackbar(context, e);
    }

    if (mounted) {
      setState(() {
        _sending = false;
        _replyToCommentId = null;
        _replyToName = null;
      });
    }
  }

  String? _currentPostAuthorUid;
  Map<String, dynamic> _anonymousMapping = {};

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
    final confirm = await showConfirmSheet(context, title: AppLocalizations.of(context)!.post_confirmDeleteComment, content: AppLocalizations.of(context)!.post_confirmDeleteCommentMessage, confirmLabel: AppLocalizations.of(context)!.common_delete);

    if (confirm == true) {
      try {
        await _repo.deleteComment(widget.postId, commentId);
      } catch (e) {
        log('PostDetailScreen: deleteComment error: $e');
        if (mounted) showErrorSnackbar(context, e);
      }
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
    final confirm = await showConfirmSheet(context, title: AppLocalizations.of(context)!.post_deleteConfirm, content: AppLocalizations.of(context)!.post_deleteConfirmMessage, confirmLabel: AppLocalizations.of(context)!.common_delete);

    if (confirm == true) {
      try {
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
      } catch (e) {
        log('PostDetailScreen: deletePost error: $e');
        if (mounted) showErrorSnackbar(context, e);
      }
    }
  }

  Future<void> _resolvePost() async {
    try {
      await _repo.resolvePost(widget.postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.post_resolvedMarked)),
        );
      }
    } catch (e) {
      log('PostDetailScreen: resolvePost error: $e');
      if (mounted) showErrorSnackbar(context, e);
    }
  }
}
