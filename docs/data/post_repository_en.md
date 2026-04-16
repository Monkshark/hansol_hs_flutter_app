# PostRepository

> 한국어: [post_repository.md](./post_repository.md)

> `lib/data/post_repository.dart` — Firestore data access layer for the board

Centralizes Firestore CRUD for posts, comments, and reports as a singleton. Removes direct Firestore calls from UI code and isolates them in the data layer.

---

## Singleton

```dart
class PostRepository {
  PostRepository._();
  static final instance = PostRepository._();
}
```

Accessed via `PostRepository.instance`. Uses a static singleton pattern instead of GetIt registration (board code only; no need for global DI).

---

## References

```dart
DocumentReference postRef(String postId)
CollectionReference commentsRef(String postId)
```

Post/comment collection references. `postStream` and `commentsStream` also provide real-time streams.

---

## Read

### `baseQuery`

```dart
Query<Map<String, dynamic>> baseQuery({String? category})
```

Per-category post query. When `category` is null, returns all posts; otherwise applies `where('category', isEqualTo: category)`. Ordered by `createdAt` descending.

### `searchPosts`

```dart
Future<QuerySnapshot> searchPosts({required List<String> tokens, int limit = 50})
```

Searches with [n-gram tokens](search_tokens.md). Uses `array-contains-any` query, fetches 50 by default.

### `myPostsStream` / `bookmarkedPostsStream`

```dart
Stream<QuerySnapshot> myPostsStream(String uid)
Stream<QuerySnapshot> bookmarkedPostsStream(String uid)
```

Streams for my posts / bookmarked posts. Each limited to 50, ordered by `createdAt` descending.

---

## Create

### `createPost`

```dart
Future<DocumentReference?> createPost(Map<String, dynamic> data)
```

Creates a post. When offline, saves to [`OfflineQueueManager`](../network/offline_queue_manager.md) and returns `null`. When online, runs `_posts.add(data)`.

### `addComment`

```dart
Future<DocumentReference?> addComment(String postId, Map<String, dynamic> commentData)
```

Adds a comment and automatically increments `commentCount` (`FieldValue.increment(1)`). When offline, queues it and returns `null`.

---

## Update

### `toggleLike` / `toggleDislike`

```dart
Future<void> toggleLike(String postId, String uid, {required bool hasLiked, required bool hasDisliked})
Future<void> toggleDislike(String postId, String uid, {required bool hasLiked, required bool hasDisliked})
```

Toggles like/dislike. After `ensureLikesMap` for legacy-post compatibility, updates `likes.$uid` + `likeCount` in a single update. Includes mutual-exclusion handling between like and dislike.

### `votePoll`

```dart
Future<void> votePoll(String postId, String uid, int optionIndex)
```

Cast a vote. Stores the selected option index under `pollVoters.$uid`.

### `pinPost` / `unpinPost`

```dart
Future<void> pinPost(String postId)   // up to 3; throws StateError('pin_maxed') when exceeded
Future<void> unpinPost(String postId)
```

Pin/unpin announcements. `pinPost` checks the current pinned count and throws `StateError` when more than 3.

### `resolvePost`

```dart
Future<void> resolvePost(String postId)
```

Marks a question post as resolved. `isResolved: true`.

### `toggleBookmark`

```dart
Future<void> toggleBookmark(String postId, String uid, bool isCurrentlyBookmarked)
```

Toggles bookmark. Adds/removes the uid to/from the `bookmarkedBy` array.

---

## `resolveAnonymousName`

```dart
Future<String> resolveAnonymousName(
  String postId, String uid,
  String authorLabel, String Function(int) anonymousNumLabel,
)
```

Allocates anonymous comment numbers. Uses a **Firestore Transaction**.

1. If the caller is the post author → returns `authorLabel` (e.g., "Anonymous (author)")
2. If an existing mapping exists → returns the existing number
3. If it's a new user → allocates `anonymousCount + 1` and updates `anonymousMapping`

The transaction prevents number collisions when comments are posted concurrently.

---

## Delete

### `deleteComment`

```dart
Future<void> deleteComment(String postId, String commentId)
```

Deletes a comment and decrements `commentCount`.

### `deletePost`

```dart
Future<void> deletePost(String postId)
```

Deletes a post. **Deletes all child comments first**, then deletes the post document (cascade).

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

Creates an in-app notification document in the target user's `users/{uid}/notifications` subcollection.

---

## Admin / Utility

| Method | Description |
|--------|-------------|
| `logAdminAction(data)` | Records admin actions in the `admin_logs` collection |
| `refreshFromServer(postId)` | Force-refetches the post + comments from the server (bypassing cache) |
| `reportPost(...)` | Creates a report document in the `reports` collection |
| `getPinnedCount()` | Returns the current pinned post count |
| `getPinnedPosts()` | Returns the list of pinned posts |
| `ensureLikesMap(postId)` | Backfills legacy posts' likes/dislikes fields into the Map + int structure |

---

## Usage

- **board_screen.dart**: `baseQuery`, `searchPosts`
- **post_detail_screen.dart**: most methods (like, comment, bookmark, report, etc.)
- **write_post_screen.dart**: `createPost`, `updatePost`, `getPinnedPosts`
- **my_posts_screen.dart**: `myPostsStream`
- **bookmarked_posts_screen.dart**: `bookmarkedPostsStream`
- **reports_tab.dart**: `deletePost`
