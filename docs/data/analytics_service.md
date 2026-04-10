# AnalyticsService

> `lib/data/analytics_service.dart` — Firebase Analytics 이벤트 래퍼

모든 메서드가 `static`. 이벤트 이름 오타/중복 방지를 위해 모든 로깅을 이 클래스로 집중. 내부에서 silent fail 처리 (호출부에서 try/catch 불필요)

---

## `observer`

```dart
static FirebaseAnalyticsObserver get observer
```

`MaterialApp.navigatorObservers`에 등록하면 화면 전환(`screen_view`) 자동 추적

---

## `setUserId`

```dart
static Future<void> setUserId(String? uid)
```

로그인 시 uid 설정, 로그아웃 시 null 전달

---

## `setUserProperty`

```dart
static Future<void> setUserProperty(String name, String? value)
```

사용자 속성 설정 (grade, userType 등)

---

## 인증 이벤트

| 메서드 | 이벤트명 | 파라미터 |
|--------|----------|----------|
| `logLogin(method)` | `login` | `{method: 'google'\|'apple'\|'kakao'\|'github'}` |
| `logSignUp(method)` | `sign_up` | `{method}` |
| `logLogout()` | `logout` | — |

---

## 게시판 이벤트

| 메서드 | 이벤트명 | 파라미터 |
|--------|----------|----------|
| `logPostCreate(boardType, isAnonymous)` | `post_create` | `{board_type, is_anonymous}` |
| `logPostView(postId)` | `post_view` | `{post_id}` |
| `logCommentCreate(postId, isReply)` | `comment_create` | `{post_id, is_reply}` |
| `logPostShare(postId)` | `post_share` | `{post_id}` |
| `logPostReport(postId)` | `post_report` | `{post_id}` |

---

## 성적/일정/검색 이벤트

| 메서드 | 이벤트명 | 파라미터 |
|--------|----------|----------|
| `logGradeAdd(examType, subject)` | `grade_add` | `{exam_type, subject}` |
| `logGradeGoalSet(subject)` | `grade_goal_set` | `{subject}` |
| `logScheduleAdd()` | `schedule_add` | — |
| `logDdayAdd()` | `dday_add` | — |
| `logNotificationToggle(category, enabled)` | `notification_toggle` | `{category, enabled}` |
| `logSearch(term)` | `search` | `{search_term}` |

---

## 내부 구조

```dart
static Future<void> _log(String name, [Map<String, Object>? params]) async {
  try {
    await _instance.logEvent(name: name, parameters: params);
  } catch (e) {
    if (kDebugMode) debugPrint('[Analytics] $name failed: $e');
  }
}
```

모든 public 메서드가 `_log`를 통해 이벤트를 발행. 릴리스 빌드에서 실패해도 앱에 영향 없음
