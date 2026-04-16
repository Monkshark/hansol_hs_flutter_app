# NetworkStatus

> 한국어: [network_status.md](./network_status.md)

> `lib/network/network_status.dart` — Network connectivity status

Uses the `connectivity_plus` plugin to check the current connectivity status. Provides both one-shot checks and a real-time stream.

---

## `isUnconnected`

```dart
static Future<bool> isUnconnected()
```

**Description**: Returns `true` when both WiFi and mobile data are disconnected.

```dart
if (_testOverride != null) return _testOverride!();
final results = await Connectivity().checkConnectivity();
return results.isEmpty || results.contains(ConnectivityResult.none);
```

- Offline if `results` is empty or contains `none`
- Used for offline checks before API calls ([MealDataApi](../api/meal_data_api.md), [TimetableDataApi](../api/timetable_data_api.md), [NoticeDataApi](../api/notice_data_api.md))
- When offline, returns cached data or displays a notice message

---

## Real-time stream monitoring

### `onStatusChange`

```dart
static Stream<bool> get onStatusChange
```

Stream of connectivity state changes. `true` = offline, `false` = online.
Automatically starts `connectivity_plus` listening on first access. It is a broadcast stream, so multiple widgets can subscribe concurrently.

Usage:
- `OfflineBanner` — displays offline banner + sync status
- `OfflineQueueManager` — automatically processes the queue when the network is restored

### `isOffline`

```dart
static bool get isOffline
```

The last known connectivity status. Used to synchronously check the current state without subscribing to the stream.

---

## Test support

```dart
static Future<bool> Function()? _testOverride;

@visibleForTesting
static set testOverride(Future<bool> Function()? fn) => _testOverride = fn;

@visibleForTesting
static void resetStream()
```

- Use `testOverride` to test online/offline scenarios without the `connectivity_plus` plugin
- Use `resetStream()` to reset the stream state (isolation between tests)
- Default `null` → in production, the real `Connectivity()` path runs
