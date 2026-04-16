# Community Features (Board / Chat / Notifications)

> 한국어: [community-features.md](./community-features.md)

Features where students, teachers, alumni, and parents communicate — board, 1:1 chat, notification system.

## Board

### Categories & Browsing

- **6 categories** + **Popular** tab: Free / Question / Info-share / Lost & Found / Student Council / Clubs
- **Popular sorted** by denormalized `likeCount` + composite index `(likeCount desc, createdAt desc)` ([ADR-04](../guides/architecture-decisions_en.md#adr-04-like-counter-mapuidbool--denormalized-int))
- **Cursor-based pagination** (20 per page, infinite scroll, pull-to-refresh)
- **Pinned announcements** (up to 3, admin-only, always on top)

### Composition / Body

- **Image attachment**: 1080px compressed + EXIF/GPS stripped, PageView swipe viewer + Hero animation + pinch-zoom
- **Polls** (up to 6 options, real-time result bars)
- **Schedule sharing** (links to academic events)
- **Anonymous numbering**: 익명1/익명2/익명(글쓴이), via Firestore Transaction ([Technical Challenge #3](../guides/technical-challenges_en.md#3-anonymous-number-consistency-concurrent-write))

### Interactions

- **Upvote/downvote**: `Map<uid,bool>` + `likeCount` int counter, ±1 delta enforced in rules ([ADR-04](../guides/architecture-decisions_en.md#adr-04-like-counter-mapuidbool--denormalized-int))
- **Bookmark** (re-accessible under My Activity → Saved)
- **Comments + replies** (indented), author-of-post comments badged blue

### Search

- **n-gram search**: title+body 2-gram indexed into `searchTokens`, `array-contains-any` query ([ADR-03](../guides/architecture-decisions_en.md#adr-03-board-search-client-side-n-gram-indexing))
- **350ms debounce**, 50-result fetch + client substring filter reduces false positives
- **Search history**: last 10 keyword chips, delete individually or all

### UX

- Shimmer skeleton loading
- **Bottom-sheet menu** (icon + text, delete/report highlighted red)
- Reports, user blocking, auto-delete (TTL), rate limiting

### My Activity

- My posts / my comments / saved tabs
- Uses `authorUid + createdAt` composite index

**Files**: `lib/screens/board/board_screen.dart`, `post_detail_screen.dart`, `write_post_screen.dart`, `my_posts_screen.dart`, `bookmarked_posts_screen.dart`, `search_history_service_test.dart`, `search_tokens_test.dart`

## 1:1 Chat

- **User search** to start a chat (by name/student ID; admins shown by default)
- **Realtime messages** (Firestore `onSnapshot`, limit 30)
- **Read receipts** + unread badge ([Technical Challenge #6](../guides/technical-challenges_en.md#6-chat-read-receipt-realtime-sync-dual-stream))
- **Message deletion**: self only / for both (if unread and ≤1h old)
- **Leave chat**: system message + other party's view retained
- Skeleton loading UI

**Security**: rules enforce `participants` array → read/write participants only.

**Files**: `lib/screens/chat/chat_list_screen.dart`, `chat_room_screen.dart`, `chat_utils.dart`

## Notifications

### Settings Screen

Five independent toggles:

| Category | Trigger | Path |
|---|---|---|
| **Comments/replies** | Comment on my post / reply to my comment | Cloud Functions → FCM |
| **Chat** | New message | Cloud Functions → FCM |
| **New posts** | New post in subscribed categories | Cloud Functions → FCM |
| **Account** | Approval / suspension / unsuspension / role change | Cloud Functions → FCM |
| **Meals** | Breakfast/lunch/dinner | Local notifications (per-meal time) |

### Implementation

- **In-app notifications**: bell icon + unread badge (`users/{uid}/notifications/{id}`)
- **FCM push**: 4 FCM topics (`account` / `comment` / `new_post` / `chat`) + 3 local (breakfast/lunch/dinner)
- **Server-side filtering**: Cloud Functions check `users/{uid}.notiXxx` before sending ([Technical Challenge #7](../guides/technical-challenges_en.md#7-per-category-push-toggles-server-side-filter))
- **Auto-unsuspension**: Cloud Functions scheduler (hourly) ([Technical Challenge #8](../guides/technical-challenges_en.md#8-auto-expiring-suspensions-scheduler-trigger))

**Files**: `lib/notification/fcm_service.dart`, `lib/screens/sub/notification_setting_screen.dart`, `lib/screens/board/notification_screen.dart`, `functions/index.js`

## Feedback

- **App feedback & bug reports** + **student-council feedback** (two channels)
- Text (1000 chars) + up to 3 photos
- State machine: pending → acknowledged → resolved → deleted (logged)
- Admin Web changes state

**Files**: `lib/screens/sub/feedback_screen.dart`, `feedback_list_screen.dart`

## Rate Limiting

| Target | Limit |
|---|---|
| Post creation | 30s cooldown |
| Comment creation | 10s cooldown |
| Report | dedup index on `(postId, reporterUid)` |
| Chat messages | (client-side debounce) |

Client-side front-loaded; Firestore rules carry only minimal validation.

## See Also
- [Public Features](./public-features_en.md)
- [Personal Features](./personal-features_en.md)
- [Admin Features](./admin-features_en.md)
- [Security Model](../guides/security_en.md)
- [Data Model](../guides/data-model_en.md) — `posts`, `comments`, `chats`, `reports`
