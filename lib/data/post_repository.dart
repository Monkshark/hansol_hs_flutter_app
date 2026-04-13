import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

/// 게시판 Firestore 데이터 접근 계층
class PostRepository {
  PostRepository._();
  static final instance = PostRepository._();

  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  // ─── References ───

  DocumentReference<Map<String, dynamic>> postRef(String postId) =>
      _posts.doc(postId);

  CollectionReference<Map<String, dynamic>> commentsRef(String postId) =>
      _posts.doc(postId).collection('comments');

  // ─── Streams ───

  Stream<DocumentSnapshot<Map<String, dynamic>>> postStream(String postId) =>
      postRef(postId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(String postId) =>
      commentsRef(postId).orderBy('createdAt').snapshots();

  // ─── Read ───

  Future<QuerySnapshot<Map<String, dynamic>>> loadPosts({
    required Query<Map<String, dynamic>> query,
    required int limit,
  }) =>
      query.limit(limit).get();

  Query<Map<String, dynamic>> baseQuery({String? category}) {
    Query<Map<String, dynamic>> q = _posts.orderBy('createdAt', descending: true);
    if (category != null) {
      q = q.where('category', isEqualTo: category);
    }
    return q;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> searchPosts({
    required List<String> tokens,
    int limit = 50,
  }) =>
      _posts
          .where('searchTokens', arrayContainsAny: tokens)
          .limit(limit)
          .get();

  Stream<QuerySnapshot<Map<String, dynamic>>> myPostsStream(String uid) =>
      _posts
          .where('authorUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> bookmarkedPostsStream(String uid) =>
      _posts
          .where('bookmarkedBy', arrayContains: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots();

  Future<DocumentSnapshot<Map<String, dynamic>>> getPost(String postId) =>
      postRef(postId).get();

  Future<DocumentSnapshot<Map<String, dynamic>>> getPostFromServer(String postId) =>
      postRef(postId).get(const GetOptions(source: Source.server));

  // ─── Create ───

  Future<DocumentReference<Map<String, dynamic>>> createPost(Map<String, dynamic> data) =>
      _posts.add(data);

  Future<DocumentReference<Map<String, dynamic>>> addComment(
      String postId, Map<String, dynamic> commentData) async {
    final ref = await commentsRef(postId).add(commentData);
    await postRef(postId).update({'commentCount': FieldValue.increment(1)});
    return ref;
  }

  // ─── Update ───

  Future<void> updatePost(String postId, Map<String, dynamic> data) =>
      postRef(postId).update(data);

  Future<void> toggleBookmark(String postId, String uid, bool isCurrentlyBookmarked) =>
      postRef(postId).update({
        'bookmarkedBy': isCurrentlyBookmarked
            ? FieldValue.arrayRemove([uid])
            : FieldValue.arrayUnion([uid]),
      });

  Future<void> ensureLikesMap(String postId) async {
    final snap = await postRef(postId).get();
    final data = snap.data();
    if (data == null) return;
    final updates = <String, dynamic>{};
    if (data['likes'] == null || data['likes'] is int) updates['likes'] = {};
    if (data['dislikes'] == null || data['dislikes'] is int) updates['dislikes'] = {};
    if (data['likeCount'] is! int) {
      final raw = data['likes'];
      updates['likeCount'] = raw is Map ? raw.length : 0;
    }
    if (data['dislikeCount'] is! int) {
      final raw = data['dislikes'];
      updates['dislikeCount'] = raw is Map ? raw.length : 0;
    }
    if (updates.isNotEmpty) await postRef(postId).update(updates);
  }

  Future<void> toggleLike(String postId, String uid, {required bool hasLiked, required bool hasDisliked}) async {
    await ensureLikesMap(postId);
    if (hasLiked) {
      await postRef(postId).update({
        'likes.$uid': FieldValue.delete(),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      final updates = <String, dynamic>{
        'likes.$uid': true,
        'likeCount': FieldValue.increment(1),
      };
      if (hasDisliked) {
        updates['dislikes.$uid'] = FieldValue.delete();
        updates['dislikeCount'] = FieldValue.increment(-1);
      }
      await postRef(postId).update(updates);
    }
  }

  Future<void> toggleDislike(String postId, String uid, {required bool hasLiked, required bool hasDisliked}) async {
    await ensureLikesMap(postId);
    if (hasDisliked) {
      await postRef(postId).update({
        'dislikes.$uid': FieldValue.delete(),
        'dislikeCount': FieldValue.increment(-1),
      });
    } else {
      final updates = <String, dynamic>{
        'dislikes.$uid': true,
        'dislikeCount': FieldValue.increment(1),
      };
      if (hasLiked) {
        updates['likes.$uid'] = FieldValue.delete();
        updates['likeCount'] = FieldValue.increment(-1);
      }
      await postRef(postId).update(updates);
    }
  }

  Future<void> votePoll(String postId, String uid, int optionIndex) =>
      postRef(postId).update({'pollVoters.$uid': optionIndex});

  Future<void> pinPost(String postId) async {
    final pinnedSnapshot = await _posts.where('isPinned', isEqualTo: true).get();
    if (pinnedSnapshot.docs.length >= 3) {
      throw StateError('pin_maxed');
    }
    await postRef(postId).update({
      'isPinned': true,
      'pinnedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unpinPost(String postId) =>
      postRef(postId).update({'isPinned': false});

  Future<void> resolvePost(String postId) =>
      postRef(postId).update({'isResolved': true});

  Future<int> getPinnedCount() async {
    final snap = await _posts.where('isPinned', isEqualTo: true).get();
    return snap.docs.length;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getPinnedPosts() =>
      _posts.where('isPinned', isEqualTo: true).get();

  /// 익명 댓글 매핑 — transaction 사용
  Future<String> resolveAnonymousName(
    String postId,
    String uid,
    String authorLabel,
    String Function(int) anonymousNumLabel,
  ) async {
    final ref = postRef(postId);
    final postSnap = await ref.get();
    final postAuthorUid = postSnap.data()?['authorUid'];

    if (uid == postAuthorUid) return authorLabel;

    return _db.runTransaction<String>((transaction) async {
      final postDoc = await transaction.get(ref);
      final data = postDoc.data() ?? {};
      final mapping = Map<String, dynamic>.from(data['anonymousMapping'] ?? {});
      final count = (data['anonymousCount'] as int?) ?? 0;

      if (mapping.containsKey(uid)) {
        return anonymousNumLabel(mapping[uid]);
      } else {
        final newNum = count + 1;
        mapping[uid] = newNum;
        transaction.update(ref, {
          'anonymousMapping': mapping,
          'anonymousCount': newNum,
        });
        return anonymousNumLabel(newNum);
      }
    });
  }

  // ─── Delete ───

  Future<void> deleteComment(String postId, String commentId) async {
    await commentsRef(postId).doc(commentId).delete();
    await postRef(postId).update({'commentCount': FieldValue.increment(-1)});
  }

  Future<void> deletePost(String postId) async {
    final comments = await commentsRef(postId).get();
    for (var doc in comments.docs) {
      await doc.reference.delete();
    }
    await postRef(postId).delete();
  }

  // ─── Notifications (users subcollection) ───

  Future<void> sendNotification({
    required String targetUid,
    required String type,
    required String postId,
    required String postTitle,
    required String senderName,
    required String content,
  }) async {
    try {
      await _db.collection('users').doc(targetUid).collection('notifications').add({
        'type': type,
        'postId': postId,
        'postTitle': postTitle,
        'senderName': senderName,
        'content': content,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('PostRepository: sendNotification error: $e');
    }
  }

  // ─── Admin ───

  Future<void> logAdminAction(Map<String, dynamic> data) =>
      _db.collection('admin_logs').add(data);

  // ─── Refresh ───

  Future<void> refreshFromServer(String postId) async {
    await postRef(postId).get(const GetOptions(source: Source.server));
    await commentsRef(postId).get(const GetOptions(source: Source.server));
  }

  // ─── Report ───

  Future<void> reportPost({
    required String postId,
    required String reporterUid,
    required String reason,
    String? detail,
  }) =>
      _db.collection('reports').add({
        'postId': postId,
        'reporterUid': reporterUid,
        'reason': reason,
        'detail': detail ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
}
