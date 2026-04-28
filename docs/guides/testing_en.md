# Testing Strategy

> 한국어: [testing.md](./testing.md)

A 4-layer test setup (Unit + Provider + Widget + Golden + Firestore Rules), totalling **597 tests**.

## Snapshot

| Layer | Count | Characteristic |
|---|---|---|
| `test()` unit | 440 | models / utils / parsers / Provider / Repository / Golden — zero external deps |
| `testWidgets()` widget | 123 | UI verification with `ProviderScope.overrides` + mock notifier (incl. a11y) |
| Integration | 4 | `integration_test/` — app-level navigation E2E |
| Firestore Rules | 34 | `@firebase/rules-unit-testing` + emulator |
| **Total** | **563 Flutter + 34 Rules = 597** | |

> Measured: `grep -rE "^\s*test\(" test/` = 440, `grep -rE "^\s*testWidgets\(" test/` = 123, `integration_test/` = 4.

## Test Layout

```
test/
├── auth_repository_test.dart        # repository + mock injection
├── auth_service_test.dart
├── board_categories_test.dart
├── chat_id_test.dart
├── comment_input_bar_test.dart      # widget — incl. a11y tests
├── conflict_dialog_test.dart
├── dday_manager_test.dart
├── dday_manager_extended_test.dart
├── deep_link_service_test.dart
├── delete_alert_dialog_test.dart
├── error_snackbar_test.dart
├── error_view_test.dart
├── event_attach_card_test.dart
├── exceptions_test.dart
├── fcm_payload_test.dart
├── grade_manager_test.dart
├── grade_provider_test.dart         # provider test
├── grade_screen_widget_test.dart    # widget test
├── input_sanitizer_test.dart
├── link_card_a11y_test.dart         # widget — a11y only
├── meal_api_test.dart               # unit (Completer prefetch)
├── meal_card_allergy_test.dart
├── meal_data_api_test.dart
├── meal_subject_model_test.dart
├── meal_test.dart
├── network_status_test.dart
├── notice_api_test.dart
├── notice_data_api_test.dart
├── offline_queue_manager_test.dart
├── poll_card_test.dart
├── post_card_golden_test.dart       # golden
├── responsive_test.dart
├── schedule_data_test.dart
├── search_history_service_test.dart
├── search_tokens_test.dart          # unit (2-gram tokenizer)
├── secure_storage_service_test.dart # unit (migrateFromPlain)
├── setting_data_test.dart
├── skeleton_test.dart
├── timetable_api_test.dart
├── timetable_cell_test.dart
├── timetable_data_api_test.dart
├── timetable_parse_test.dart
├── today_banner_test.dart
├── user_profile_test.dart
├── version_compare_test.dart
├── vote_button_test.dart            # widget — a11y + behavior
├── widget_service_test.dart
├── widget_service_logic_test.dart
├── write_category_selector_test.dart
├── write_toggle_row_test.dart
├── helpers/                         # common mock utils
└── goldens/                         # golden PNG snapshots

tests/firestore-rules/               # rules emulator (Node.js)
integration_test/                    # e2e (optional)
```

> 53 test files total (excluding helpers/ and goldens/ directories).

## Layer Details

### 1. Unit (89)
- Model serialization (`freezed` / `json_serializable`), grade conversion, meal parsing
- Timetable period math, search tokenizer (2-gram), search history (SharedPreferences)
- secure_storage migration
- No external deps — file/network/time mocked

### 2. Provider (17)
- Build `ProviderContainer` → `await notifier.future` → assert state
- **Example**:
  ```dart
  final container = ProviderContainer(overrides: [
    gradeRepositoryProvider.overrideWithValue(FakeGradeRepository()),
  ]);
  addTearDown(container.dispose);

  final exams = await container.read(examsProvider.future);
  expect(exams, isNotEmpty);
  ```
