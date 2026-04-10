import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/board_screen.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 내 활동 화면 (MyPostsScreen)
///
/// - 내가 작성한 글 목록을 탭으로 조회
/// - 내가 작성한 댓글 목록을 탭으로 조회
/// - 각 항목 탭 시 해당 게시글 상세로 이동
class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({Key? key}) : super(key: key);

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final uid = AuthService.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.myActivity_title)),
        body: const Center(child: Text('로그인이 필요합니다')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: Text(AppLocalizations.of(context)!.myActivity_title),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.theme.primaryColor,
          unselectedLabelColor: AppColors.theme.darkGreyColor,
          indicatorColor: AppColors.theme.primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.myActivity_myPosts),
            Tab(text: AppLocalizations.of(context)!.myActivity_myComments),
            Tab(text: AppLocalizations.of(context)!.myActivity_savedPosts),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyPostsList(uid: uid),
          _MyCommentsList(uid: uid),
          _BookmarkedPostsList(uid: uid),
        ],
      ),
    );
  }
}

class _MyPostsList extends StatelessWidget {
  final String uid;
  const _MyPostsList({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.myActivity_noPosts, style: TextStyle(color: AppColors.theme.darkGreyColor)),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => PostCard(
            doc: docs[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailScreen(postId: docs[index].id)),
            ),
          ),
        );
      },
    );
  }
}

class _MyCommentsList extends StatelessWidget {
  final String uid;
  const _MyCommentsList({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collectionGroup('comments')
          .where('authorUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.myActivity_noComments, style: TextStyle(color: AppColors.theme.darkGreyColor)),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = Theme.of(context).textTheme.bodyLarge?.color;

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final content = data['content'] ?? '';
            final createdAt = data['createdAt'] as Timestamp?;
            final postRef = docs[index].reference.parent.parent;

            return GestureDetector(
              onTap: () {
                if (postRef != null) {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postRef.id)));
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2028) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content, style: TextStyle(fontSize: 14, color: textColor),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(
                      createdAt != null
                          ? _formatTime(createdAt.toDate())
                          : '',
                      style: TextStyle(fontSize: 11, color: AppColors.theme.darkGreyColor),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

class _BookmarkedPostsList extends StatelessWidget {
  final String uid;
  const _BookmarkedPostsList({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('posts')
          .where('bookmarkedBy', arrayContains: uid)
          .orderBy('createdAt', descending: true).limit(50).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bookmark_border, size: 40, color: AppColors.theme.darkGreyColor),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.bookmarks_empty, style: TextStyle(color: AppColors.theme.darkGreyColor)),
        ]));
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
          itemCount: docs.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => PostCard(
            doc: docs[index],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: docs[index].id))),
          ),
        );
      },
    );
  }
}
