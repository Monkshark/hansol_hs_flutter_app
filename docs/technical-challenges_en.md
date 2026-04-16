# Technical Challenges & Solutions

> 한국어: [technical-challenges.md](./technical-challenges.md)

14 engineering challenges hit during production operation, each with a *problem → solution → outcome* summary and related file paths.

## Contents

1. [Firebase Auth token propagation (Permission Denied)](#1-firebase-auth-token-propagation-permission-denied)
2. [Meal API concurrent-request race](#2-meal-api-concurrent-request-race-condition)
3. [Anonymous number consistency (concurrent write)](#3-anonymous-number-consistency-concurrent-write)
4. [Timetable elective slot conflicts](#4-timetable-elective-slot-conflicts)
5. [Firestore rules vs features (field-level validation)](#5-firestore-rules-vs-features-field-level-validation)
6. [Chat read-receipt realtime sync (dual stream)](#6-chat-read-receipt-realtime-sync-dual-stream)
7. [Per-category push toggles (server-side filter)](#7-per-category-push-toggles-server-side-filter)
8. [Auto-expiring suspensions (scheduler trigger)](#8-auto-expiring-suspensions-scheduler-trigger)
9. [Admin screen Firestore read overload (Stream → Future transition)](#9-admin-screen-firestore-read-overload-stream--future-transition)
10. [Account deletion ordering (Auth → Firestore permission loss)](#10-account-deletion-ordering-auth--firestore-permission-loss)
11. [Riverpod AsyncNotifier race condition (invalidateSelf)](#11-riverpod-asyncnotifier-race-condition-invalidateself)
12. [Non-deterministic widget test timer leak](#12-non-deterministic-widget-test-timer-leak)
13. [StatefulWidget 1,400+ lines → Stateless composition (refactoring)](#13-statefulwidget-1400-lines--stateless-composition-refactoring)
14. [Repository + GetIt gradual migration](#14-repository--getit-gradual-migration)

---

## 1. Firebase Auth token propagation (Permission Denied)

**Problem:** Right after a social login, querying Firestore threw PERMISSION_DENIED — the auth token hadn't propagated to the Firestore SDK yet.

**Fix:** `getIdToken(true)` to force-refresh + retry up to 3 times so first-install / re-login flows reliably fetch the profile.

**Related:** `lib/screens/auth/login_screen.dart`, `lib/screens/auth/profile_setup_screen.dart`

---

## 2. Meal API concurrent-request race condition

**Problem:** Multiple screens requested the same month's meals simultaneously → duplicate API calls.

**Fix:** `Completer` pattern coalesces same-month prefetches into a single Future; in-flight requests share it.

**Outcome:** API calls dropped **30 → 1**.

**Related:** `lib/api/meal_api.dart` (expected), `test/meal_api_test.dart`

---

## 3. Anonymous number consistency (concurrent write)

**Problem:** If the client assigned anonymous numbers, simultaneous comments could collide on the same number.

**Fix:** Firestore Transaction atomically reads/writes `anonymousMapping` / `anonymousCount` on the post doc, preventing collisions. The author is always labeled "익명(글쓴이)" (`anonymous (author)`).

**Related:** `lib/screens/board/post_detail_screen.dart`, `firestore.rules` (`isInteractionUpdate` covers `anonymousMapping`)

---

## 4. Timetable elective slot conflicts

**Problem:** 2nd/3rd-year electives could overlap with another class in the same slot.

**Fix:** Build-time per-slot conflict detection → user-facing dialog to choose, with the choice stored locally to prevent recurrence.

**Related:** `lib/screens/sub/timetable_view_screen.dart`, `timetable_select_screen.dart`

---

## 5. Firestore rules vs features (field-level validation)

**Problem:** Restricting `posts.update` to authors blocks other users from voting / upvoting.

**Fix:** `request.resource.data.diff(resource.data).affectedKeys().hasOnly([...])` for field-level validation — non-authors can only change interaction fields. `validCounterDelta(field)` enforces `likeCount` / etc. ±1 delta.

**Related:** `firestore.rules` (`isInteractionUpdate`, `validCounterDelta`), `tests/firestore-rules/`

---

## 6. Chat read-receipt realtime sync (dual stream)

**Problem:** Tracking read state separately from the message stream meant extra Firestore reads.

**Fix:** Watch `chats/{id}.unreadCount` via a dedicated `StreamBuilder` — one doc stream delivers read state in realtime.

**Related:** `lib/screens/chat/chat_room_screen.dart`, `chat_list_screen.dart`

---

## 7. Per-category push toggles (server-side filter)

**Problem:** FCM pushes are server-triggered, so clients can't toggle categories on/off locally.

**Fix:** Store `notiComment`, `notiReply`, `notiChat`, … booleans on `users/{uid}`. Cloud Functions check them before sending; skip if `false`.

**Related:** `functions/index.js`, `lib/screens/sub/notification_setting_screen.dart`

---

## 8. Auto-expiring suspensions (scheduler trigger)

**Problem:** Even after `suspendedUntil` expired, the field lingered and `onUserUpdated` didn't fire, so no unsuspension push.

**Fix:** Hourly Cloud Functions scheduler queries `suspendedUntil <= now` and deletes the field → `onUserUpdated` triggers → unsuspension push.

**Related:** `functions/index.js` (`suspensionScheduler`)

---

## 9. Admin screen Firestore read overload (Stream → Future transition)

**Problem:** Admin screen watched users/reports/logs live via `StreamBuilder`, so opening it alone produced 130+ reads; every data change re-queried everything.

**Fix:** Switched to `FutureBuilder` — one read on open + manual `_refresh()` after actions (approve/delete). `ExpansionTile` children render only when expanded; collapsed tabs do 0 reads.

**Outcome:** **130 → 20–30 reads**.

**Related:** `lib/screens/board/admin_screen.dart`, `admin/users_tab.dart`

---

## 10. Account deletion ordering (Auth → Firestore permission loss)

**Problem:** Calling `user.delete()` signs out Firebase Auth immediately — any subsequent Firestore deletes fail with PERMISSION_DENIED.

**Fix:** Delete Firestore docs first (while still authed), then Auth. Save `uid` in a local variable to keep the reference after auth is gone.

**Related:** `lib/screens/sub/setting_screen.dart`, `lib/screens/auth/profile_edit_screen.dart`

---

## 11. Riverpod AsyncNotifier race condition (invalidateSelf)

**Problem:** `ExamsNotifier.add()` / `delete()` called `ref.invalidateSelf()` to reload — provider tests flaked intermittently. Invalidate is async, so a following `read()` returned the *old* state.

**Fix:** Inside mutators, `final current = await future;` → mutate store → `state = AsyncData([...current, exam])`. Removed `invalidateSelf`. Applied the same pattern to `GoalsNotifier` / `JeongsiGoalsNotifier`.

**Related:** `lib/providers/grade_provider.dart`, `test/grade_provider_test.dart`

---

## 12. Non-deterministic widget test timer leak

**Problem:** `_LoadingExamsNotifier` mocked eternal loading with `await Future.delayed(Duration(seconds: 30))` — `flutter test` failed "A Timer is still pending even after the widget tree was disposed".

**Fix:** `Completer<List<Exam>>` pattern — the Future can be externally completed, so tests explicitly `complete()` at teardown. Provider tests use `addTearDown(container.dispose)` to plug container leaks.

**Related:** `test/grade_screen_widget_test.dart`, `test/helpers/`

---

## 13. StatefulWidget 1,400+ lines → Stateless composition (refactoring)

**Problem:** `post_detail_screen.dart` (1,442), `admin_screen.dart` (1,071), `write_post_screen.dart` (1,119), `timetable_view_screen.dart` (943) — all sub-widgets were private classes / `_buildXxx` methods in one file. Readability, reusability, testability all suffered; even `grep` for reuse points was hard.

**Fix:** Two patterns:
1. **Private class → public StatelessWidget** — extracted `_PollCard` / `_VoteButton` / `_CommentItem` / `_EventAttachCard` from `post_detail_screen`, 5 tab classes from `admin_screen`, dialogs / Painters from `timetable_view`, etc. Moved to separate files, dropped `_` prefix.
2. **State-dependent builder methods → callback-parameter widgets** — `write_post_screen`'s `_buildEventForm` / `_buildPollForm` / `_buildImageSection` accessed state directly; converted to Stateless widgets that accept explicit callbacks (`onPickDate`, `onAddOption`, `onReorder`, …).

**Outcome:** 4 screens **4,575 → 2,589 lines (-43%)**, split into 15 widget modules, 113 tests all still passing (zero regression).

**Related:** `lib/screens/board/widgets/`, `lib/screens/board/write_widgets/`, `lib/screens/board/admin/`, `lib/screens/sub/timetable_widgets/`

---

## 14. Repository + GetIt gradual migration

**Problem:** `AuthService` / `GradeManager` were static methods scattered across 25+ call sites — switching to DI in one shot meant editing everything at once, regression risk high.

**Fix:** Introduced abstract `AuthRepository` / `GradeRepository` interfaces with `FirebaseAuthRepository` / `LocalGradeRepository` delegating to the old static methods. New code pulls via `GetIt.I<AuthRepository>()`; old call sites left untouched. Tests inject mocks through `setupServiceLocator()` / `resetServiceLocator()` → incremental migration + backward compatibility simultaneously.

**Related:** `test/auth_repository_test.dart`, `test/auth_service_test.dart`, `test/grade_manager_test.dart`

---

## See Also
- [Architecture Decisions](./architecture-decisions_en.md) — design background for each challenge
- [Testing Strategy](./testing_en.md) — regression-proof test layers
