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

## App lifecycle events

| Method | Event name | Parameters |
|--------|----------|----------|
| `logAppOpen(source)` | `app_open` | `{source}` |
| `markSessionStart()` | — | Starts internal timer |
| `logSessionEnd()` | `session_duration` | `{seconds}` |

`markSessionStart()` records the session start time. When `logSessionEnd()` is called, the elapsed time in seconds is sent as a `session_duration` event.

---

## Post creation funnel

| Method | Event name | Parameters |
|--------|----------|----------|
| `logPostStart(boardType)` | `post_start` | `{board_type}` |
| `logPostDraft()` | `post_draft` | — |
| `logPostSubmit(boardType)` | `post_submit` | `{board_type}` |

Post creation flow: **post_start → post_draft → post_submit**. Funnel analysis can identify drop-off points.

---

## Other events

| Method | Event name | Parameters |
|--------|----------|----------|
| `logFeatureDiscovery(feature)` | `feature_discovery` | `{feature}` |
| `trackFirstVisit(feature)` | `feature_discovery` | `{feature}` (first visit only) |
| `logErrorShown(errorType)` | `error_shown` | `{error_type}` |

`trackFirstVisit` checks SharedPreferences key `visited_$feature` and logs the `feature_discovery` event only on the first visit.

---

## User collection consent (opt-out)

Analytics collection is controlled outside of AnalyticsService:

- **`main.dart` `_deferredInit()`**: Combines `SharedPreferences.getBool('analyticsEnabled')` with a release mode check to call `FirebaseAnalytics.instance.setAnalyticsCollectionEnabled()`.
- **Settings screen**: The user can toggle analytics collection on/off. Changes are saved to `SharedPreferences` and `setAnalyticsCollectionEnabled()` is called immediately.

Collection is enabled by default in release builds. If the user disables it in settings, all subsequent event transmission stops.

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
