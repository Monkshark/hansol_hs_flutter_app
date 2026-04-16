# AnalyticsService

> 한국어: [analytics_service.md](./analytics_service.md)

> `lib/data/analytics_service.dart` — Firebase Analytics event wrapper

All methods are `static`. All logging is centralized in this class to prevent event name typos and duplicates. Failures are handled silently inside (no try/catch needed at the call site).

---

## `observer`

```dart
static FirebaseAnalyticsObserver get observer
```

Register on `MaterialApp.navigatorObservers` to automatically track screen transitions (`screen_view`).

---

## `setUserId`

```dart
static Future<void> setUserId(String? uid)
```

Set the uid on login, pass null on logout.

---

## `setUserProperty`

```dart
static Future<void> setUserProperty(String name, String? value)
```

Set user properties (grade, userType, etc.).

---

## Auth events

| Method | Event name | Parameters |
|--------|----------|----------|
| `logLogin(method)` | `login` | `{method: 'google'\|'apple'\|'kakao'\|'github'}` |
| `logSignUp(method)` | `sign_up` | `{method}` |
| `logLogout()` | `logout` | — |

---

## Board events

| Method | Event name | Parameters |
|--------|----------|----------|
| `logPostCreate(boardType, isAnonymous)` | `post_create` | `{board_type, is_anonymous}` |
| `logPostView(postId)` | `post_view` | `{post_id}` |
| `logCommentCreate(postId, isReply)` | `comment_create` | `{post_id, is_reply}` |
| `logPostShare(postId)` | `post_share` | `{post_id}` |
| `logPostReport(postId)` | `post_report` | `{post_id}` |

---

## Grade/Schedule/Search events

| Method | Event name | Parameters |
|--------|----------|----------|
| `logGradeAdd(examType, subject)` | `grade_add` | `{exam_type, subject}` |
| `logGradeGoalSet(subject)` | `grade_goal_set` | `{subject}` |
| `logScheduleAdd()` | `schedule_add` | — |
| `logDdayAdd()` | `dday_add` | — |
| `logNotificationToggle(category, enabled)` | `notification_toggle` | `{category, enabled}` |
| `logSearch(term)` | `search` | `{search_term}` |

---

## Internal structure

```dart
static Future<void> _log(String name, [Map<String, Object>? params]) async {
  try {
    await _instance.logEvent(name: name, parameters: params);
  } catch (e) {
    if (kDebugMode) debugPrint('[Analytics] $name failed: $e');
  }
}
```

All public methods publish events through `_log`. Failures in release builds do not affect the app.
