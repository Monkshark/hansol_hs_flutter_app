import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/analytics_service.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/search_history_service.dart';
import 'package:hansol_high_school/data/search_tokens.dart';
import 'package:hansol_high_school/screens/auth/login_screen.dart';
import 'package:hansol_high_school/screens/board/my_posts_screen.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/data/board_categories.dart';
import 'package:hansol_high_school/data/post_repository.dart';
import 'package:hansol_high_school/screens/board/widgets/board_search_body.dart';
import 'package:hansol_high_school/screens/board/widgets/post_card.dart';
import 'package:hansol_high_school/screens/board/write_post_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}


class _BoardScreenState extends State<BoardScreen> {
  static const _categoryKeys = BoardCategories.boardKeys;
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
    return BoardCategories.localizedName(AppLocalizations.of(context)!, key);
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.trackFirstVisit('board');
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
      final snap = await _repo.searchPosts(tokens: tokens, limit: _searchLimit);

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
    } catch (e) {
      log('BoardScreen: search error: $e');
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

  final _repo = PostRepository.instance;

  Query<Map<String, dynamic>> _baseQuery() {
    final category = (_selectedCategory != BoardCategories.all && _selectedCategory != BoardCategories.popular)
        ? _selectedCategory
        : null;
    return _repo.baseQuery(category: category);
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

    final isPopular = _selectedCategory == BoardCategories.popular;
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
              height: MediaQuery.of(context).size.height * 0.045,
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
                ? BoardSearchBody(
                    searchQuery: _searchQuery,
                    searchLoading: _searchLoading,
                    searchResults: _searchResults,
                    searchHistory: _searchHistory,
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onCommitHistory: _commitSearchHistory,
                    onRemoveHistory: _removeHistory,
                    onClearAllHistory: _clearAllHistory,
                    onRunSearch: _runSearch,
                    onPostReturned: () { if (mounted) _runSearch(_searchQuery); },
                  )
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
        cacheExtent: 500,
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
    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WritePostScreen()),
    );
    if (result == true && mounted) {
      _loadPosts();
    }
  }
}
