import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  AnalyticsService._();
  static final FirebaseAnalytics _instance = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _instance);

  static Future<void> setUserId(String? uid) async {
    try {
      await _instance.setUserId(id: uid);
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] setUserId failed: $e');
    }
  }

  static Future<void> setUserProperty(String name, String? value) async {
    try {
      await _instance.setUserProperty(name: name, value: value);
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] setUserProperty failed: $e');
    }
  }

  static Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await _instance.logEvent(name: name, parameters: params);
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] $name failed: $e');
    }
  }

  static Future<void> logLogin(String method) =>
      _log('login', {'method': method});
  static Future<void> logSignUp(String method) =>
      _log('sign_up', {'method': method});
  static Future<void> logLogout() => _log('logout');

  static Future<void> logPostCreate({required String boardType, bool isAnonymous = false}) =>
      _log('post_create', {'board_type': boardType, 'is_anonymous': isAnonymous.toString()});
  static Future<void> logPostView(String postId) =>
      _log('post_view', {'post_id': postId});
  static Future<void> logCommentCreate({required String postId, bool isReply = false}) =>
      _log('comment_create', {'post_id': postId, 'is_reply': isReply.toString()});
  static Future<void> logPostShare(String postId) =>
      _log('post_share', {'post_id': postId});
  static Future<void> logPostReport(String postId) =>
      _log('post_report', {'post_id': postId});

  static Future<void> logGradeAdd({required String examType, required String subject}) =>
      _log('grade_add', {'exam_type': examType, 'subject': subject});
  static Future<void> logGradeGoalSet(String subject) =>
      _log('grade_goal_set', {'subject': subject});

  static Future<void> logScheduleAdd() => _log('schedule_add');
  static Future<void> logDdayAdd() => _log('dday_add');

  static Future<void> logNotificationToggle({required String category, required bool enabled}) =>
      _log('notification_toggle', {'category': category, 'enabled': enabled.toString()});

  static Future<void> logSearch(String term) => _log('search', {'search_term': term});

  static Future<void> logAppOpen({required String source}) =>
      _log('app_open', {'source': source});

  static Future<void> logFeatureDiscovery({required String feature}) =>
      _log('feature_discovery', {'feature': feature});

  static Future<void> trackFirstVisit(String feature) async {
    final key = 'visited_$feature';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);
    await logFeatureDiscovery(feature: feature);
  }

  static Future<void> logPostStart({required String boardType}) =>
      _log('post_start', {'board_type': boardType});

  static Future<void> logPostDraft() => _log('post_draft');

  static Future<void> logPostSubmit({required String boardType}) =>
      _log('post_submit', {'board_type': boardType});

  static DateTime? _sessionStart;

  static void markSessionStart() => _sessionStart = DateTime.now();

  static Future<void> logSessionEnd() async {
    if (_sessionStart == null) return;
    final seconds = DateTime.now().difference(_sessionStart!).inSeconds;
    _sessionStart = null;
    if (seconds > 1) await _log('session_duration', {'seconds': seconds});
  }

  static Future<void> logErrorShown({required String errorType}) =>
      _log('error_shown', {'error_type': errorType});
}