- `addTearDown(container.dispose)` prevents ProviderContainer leaks ([Technical Challenge #12](./technical-challenges_en.md#12-non-deterministic-widget-test-timer-leak))

### 3. Widget (123 testWidgets)
- Inject mock notifiers via `ProviderScope(overrides: [...])`
- Cover loading / error / empty / success branches
- **Avoid timer leaks**: simulate indefinite loading with `Completer.future`, `complete()` at teardown
- **Accessibility (a11y) tests**: `link_card_a11y_test.dart`, `vote_button_test.dart` (a11y group), `comment_input_bar_test.dart` (a11y group) -- verify Semantics labels, tab order, and screen reader compatibility

### 4. Golden (5)
- `post_card_golden_test.dart` — 5 PostCard variants (default / liked / notice / +N badge / anon+manager view)
- Mock Firestore via `fake_cloud_firestore`
- **Tolerance comparator** absorbs platform font-rendering differences
- Refresh: `flutter test --update-goldens`

### 5. Repository (8)
- `setupServiceLocator()` + mocks, cover success/failure
- Demonstrates gradual DI migration ([ADR-07](./architecture-decisions_en.md#adr-07-di-getit--abstract-repository))

### 6. Firestore Rules (34)
- `tests/firestore-rules/` directory, Node.js
- `@firebase/rules-unit-testing` + Firestore emulator
- Scenarios:
  - Permission bypass (non-author editing posts, altering other profiles)
  - Counter ±1 delta enforcement (`validCounterDelta`)
  - Field forgery (non-author editing non-interaction fields)
  - Non-participant read/write on chats
  - Message content modification

## How to Run

### Flutter tests
```bash
# all
flutter test

# with coverage
flutter test --coverage

# update goldens
flutter test --update-goldens

# single file
flutter test test/search_tokens_test.dart

# filter
flutter test --name "2-gram"
```

### Rules tests
```bash
cd tests/firestore-rules
npm install
firebase emulators:exec --only firestore,auth --project hansol-test "npm test"
```

### Integration (optional)
```bash
flutter test integration_test/
```

## Mock / Fake Patterns

| Target | Approach |
|---|---|
| Firestore | `fake_cloud_firestore` |
| Firebase Auth | Mock + `setupServiceLocator` |
| Repository | Abstract + test implementation (GetIt injection) |
| AsyncNotifier | `ProviderScope.overrides` + mock notifier |
| Timer | `Completer` pattern ([Technical Challenge #12](./technical-challenges_en.md#12-non-deterministic-widget-test-timer-leak)) |
| HTTP | Test `Client` override |

## CI Integration

Two GitHub Actions workflows run in parallel:

1. `.github/workflows/flutter.yml` — `flutter analyze` + `flutter test --coverage` + Codecov + APK build on master push
2. `.github/workflows/firestore-rules.yml` — `firebase emulators:exec ... npm test` (Node 20, Java 21, path-triggered)

Details → [cicd-setup_en.md](./cicd-setup_en.md).

## Measured Times
- Flutter full suite (`flutter test`): 563 tests (`test` + `testWidgets`), local machine seconds~tens of seconds
- Integration (`integration_test/`): 4 tests, device/emulator required
- Rules: **~4s**, 34 tests, via `firebase emulators:exec`

## PIPA + Four-Tier Role Integration Scenarios (manual)

Not part of the automated test suite — this is a **pre-deploy manual checklist**. Prepare four test accounts (admin / manager / moderator / auditor / regular).

### Signup / consent flow
- [ ] New signup with terms + privacy + age-14 all checked → signup proceeds
- [ ] Terms / privacy unchecked → signup button disabled
- [ ] Under-14 checked → signup blocked with message

### Suspension + appeal (`appeals`)
- [ ] Manager suspends a regular user for 24h → user can't post or comment
- [ ] Suspended user opens `/appeal_screen` → submits reason → new `appeals` doc (`status: pending`)
- [ ] Manager reviews on Admin Web `/appeals` → approve → user's `suspendedUntil` cleared + `appeals.status = approved`
- [ ] Auditor opens `/appeals` → list visible, action buttons hidden

### Data rights (`data_requests`)
- [ ] User submits data request (access / portability / deletion) in-app → new `data_requests` doc
- [ ] Manager processes on Admin Web `/data-requests` → Function returns ZIP + signed URL → `status: completed`
- [ ] User can download via the link; verify expiry after 7 days

### Four-tier role permission matrix
- [ ] **moderator**: can delete posts/comments; `/users`, `/dashboard`, `/feedbacks` menus hidden
- [ ] **auditor**: can read `/admin-logs`, `/dashboard`, `/crashes`, `/feedbacks`, `/function-logs`; all writes blocked
- [ ] **manager**: can change roles (except granting admin), suspend / approve / delete users
- [ ] **admin**: can grant admin to others; sees a "Remove Admin" button on own row

### `admin_logs` records
- [ ] After each action confirm an entry on Admin Web `/admin-logs`:
  - `change_role` (with `previousRole`/`newRole`), `approve_user`, `reject_user`, `suspend_user` (with `hours`), `unsuspend_user`, `delete_user`, `delete_post`, `delete_comment`, `delete_feedback`
- [ ] `expiresAt` is exactly `createdAt + 30 days`
- [ ] (Blaze only) Entries past 30 days are auto-deleted by the TTL policy

### Community rules (`community_rules`)
- [ ] Manager publishes a new version on Admin Web `/community-rules` → new `community_rules` doc + version bump
- [ ] App detects the new version → re-consent dialog appears → user agrees → continues
- [ ] Without agreeing, the main UI is gated

Permission matrix details: [security_en.md](./security_en.md). Action log schema: [admin-features_en.md](../features/admin-features_en.md#audit-log-admin_logs).

## When Adding Tests
- New Riverpod provider → provider test mandatory
- New Firestore field/rule → rules test mandatory (regression guard)
- New board UI variant → consider golden test
- All async logic → use `Completer` / `addTearDown` to prevent leaks

## See Also
- [CI/CD Setup](./cicd-setup_en.md)
- [Architecture Decisions](./architecture-decisions_en.md)
- [Technical Challenges](./technical-challenges_en.md)
