# OfflineQueueManager

> `lib/network/offline_queue_manager.dart` — 오프라인 쓰기 큐

오프라인 상태에서 발생한 Firestore 쓰기 작업을 sqflite에 저장하고, 네트워크 복원 시 자동으로 순서대로 재실행함

---

## 싱글톤

```dart
class OfflineQueueManager {
  OfflineQueueManager._();
  static final instance = OfflineQueueManager._();
}
```

`main.dart`의 `_deferredInit()`에서 `initialize()` 호출

---

## `initialize`

```dart
Future<void> initialize()
```

1. `offline_queue.db` SQLite 데이터베이스 열기/생성
2. 대기 작업 수 갱신
3. `NetworkStatus.onStatusChange` 구독 시작 (네트워크 복원 시 큐 자동 처리)

### 큐 테이블 스키마

```sql
CREATE TABLE queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,        -- 'create_post' | 'create_comment'
  payload TEXT NOT NULL,     -- JSON 직렬화된 데이터
  createdAt INTEGER NOT NULL,
  retryCount INTEGER DEFAULT 0
)
```

---

## 큐 추가

### `enqueuePost`

```dart
Future<int> enqueuePost(Map<String, dynamic> postData)
```

글 작성 데이터를 큐에 저장. `FieldValue.serverTimestamp()` → `'__SERVER_TIMESTAMP__'` 플레이스홀더로 변환하여 JSON 직렬화

### `enqueueComment`

```dart
Future<int> enqueueComment(String postId, Map<String, dynamic> commentData)
```

댓글 데이터를 큐에 저장. `postId`와 `commentData`를 하나의 payload로 묶음

---

## 큐 처리

네트워크 복원 시 `_processQueue()` 자동 실행:

```
네트워크 복원 감지 (onStatusChange)
  │
  └── _processQueue()
       ├── 큐에서 가장 오래된 작업 조회 (FIFO)
       ├── 네트워크 끊기면 즉시 중단
       ├── 작업 실행 성공 → 큐에서 삭제
       ├── 작업 실행 실패
       │     ├── retryCount < 3 → 카운트 증가, 다음 연결 복원 시 재시도
       │     └── retryCount >= 3 → 큐에서 삭제 (드롭)
       └── 모든 작업 완료 → SyncStatus.idle()
```

### 지원 작업 타입

| type | 설명 | Firestore 실행 |
|------|------|----------------|
| `create_post` | 글 작성 | `posts.add(data)` |
| `create_comment` | 댓글 작성 | `comments.add(data)` + `commentCount` 증가 |

---

## 동기화 상태 스트림

```dart
Stream<SyncStatus> get onSyncStatusChange
int get pendingCount
```

`OfflineBanner`에서 구독하여 UI에 상태 표시

### SyncStatus

| 상태 | 의미 |
|------|------|
| `SyncState.idle` | 대기 작업 없음 |
| `SyncState.pending` | 대기 작업 있음 (네트워크 대기 중) |
| `SyncState.syncing` | 큐 처리 중 |

---

## 유틸리티

### `syncNow`

```dart
Future<void> syncNow()
```

수동 동기화 트리거. 온라인이면 즉시 큐 처리 시작

### `clearQueue`

```dart
Future<void> clearQueue()
```

모든 대기 작업 삭제

---

## ServerTimestamp 직렬화

`FieldValue.serverTimestamp()`는 JSON 직렬화가 불가하므로:

1. **저장 시** (`_sanitizeForStorage`): `FieldValue` → `'__SERVER_TIMESTAMP__'` 문자열
2. **실행 시** (`_restoreTimestamps`): `'__SERVER_TIMESTAMP__'` → `FieldValue.serverTimestamp()`

중첩 Map도 재귀적으로 처리
