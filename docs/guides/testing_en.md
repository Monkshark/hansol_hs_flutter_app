# Testing Strategy

> 한국어: [testing.md](./testing.md)

A 4-layer test setup (Unit + Provider + Widget + Golden + Firestore Rules), totalling **558 tests**.

## Snapshot

| Layer | Count | Characteristic |
|---|---|---|
| `test()` unit | 440 | models / utils / parsers / Provider / Repository / Golden — zero external deps |
| `testWidgets()` widget | 80 | UI verification with `ProviderScope.overrides` + mock notifier |
| Integration | 4 | `integration_test/` — app-level navigation E2E |
| Firestore Rules | 34 | `@firebase/rules-unit-testing` + emulator |
| **Total** | **524 Flutter + 34 Rules = 558** | |

> Measured: `grep -rE "^\s*test\(" test/` = 440, `grep -rE "^\s*testWidgets\(" test/` = 80, `integration_test/` = 4.

## Test Layout

```
test/
├── auth_repository_test.dart       # repository + mock injection
├── auth_service_test.dart
├── dday_manager_test.dart
├── grade_manager_test.dart
├── grade_provider_test.dart        # provider test
├── grade_screen_widget_test.dart   # widget test
├── meal_api_test.dart              # unit (Completer prefetch)
├── meal_test.dart
├── post_card_golden_test.dart      # golden
├── schedule_data_test.dart
├── search_history_service_test.dart
├── search_tokens_test.dart         # unit (2-gram tokenizer)
├── secure_storage_service_test.dart# unit (migrateFromPlain)
├── timetable_api_test.dart
├── widget_service_test.dart
├── helpers/                        # common mock utils
└── goldens/                        # golden PNG snapshots

tests/firestore-rules/              # rules emulator (Node.js)
integration_test/                   # e2e (optional)
```

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

### 3. Widget (17)
- Inject mock notifiers via `ProviderScope(overrides: [...])`
- Cover loading / error / empty / success branches
- **Avoid timer leaks**: simulate indefinite loading with `Completer.future`, `complete()` at teardown

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
- Flutter full suite (`flutter test`): 520 tests (`test` + `testWidgets`), local machine seconds~tens of seconds
- Integration (`integration_test/`): 4 tests, device/emulator required
- Rules: **~4s**, 34 tests, via `firebase emulators:exec`

## When Adding Tests
- New Riverpod provider → provider test mandatory
- New Firestore field/rule → rules test mandatory (regression guard)
- New board UI variant → consider golden test
- All async logic → use `Completer` / `addTearDown` to prevent leaks

## See Also
- [CI/CD Setup](./cicd-setup_en.md)
- [Architecture Decisions](./architecture-decisions_en.md)
- [Technical Challenges](./technical-challenges_en.md)
