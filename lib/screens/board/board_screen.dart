import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/search_history_service.dart';
import 'package:hansol_high_school/data/search_tokens.dart';
import 'package:hansol_high_school/screens/auth/login_screen.dart';
import 'package:hansol_high_school/screens/board/my_posts_screen.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/screens/board/write_post_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({Key? key}) : super(key: key);

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

String _formatSuspendDuration(AppLocalizations l, Duration diff) {
  final days = diff.inDays;
  final hours = diff.inHours % 24;
  final minutes = diff.inMinutes % 60;
  final seconds = diff.inSeconds % 60;
  final parts = <String>[];
  if (days > 0) parts.add(l.data_suspendDays(days));
  if (hours > 0) parts.add(l.data_suspendHours(hours));
  if (minutes > 0) parts.add(l.data_suspendMinutes(minutes));
  if (parts.isEmpty) parts.add(l.data_suspendSeconds(seconds));
  return parts.join(' ');
}

class _BoardScreenState extends State<BoardScreen> {
  static const _categoryKeys = ['전체', '인기글', '자유', '질문', '정보공유', '분실물', '학생회', '동아리'];
  static const _pageSize = 20;
  static const _searchLimit = 50;
  int _selectedIndex = 0;
  String _searchQuery = '';
  bool _isSearching = false;
  bool _searchLoading = false;
  List<String> _searchHistory = [];
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  late final PageController _pageController = PageController(initialPage: _selectedIndex);
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _searchResults = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _initialLoading = true;

  String get _selectedCategory => _categoryKeys[_selectedIndex];

