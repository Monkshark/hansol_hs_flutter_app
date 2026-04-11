# FcmService

> `lib/notification/fcm_service.dart` — FCM 푸시 알림, 토픽, 딥링크

모든 메서드가 `static`. Firebase Cloud Messaging 초기화, 토큰 관리, 토픽 구독, 딥링크 라우팅을 담당

---

## `initialize`

```dart
static Future<void> initialize()
```

**설명**: FCM 서비스를 초기화함. `main()` 에서 한 번 호출

1. Android 알림 채널 생성 (`_initChannel`)

2. **로컬 알림 플러그인 초기화** (포그라운드 FCM 알림 탭 콜백 등록):
   ```dart
   await _localNotifications.initialize(
     const InitializationSettings(android: androidSettings, iOS: iosSettings),
     onDidReceiveNotificationResponse: onNotificationTap,
   );
   ```
   > `onNotificationTap`은 `main.dart`에서 import. 탭 시 `notificationStream` 전달 + `handleLocalNotificationTap` → `_handleDeepLink` 호출

3. Android 알림 채널 등록

4. 알림 권한 요청:
   ```dart
   await _messaging.requestPermission(alert: true, badge: true, sound: true);
   ```

5. 포그라운드 알림 표시 옵션 설정

6. FCM 토큰 저장 + 토큰 갱신 리스너 등록:
   ```dart
   await _saveToken();
   _messaging.onTokenRefresh.listen(_onTokenRefresh);
   ```

7. 토픽 구독 (설정에 따라):
   ```dart
   await _subscribeTopics();
   ```

8. 메시지 핸들러 등록:
   ```dart
   FirebaseMessaging.onMessage.listen(_onForegroundMessage);        // 포그라운드
   FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp); // 백그라운드 탭
   final initialMessage = await _messaging.getInitialMessage();      // 종료 상태 탭
   ```

---

## `_saveToken` / `_onTokenRefresh`

```dart
static Future<void> _saveToken()
static Future<void> _onTokenRefresh(String token)
```

FCM 토큰을 Firestore `users/{uid}` 문서의 `fcmToken` 필드에 저장. Cloud Function이 이 토큰으로 개인 알림 전송

---

## 토픽 관리

### `_subscribeTopics`

```dart
static Future<void> _subscribeTopics()
```

[SettingData](../data/setting_data.md) 설정에 따라 토픽을 구독함:

- `board_new_post`: 전체 게시판 알림
- 카테고리별: `board_free`, `board_question`, `board_info`, `board_lost`, `board_council`, `board_club`
- `board_popular`: 인기글 알림

### 한글→영문 토픽 매핑

```dart
static const _categoryTopicKey = {
  '자유': 'free', '질문': 'question', '정보공유': 'info',
  '분실물': 'lost', '학생회': 'council', '동아리': 'club',
};
```

FCM 토픽명에 한글 불가 → 영문 변환

### `toggleBoardNotification`

```dart
static Future<void> toggleBoardNotification(bool enabled)
```

전체 게시판 알림 토글. `board_new_post` 토픽 구독/해제 + [SettingData](../data/setting_data.md) 저장

### `toggleCategoryNotification`

```dart
static Future<void> toggleCategoryNotification(String category, bool enabled)
```

카테고리별 알림 토글. 예: `toggleCategoryNotification('자유', false)`

### `togglePopularNotification`

```dart
static Future<void> togglePopularNotification(bool enabled)
```

인기글 알림 토글. `board_popular` 토픽

---

## `_onForegroundMessage`

```dart
static void _onForegroundMessage(RemoteMessage message)
```

**설명**: 포그라운드에서 FCM 메시지 수신 시 로컬 알림으로 표시함

```dart
_localNotifications.show(
  notification.hashCode,
  notification.title,
  notification.body,
  NotificationDetails(...),
  payload: payload,  // key=value;key=value 형태
);
```

---

## `_handleDeepLink`

```dart
static Future<void> _handleDeepLink(Map<String, dynamic> data)
```

**설명**: 알림 탭 시 data payload 기반으로 화면을 라우팅함

```dart
switch (type) {
  case 'comment':
  case 'new_post':
    navigator.push(...PostDetailScreen(postId: postId));
  case 'account':
    if (isManager) navigator.push(...AdminScreen());
    else navigator.push(...NotificationScreen());
  case 'chat':
    // chatId로 chat 문서 조회 → 상대방 정보 로드 → ChatRoomScreen 이동
}
```

| type | 대상 | 이동 화면 |
|------|------|----------|
| `comment` | 게시글 작성자 / 멘션 대상 | `PostDetailScreen` |
| `new_post` | 토픽 구독자 | `PostDetailScreen` |
| `account` | 관리자 (가입 요청) | `AdminScreen` |
| `account` | 일반 유저 (승인/정지 등) | `NotificationScreen` |
| `chat` | 채팅 참여자 | `ChatRoomScreen` |

> 관리자/일반 유저 구분은 [`AuthService`](../data/auth_service.md)`.cachedProfile?.isManager`로 판별

---

## payload 인코딩/디코딩

```dart
static String _encodePayload(Map<String, dynamic> data)
// → "type=comment;postId=abc123"

static Map<String, dynamic> decodePayload(String payload)
// "type=comment;postId=abc123" → {type: 'comment', postId: 'abc123'}
```

포그라운드 로컬 알림의 payload 전달용. `=`로 key-value 분리, `;`로 쌍 분리

---

## `onUserLogin`

```dart
static Future<void> onUserLogin()
```

로그인 직후 호출. 토큰 저장 + 토픽 재구독

---

## `firebaseMessagingBackgroundHandler`

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
```

백그라운드 메시지 핸들러. 현재 빈 구현 (시스템 알림은 자동 표시)
`@pragma('vm:entry-point')`로 tree-shaking 방지
