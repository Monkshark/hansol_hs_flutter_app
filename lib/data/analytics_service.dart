import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

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
}