  String _localizedCategory(BuildContext context, String key) {
    final l = AppLocalizations.of(context)!;
    switch (key) {
      case '전체': return l.board_categoryAll;
      case '인기글': return l.board_categoryPopular;
      case '자유': return l.board_categoryFree;
      case '질문': return l.board_categoryQuestion;
      case '정보공유': return l.board_categoryInfoShare;
      case '분실물': return l.board_categoryLostFound;
      case '학생회': return l.board_categoryStudentCouncil;
      case '동아리': return l.board_categoryClub;
      default: return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadSearchHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _scrollCategoryIntoView() {
    if (!_categoryScrollController.hasClients) return;
    const chipWidth = 78.0;
    final viewportWidth = _categoryScrollController.position.viewportDimension;
    final target = (_selectedIndex * chipWidth) - (viewportWidth / 2) + (chipWidth / 2);
    final clamped = target.clamp(
      _categoryScrollController.position.minScrollExtent,
      _categoryScrollController.position.maxScrollExtent,
    );
    _categoryScrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadSearchHistory() async {
    final h = await SearchHistoryService.load();
    if (mounted) setState(() => _searchHistory = h);
  }

  void _onSearchChanged(String v) {
    final q = v.trim();
    setState(() => _searchQuery = q);
    _searchDebounce?.cancel();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchLoading = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 350), () => _runSearch(q));
  }

  Future<void> _runSearch(String query) async {
    final tokens = SearchTokens.forQuery(query);
    if (tokens.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searchLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .where('searchTokens', arrayContainsAny: tokens)
          .limit(_searchLimit)
          .get();

      final lowerQuery = query.toLowerCase();
      final filtered = snap.docs.where((doc) {
        final d = doc.data();
        final title = (d['title'] ?? '').toString().toLowerCase();
        final content = (d['content'] ?? '').toString().toLowerCase();
        return title.contains(lowerQuery) || content.contains(lowerQuery);
      }).toList();

      filtered.sort((a, b) {
        final at = a.data()['createdAt'] as Timestamp?;
        final bt = b.data()['createdAt'] as Timestamp?;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

      if (mounted) {
        setState(() {
          _searchResults = filtered;
          _searchLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  Future<void> _commitSearchHistory(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    await SearchHistoryService.add(q);
    await _loadSearchHistory();
  }

  Future<void> _removeHistory(String query) async {
    await SearchHistoryService.remove(query);
    await _loadSearchHistory();
  }

  Future<void> _clearAllHistory() async {
    await SearchHistoryService.clear();
    await _loadSearchHistory();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Query<Map<String, dynamic>> _baseQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('posts');
    q = q.orderBy('createdAt', descending: true);
    if (_selectedCategory != '전체' && _selectedCategory != '인기글') {
      q = q.where('category', isEqualTo: _selectedCategory);
    }
    return q;
  }

  int _docLikeCount(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d['likeCount'] is int) return d['likeCount'] as int;
    final raw = d['likes'];
    if (raw is Map) return raw.length;
    if (raw is int) return raw;
    return 0;
  }

  Future<void> _loadPosts() async {
    setState(() { _initialLoading = true; _allDocs = []; _lastDoc = null; _hasMore = true; });

    final isPopular = _selectedCategory == '인기글';
    final fetchLimit = isPopular ? 100 : _pageSize;

    final snap = await _baseQuery().limit(fetchLimit).get();
    if (!mounted) return;

    var docs = snap.docs;
    if (isPopular) {
      docs = docs.where((d) => _docLikeCount(d) > 0).toList()
        ..sort((a, b) => _docLikeCount(b).compareTo(_docLikeCount(a)));
    }

    setState(() {
      _allDocs = docs;
      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = !isPopular && snap.docs.length == _pageSize;
      _initialLoading = false;
    });
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: _isSearching
            ? TextField(
                autofocus: true,
                controller: _searchController,
                style: TextStyle(fontSize: 15, color: textColor),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.board_searchHint,
                  hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: (v) {
                  _commitSearchHistory(v);
                  _runSearch(v.trim());
                },
              )
            : Text(AppLocalizations.of(context)!.board_title),
        centerTitle: !_isSearching,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: AppLocalizations.of(context)!.home_search,
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
                _searchController.clear();
                _searchResults = [];
                _searchDebounce?.cancel();
              }
            }),
          ),
          if (!_isSearching && AuthService.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: AppLocalizations.of(context)!.home_myPosts,
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
        tooltip: AppLocalizations.of(context)!.home_writePost,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: Column(
        children: [
          if (!_isSearching) ...[
            SizedBox(
              height: 40,
              child: ListView.separated(
                controller: _categoryScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categoryKeys.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _selectedIndex == index;
                  return Semantics(
                    selected: selected,
                    button: true,
                    child: GestureDetector(
                    onTap: () {
                      if (_selectedIndex == index) return;
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      );
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
                        _localizedCategory(context, _categoryKeys[index]),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.theme.darkGreyColor,
                        ),
                      ),
                    ),
                  ));
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: _isSearching
                ? _buildSearchBody(context)
                : PageView.builder(
                    controller: _pageController,
                    itemCount: _categoryKeys.length,
                    onPageChanged: (i) {
                      setState(() => _selectedIndex = i);
                      _scrollCategoryIntoView();
                      _loadPosts();
                    },
                    itemBuilder: (context, index) => _buildCategoryBody(context, index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBody(BuildContext context, int pageIndex) {
    if (_initialLoading && pageIndex == _selectedIndex) {
      return const Center(child: CircularProgressIndicator());
    }

    var docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(_allDocs);

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
            Icon(Icons.article_outlined,
                size: 40, color: AppColors.theme.darkGreyColor),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.board_emptyPosts,
                style: TextStyle(color: AppColors.theme.darkGreyColor)),
          ],
        ),
      );
    }

    final isCurrent = pageIndex == _selectedIndex;
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.separated(
        controller: isCurrent ? _scrollController : null,
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 80),
        itemCount: docs.length + (_loadingMore && isCurrent ? 1 : 0),
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
  }

  Widget _buildSearchBody(BuildContext context) {
    if (_searchQuery.isEmpty) {
      if (_searchHistory.isEmpty) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.history, size: 40, color: AppColors.theme.darkGreyColor),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.board_searchEmptyQuery,
                style: TextStyle(color: AppColors.theme.darkGreyColor)),
          ]),
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(AppLocalizations.of(context)!.board_recentSearches,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.theme.darkGreyColor)),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllHistory,
                  child: Text(AppLocalizations.of(context)!.board_clearAllSearches,
                      style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor)),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _searchHistory
                  .map((q) => InputChip(
                        label: Text(q, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          _searchController.text = q;
                          _searchController.selection = TextSelection.fromPosition(
                              TextPosition(offset: q.length));
                          _onSearchChanged(q);
                        },
                        onDeleted: () => _removeHistory(q),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    }

    if (_searchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off, size: 40, color: AppColors.theme.darkGreyColor),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.board_searchNoResults,
              style: TextStyle(color: AppColors.theme.darkGreyColor)),
        ]),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 80),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return PostCard(
          doc: _searchResults[index],
          onTap: () async {
            _commitSearchHistory(_searchQuery);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(postId: _searchResults[index].id),
              ),
            );
            if (mounted) _runSearch(_searchQuery);
          },
        );
      },
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

    final suspendDuration = await AuthService.getSuspendedDuration();
    if (suspendDuration != null) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        final formatted = _formatSuspendDuration(l, suspendDuration);
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

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WritePostScreen()),
    );
    if (result == true && mounted) {
      _loadPosts();
    }
  }
}

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
                  child: Text(_localizedCategoryName(context, category),
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

  String _localizedCategoryName(BuildContext context, String key) {
    final l = AppLocalizations.of(context)!;
    switch (key) {
      case '자유': return l.board_categoryFree;
      case '인기글': return l.board_categoryPopular;
      case '질문': return l.board_categoryQuestion;
      case '정보공유': return l.board_categoryInfoShare;
      case '분실물': return l.board_categoryLostFound;
      case '학생회': return l.board_categoryStudentCouncil;
      case '동아리': return l.board_categoryClub;
      default: return key;
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
