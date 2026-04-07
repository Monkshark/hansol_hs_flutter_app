import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/screens/auth/login_screen.dart';
import 'package:hansol_high_school/screens/board/my_posts_screen.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/screens/board/write_post_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';

/// 게시판 목록 화면 (BoardScreen)
///
/// - 카테고리(전체/자유/질문/정보공유) 필터로 게시글 분류
/// - 키워드 검색으로 게시글 빠르게 탐색
/// - 내 활동(내가 쓴 글/댓글) 바로가기 제공
/// - PostCard 위젯으로 각 게시글의 요약 정보 표시
class BoardScreen extends StatefulWidget {
  const BoardScreen({Key? key}) : super(key: key);

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  static const _categories = ['전체', '인기글', '자유', '질문', '정보공유', '분실물', '학생회', '동아리'];
  static const _pageSize = 20;
  int _selectedIndex = 0;
  String _searchQuery = '';
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allDocs = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _initialLoading = true;

  String get _selectedCategory => _categories[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Query<Map<String, dynamic>> _baseQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('posts');
    if (_selectedCategory == '인기글') {
      // 인기글: likeCount > 0 (인덱스 prefix 매칭 + 좋아요 0개 글 제외)
      q = q
          .where('likeCount', isGreaterThan: 0)
          .orderBy('likeCount', descending: true)
          .orderBy('createdAt', descending: true);
    } else {
      q = q.orderBy('createdAt', descending: true);
      if (_selectedCategory != '전체') {
        q = q.where('category', isEqualTo: _selectedCategory);
      }
    }
    return q;
  }

  Future<void> _loadPosts() async {
    setState(() { _initialLoading = true; _allDocs = []; _lastDoc = null; _hasMore = true; });

    final snap = await _baseQuery().limit(_pageSize).get();
    if (mounted) {
      setState(() {
        _allDocs = snap.docs;
        _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
        _hasMore = snap.docs.length == _pageSize;
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_hasMore || _loadingMore || _lastDoc == null) return;
    setState(() => _loadingMore = true);

    final snap = await _baseQuery().startAfterDocument(_lastDoc!).limit(_pageSize).get();
    if (mounted) {
      setState(() {
        _allDocs.addAll(snap.docs);
        _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
        _hasMore = snap.docs.length == _pageSize;
        _loadingMore = false;
      });
    }
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
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: TextStyle(fontSize: 15, color: textColor),
                decoration: InputDecoration(
                  hintText: '검색...',
                  hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              )
            : const Text('게시판'),
        centerTitle: !_isSearching,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = '';
            }),
          ),
          if (!_isSearching && AuthService.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyPostsScreen()),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.theme.primaryColor,
        onPressed: _onWrite,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    _loadPosts();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.theme.primaryColor
                          : (isDark ? const Color(0xFF252830) : const Color(0xFFF0F0F0)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.theme.darkGreyColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_initialLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(_allDocs);

                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data();
                    final title = (data['title'] ?? '').toString().toLowerCase();
                    final content = (data['content'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery) || content.contains(_searchQuery);
                  }).toList();
                }

                final pinned = docs.where((doc) => doc.data()['isPinned'] == true).toList();
                final nonPinned = docs.where((doc) => doc.data()['isPinned'] != true).toList();

                pinned.sort((a, b) {
                  final aTime = a.data()['pinnedAt'] as Timestamp?;
                  final bTime = b.data()['pinnedAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                docs = [...pinned, ...nonPinned];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_searchQuery.isNotEmpty ? Icons.search_off : Icons.article_outlined,
                          size: 40, color: AppColors.theme.darkGreyColor),
                        const SizedBox(height: 8),
                        Text(_searchQuery.isNotEmpty ? '검색 결과가 없습니다' : '게시글이 없습니다',
                          style: TextStyle(color: AppColors.theme.darkGreyColor)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 80),
                    itemCount: docs.length + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == docs.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      return PostCard(
                        doc: docs[index],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(postId: docs[index].id),
                            ),
                          );
                          if (mounted) _loadPosts();
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _onWrite() async {
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

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WritePostScreen()),
    );
    if (result == true && mounted) {
      _loadPosts();
    }
  }
}

/// 게시글 요약 카드 위젯 (카테고리, 제목, 댓글 수, 좋아요 등 표시)
class PostCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onTap;

  const PostCard({required this.doc, required this.onTap, Key? key}) : super(key: key);

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
    final authorName = (isAnon && isManagerView && realName != null)
        ? '익명 ($realName)'
        : (data['authorName'] ?? '익명');
    final category = data['category'] ?? '';
    final commentCount = data['commentCount'] ?? 0;
    final rawLikes = data['likes'];
    final rawDislikes = data['dislikes'];
    // 비정규화 카운터(likeCount/dislikeCount) 우선, 없으면 Map/int fallback
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
    final timeStr = createdAt != null ? _formatTime(createdAt.toDate()) : '';

    return GestureDetector(
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
                    color: _categoryColor(category).withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(category,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _categoryColor(category))),
                ),
                if (data['isResolved'] == true && category == '분실물')
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('해결',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
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
                      width: 56,
                      height: 56,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: firstImage,
                            fit: BoxFit.cover,
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
                  Icon(Icons.thumb_down, size: 12, color: Colors.redAccent),
                  const SizedBox(width: 2),
                  Text('$dislikeCount', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
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

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('M/d').format(dt);
  }
}
