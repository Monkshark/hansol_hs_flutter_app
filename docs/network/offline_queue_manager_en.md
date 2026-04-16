# OfflineQueueManager

> 한국어: [offline_queue_manager.md](./offline_queue_manager.md)

> `lib/network/offline_queue_manager.dart` — Offline write queue

Saves Firestore write operations that occur while offline into sqflite, and automatically re-executes them in order when the network is restored.

---

## Singleton

```dart
class OfflineQueueManager {
  OfflineQueueManager._();
  static final instance = OfflineQueueManager._();
}
```

`initialize()` is called from `_deferredInit()` in `main.dart`.

---

## `initialize`

```dart
Future<void> initialize()
```

1. Opens/creates the `offline_queue.db` SQLite database
2. Refreshes the pending-operation count
3. Starts subscribing to `NetworkStatus.onStatusChange` (automatically processes the queue when the network is restored)

### Queue table schema

```sql
CREATE TABLE queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,        -- 'create_post' | 'create_comment'
  payload TEXT NOT NULL,     -- JSON-serialized data
  createdAt INTEGER NOT NULL,
  retryCount INTEGER DEFAULT 0
)
```

---

## Adding to the queue

### `enqueuePost`

```dart
Future<int> enqueuePost(Map<String, dynamic> postData)
```

Saves post creation data to the queue. Converts `FieldValue.serverTimestamp()` → `'__SERVER_TIMESTAMP__'` placeholder for JSON serialization.

### `enqueueComment`

```dart
Future<int> enqueueComment(String postId, Map<String, dynamic> commentData)
```

Saves comment data to the queue. Bundles `postId` and `commentData` into a single payload.

---

## Queue processing

When the network is restored, `_processQueue()` runs automatically:

```
Network restoration detected (onStatusChange)
  │
  └── _processQueue()
       ├── Fetch the oldest operation from the queue (FIFO)
       ├── Abort immediately if the network disconnects
       ├── Operation succeeds → remove from the queue
       ├── Operation fails
       │     ├── retryCount < 3 → increment count, retry on next restoration
       │     └── retryCount >= 3 → remove from the queue (drop)
       └── All operations completed → SyncStatus.idle()
```

### Supported operation types

| type | Description | Firestore execution |
|------|-------------|---------------------|
| `create_post` | Create post | `posts.add(data)` |
| `create_comment` | Create comment | `comments.add(data)` + `commentCount` increment |

---

## Sync status stream

```dart
Stream<SyncStatus> get onSyncStatusChange
int get pendingCount
```

Subscribed by `OfflineBanner` to display the status in the UI.

### SyncStatus

| State | Meaning |
|-------|---------|
| `SyncState.idle` | No pending operations |
| `SyncState.pending` | Pending operations exist (waiting for network) |
| `SyncState.syncing` | Queue is being processed |

---

## Utilities

### `syncNow`

```dart
Future<void> syncNow()
```

Manual sync trigger. If online, immediately starts queue processing.

### `clearQueue`

```dart
Future<void> clearQueue()
```

Deletes all pending operations.

---

## ServerTimestamp serialization

Because `FieldValue.serverTimestamp()` cannot be JSON-serialized:

1. **On save** (`_sanitizeForStorage`): `FieldValue` → `'__SERVER_TIMESTAMP__'` string
2. **On execution** (`_restoreTimestamps`): `'__SERVER_TIMESTAMP__'` → `FieldValue.serverTimestamp()`

Nested Maps are handled recursively as well.
