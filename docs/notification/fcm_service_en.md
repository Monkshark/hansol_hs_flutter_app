# FcmService

> 한국어: [fcm_service.md](./fcm_service.md)

> `lib/notification/fcm_service.dart` — FCM push notifications, topics, deep links

All methods are `static`. Handles Firebase Cloud Messaging initialization, token management, topic subscriptions, and deep-link routing.

---

## `initialize`

```dart
static Future<void> initialize()
```

**Description**: Initializes the FCM service. Called once from `main()`.

1. Create the Android notification channel (`_initChannel`)

2. **Initialize the local notifications plugin** (registers the tap callback for foreground FCM notifications):
   ```dart
   await _localNotifications.initialize(
     const InitializationSettings(android: androidSettings, iOS: iosSettings),
     onDidReceiveNotificationResponse: onNotificationTap,
   );
   ```
   > `onNotificationTap` is imported from `main.dart`. On tap, it forwards to `notificationStream` + `handleLocalNotificationTap` → calls `_handleDeepLink`.

3. Register the Android notification channel

4. Request notification permission:
   ```dart
   await _messaging.requestPermission(alert: true, badge: true, sound: true);
   ```

5. Configure foreground notification presentation options

6. Save the FCM token + register a token-refresh listener:
   ```dart
   await _saveToken();
   _messaging.onTokenRefresh.listen(_onTokenRefresh);
   ```

7. Subscribe to topics (based on settings):
   ```dart
   await _subscribeTopics();
   ```

8. Register message handlers:
   ```dart
   FirebaseMessaging.onMessage.listen(_onForegroundMessage);        // foreground
   FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp); // background tap
   final initialMessage = await _messaging.getInitialMessage();      // terminated tap
   ```

---

## `_saveToken` / `_onTokenRefresh`

```dart
static Future<void> _saveToken()
static Future<void> _onTokenRefresh(String token)
```

Saves the FCM token to the `fcmToken` field of the `users/{uid}` Firestore document. A Cloud Function uses this token to send personal notifications.

---

## Topic management

### `_subscribeTopics`

```dart
static Future<void> _subscribeTopics()
```

Subscribes to topics based on the [SettingData](../data/setting_data.md) configuration:

- `board_new_post`: notifications for the entire board
- Per-category: `board_free`, `board_question`, `board_info`, `board_lost`, `board_council`, `board_club`
- `board_popular`: popular-post notifications

### Korean → English topic mapping

```dart
static const _categoryTopicKey = {
  '자유': 'free', '질문': 'question', '정보공유': 'info',
  '분실물': 'lost', '학생회': 'council', '동아리': 'club',
};
```

FCM topic names cannot contain Korean → convert to English.

### `toggleBoardNotification`

```dart
static Future<void> toggleBoardNotification(bool enabled)
```

Toggles notifications for the entire board. Subscribes/unsubscribes the `board_new_post` topic + saves to [SettingData](../data/setting_data.md).

### `toggleCategoryNotification`

```dart
static Future<void> toggleCategoryNotification(String category, bool enabled)
```

Toggles per-category notifications. Example: `toggleCategoryNotification('자유', false)`.

### `togglePopularNotification`

```dart
static Future<void> togglePopularNotification(bool enabled)
```

Toggles popular-post notifications. `board_popular` topic.

---

## `_onForegroundMessage`

```dart
static void _onForegroundMessage(RemoteMessage message)
```

**Description**: When an FCM message is received in the foreground, displays it as a local notification.

```dart
_localNotifications.show(
  notification.hashCode,
  notification.title,
  notification.body,
  NotificationDetails(...),
  payload: payload,  // key=value;key=value format
);
```

---

## `_handleDeepLink`

```dart
static Future<void> _handleDeepLink(Map<String, dynamic> data)
```

**Description**: Routes to a screen based on the data payload when the notification is tapped.

```dart
switch (type) {
  case 'comment':
  case 'new_post':
    navigator.push(...PostDetailScreen(postId: postId));
  case 'account':
    if (isManager) navigator.push(...AdminScreen());
    else navigator.push(...NotificationScreen());
  case 'chat':
    // Look up chat document by chatId → load peer info → navigate to ChatRoomScreen
}
```

| type | Target | Destination screen |
|------|--------|--------------------|
| `comment` | Post author / mentioned user | `PostDetailScreen` |
| `new_post` | Topic subscribers | `PostDetailScreen` |
| `account` | Admin (signup request) | `AdminScreen` |
| `account` | Regular user (approved/suspended, etc.) | `NotificationScreen` |
| `chat` | Chat participant | `ChatRoomScreen` |

> Admin vs regular user is determined by [`AuthService`](../data/auth_service.md)`.cachedProfile?.isManager`.

---

## payload encoding/decoding

```dart
static String _encodePayload(Map<String, dynamic> data)
// → "type=comment;postId=abc123"

static Map<String, dynamic> decodePayload(String payload)
// "type=comment;postId=abc123" → {type: 'comment', postId: 'abc123'}
```

Used to carry the payload for foreground local notifications. `=` separates key and value; `;` separates pairs.

---

## `onUserLogin`

```dart
static Future<void> onUserLogin()
```

Called right after login. Saves the token + re-subscribes to topics.

---

## `firebaseMessagingBackgroundHandler`

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
```

Background message handler. Currently an empty implementation (system notifications are displayed automatically).
`@pragma('vm:entry-point')` prevents tree-shaking.
