import 'dart:async';
import 'dart:developer';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/analytics_service.dart';
import 'package:hansol_high_school/main.dart' show rootNavigatorKey;
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';

class DeepLinkService {
  static final _appLinks = AppLinks();
  static const _postPrefix = '/post/';
  static StreamSubscription<Uri>? _linkSub;

  static Future<void> initialize() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleUri(initialUri);
    } catch (e) {
      log('DeepLinkService: initial link error: $e');
    }

    _linkSub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (e) => log('DeepLinkService: stream error: $e'),
    );
  }

  static Future<void> dispose() async {
    await _linkSub?.cancel();
  }

  static void _handleUri(Uri uri) {
    log('DeepLinkService: received $uri');
    AnalyticsService.logAppOpen(source: 'deep_link');
    final path = uri.path;
    if (path.startsWith(_postPrefix)) {
      final postId = path.substring(_postPrefix.length).replaceAll('/', '');
      if (postId.isNotEmpty) _navigateToPost(postId);
    }
  }

  static void _navigateToPost(String postId, [int retries = 0]) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      if (retries < 5) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigateToPost(postId, retries + 1);
        });
      }
      return;
    }
    navigator.push(MaterialPageRoute(
      builder: (_) => PostDetailScreen(postId: postId),
    ));
  }
}
