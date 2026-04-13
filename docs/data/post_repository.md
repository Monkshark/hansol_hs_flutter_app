# PostRepository

> `lib/data/post_repository.dart` — 게시판 Firestore 데이터 접근 계층

게시글·댓글·신고 관련 Firestore CRUD를 싱글턴으로 중앙 집중. UI 코드에서 Firestore 직접 호출을 제거하고, 데이터 계층으로 분리

---

## 싱글턴

```dart
class PostRepository {
  PostRepository._();
  static final instance = PostRepository._();
}
```

`PostRepository.instance`로 접근. GetIt에 등록하지 않고 static 싱글턴 패턴 사용 (게시판 코드 전용이라 전역 DI 불필요)

---

## References

```dart
DocumentReference postRef(String postId)
CollectionReference commentsRef(String postId)
```

게시글/댓글 컬렉션 참조. `postStream`, `commentsStream`으로 실시간 스트림도 제공

---

## Read

### `baseQuery`

```dart
Query<Map<String, dynamic>> baseQuery({String? category})
```

카테고리별 게시글 쿼리. `category`가 null이면 전체, 있으면 `where('category', isEqualTo: category)` 필터. `createdAt` 내림차순

### `searchPosts`

```dart
Future<QuerySnapshot> searchPosts({required List<String> tokens, int limit = 50})
```

[n-gram 토큰](search_tokens.md)으로 검색. `array-contains-any` 쿼리, 기본 50건 fetch

### `myPostsStream` / `bookmarkedPostsStream`

```dart
Stream<QuerySnapshot> myPostsStream(String uid)
Stream<QuerySnapshot> bookmarkedPostsStream(String uid)
```

내가 쓴 글 / 저장한 글 스트림. 각각 최대 50건, `createdAt` 내림차순

---

## Create

### `createPost`

```dart
Future<DocumentReference> createPost(Map<String, dynamic> data)
```

게시글 생성. `_posts.add(data)`

### `addComment`

```dart
Future<DocumentReference> addComment(String postId, Map<String, dynamic> commentData)
```

댓글 추가 + `commentCount` 자동 증가 (`FieldValue.increment(1)`)

---

## Update

### `toggleLike` / `toggleDislike`

```dart
Future<void> toggleLike(String postId, String uid, {required bool hasLiked, required bool hasDisliked})
Future<void> toggleDislike(String postId, String uid, {required bool hasLiked, required bool hasDisliked})
```

좋아요/비추천 토글. `ensureLikesMap`으로 legacy 글 호환 후, `likes.$uid` + `likeCount` 를 단일 update로 처리. 좋아요↔비추천 상호 배타 처리 포함

### `votePoll`

```dart
Future<void> votePoll(String postId, String uid, int optionIndex)
```

투표. `pollVoters.$uid` 에 선택지 인덱스 저장

### `pinPost` / `unpinPost`

```dart
Future<void> pinPost(String postId)   // 최대 3개, 초과 시 StateError('pin_maxed')
Future<void> unpinPost(String postId)
```

공지 고정/해제. `pinPost`는 현재 고정된 글 수를 확인하여 3개 초과 시 `StateError` throw

### `resolvePost`

```dart
Future<void> resolvePost(String postId)
```

질문글 해결 처리. `isResolved: true`

### `toggleBookmark`

```dart
Future<void> toggleBookmark(String postId, String uid, bool isCurrentlyBookmarked)
```

북마크 토글. `bookmarkedBy` 배열에 uid 추가/제거

---

## `resolveAnonymousName`

```dart
Future<String> resolveAnonymousName(
  String postId, String uid,
  String authorLabel, String Function(int) anonymousNumLabel,
)
```

익명 댓글 번호 할당. **Firestore Transaction** 사용

1. 글 작성자면 → `authorLabel` 반환 (예: "익명(글쓴이)")
2. 기존 매핑 있으면 → 기존 번호 반환
3. 새 사용자면 → `anonymousCount + 1` 할당, `anonymousMapping` 업데이트

동시 댓글 시 번호 중복을 Transaction으로 방지

---

## Delete

### `deleteComment`

```dart
Future<void> deleteComment(String postId, String commentId)
```

댓글 삭제 + `commentCount` 감소

### `deletePost`

```dart
Future<void> deletePost(String postId)
```

게시글 삭제. **하위 댓글 먼저 전부 삭제** 후 게시글 문서 삭제 (cascade)

---

## Notification

### `sendNotification`

```dart
Future<void> sendNotification({
  required String targetUid,
  required String type,
  required String postId,
  required String postTitle,
  required String senderName,
  required String content,
})
```

대상 유저의 `users/{uid}/notifications` 서브컬렉션에 인앱 알림 문서 생성

---

## Admin / Utility

| 메서드 | 설명 |
|--------|------|
| `logAdminAction(data)` | `admin_logs` 컬렉션에 관리 행위 기록 |
| `refreshFromServer(postId)` | 게시글 + 댓글을 서버에서 강제 재조회 (캐시 우회) |
| `reportPost(...)` | `reports` 컬렉션에 신고 문서 생성 |
| `getPinnedCount()` | 현재 고정된 글 수 반환 |
| `getPinnedPosts()` | 고정된 글 목록 반환 |
| `ensureLikesMap(postId)` | legacy 글의 likes/dislikes 필드를 Map + int 구조로 backfill |

---

## 사용 위치

- **board_screen.dart**: `baseQuery`, `searchPosts`
- **post_detail_screen.dart**: 대부분의 메서드 (좋아요, 댓글, 북마크, 신고 등)
- **write_post_screen.dart**: `createPost`, `updatePost`, `getPinnedPosts`
- **my_posts_screen.dart**: `myPostsStream`
- **bookmarked_posts_screen.dart**: `bookmarkedPostsStream`
- **reports_tab.dart**: `deletePost`
