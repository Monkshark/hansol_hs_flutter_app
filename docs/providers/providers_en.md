# Providers

> 한국어: [providers.md](./providers.md)

> `lib/providers/` — All Riverpod Notifier / AsyncNotifier providers

---

## auth_provider.dart

### `authStateProvider`

```dart
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
```

Firebase Auth state stream. Automatically refreshes on login/logout.

### `UserProfileNotifier` / `userProfileProvider`

```dart
class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      data: (user) async => user == null ? null : AuthService.getUserProfile(),
      loading: () => null,
      error: (_, __) => null,
    );
  }
}
```

Watches `authStateProvider` → automatically re-fetches whenever the login state changes.

#### `refresh()`

```dart
Future<void> refresh() async {
  state = const AsyncLoading();
  AuthService.clearProfileCache();
  state = await AsyncValue.guard(() => AuthService.getUserProfile());
}
```

Called after editing the profile. Clears the cache + re-fetches from Firestore.

#### `save(profile)`

```dart
Future<void> save(UserProfile profile) async {
  state = AsyncData(profile);                    // optimistic UI update
  await AuthService.saveUserProfile(profile);    // save to server
  AuthService.clearProfileCache();
}
```

### Derived providers

| Provider | Type | Description |
|----------|------|-------------|
| `isLoggedInProvider` | `Provider<bool>` | `authStateProvider.user != null` |
| `isManagerProvider` | `Provider<bool>` | `profile?.isManager ?? false` (manager + admin) |
| `isAdminProvider` | `Provider<bool>` | `profile?.isAdmin ?? false` |
| `isStaffProvider` | `Provider<bool>` | `profile?.isStaff ?? false` (admin + manager + moderator + auditor) |
| `isSuspendedProvider` | `Provider<bool>` | `profile?.isSuspended ?? false` |
| `isVerifiedProvider` | `Provider<bool>` | `profile?.isVerified ?? false` |
| `canWriteProvider` | `Provider<bool>` | `profile?.canWrite ?? false` (verified && !suspended) |

---

## grade_provider.dart

### `ExamsNotifier` / `examsProvider`

```dart
class ExamsNotifier extends AsyncNotifier<List<Exam>> {
  @override
  Future<List<Exam>> build() => GradeManager.loadExams();
}
```

All mutators use `await future` to guarantee initial build completion, then update state directly (avoiding the `invalidateSelf` race condition). Data storage is delegated to [`GradeManager`](../data/grade_manager.md) static methods.

#### `add(exam)`

```dart
Future<void> add(Exam exam) async {
  final current = await future;
  await GradeManager.addExam(exam);
  state = AsyncData([...current, exam]);
}
```

#### `updateExam(exam)`

```dart
state = AsyncData([
  for (final e in current) if (e.id == exam.id) exam else e,
]);
```

#### `delete(id)`

```dart
state = AsyncData(current.where((e) => e.id != id).toList());
await GradeManager.deleteExam(id);  // optimistic: update UI first, persist afterwards
```

### `examsByTypeProvider`

```dart
final examsByTypeProvider = Provider.family<List<Exam>, ExamTab>((ref, tab) {
  final exams = ref.watch(examsProvider).valueOrNull ?? [];
  if (tab == 0) return exams.where((e) => e.type == 'midterm' || e.type == 'final').toList();
  return exams.where((e) => e.type == 'mock' || e.type == 'private_mock').toList();
});
```

Tab 0 = Susi (midterm/final), Tab 1 = Jeongsi (mock/private mock).

### `GoalsNotifier` / `goalsProvider`

```dart
class GoalsNotifier extends AsyncNotifier<Map<String, double>> {
  @override
  Future<Map<String, double>> build() => GradeManager.loadGoals();

  Future<void> save(Map<String, double> goals) async {
    await future;
    await GradeManager.saveGoals(goals);
    state = AsyncData(goals);
  }
}
```

Susi target grades (subject name → grade double).

### `JeongsiGoalsNotifier` / `jeongsiGoalsProvider`

Jeongsi target percentiles. Same structure as `GoalsNotifier`, using `GradeManager.loadJeongsiGoals()`.

---

## settings_provider.dart

### `GradeClassNotifier` / `gradeClassProvider`

```dart
class GradeClassNotifier extends Notifier<GradeClassState> {
  @override
  GradeClassState build() => GradeClassState(
    grade: SettingData().grade,
    classNum: SettingData().classNum,
  );
}
```

Synchronous `Notifier`. Bidirectionally synced with the [SettingData](../data/setting_data.md) singleton.

#### Methods

| Method | Description |
|--------|-------------|
| `setGrade(grade)` | Changes the grade only |
| `setClassNum(classNum)` | Changes the class number only |
| `setBoth(grade, classNum)` | Changes both grade and class number at once |

### `NotificationSettingsNotifier` / `notificationSettingsProvider`

```dart
class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    final s = SettingData();
    return NotificationSettings(
      breakfast: s.isBreakfastNotificationOn,
      breakfastTime: s.breakfastTime,
      // ... lunch, dinner, board
    );
  }
}
```

Unified notification settings state. Each setter (`setBreakfast`, `setLunch`, `setDinner`, `setBoard`) updates both [SettingData](../data/setting_data.md) and state at the same time.

### `LocaleNotifier` / `localeProvider`

```dart
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = SettingData().localeCode;
    return code.isEmpty ? null : Locale(code);
  }

  void setLocale(Locale? locale) {
    SettingData().localeCode = locale?.languageCode ?? '';
    state = locale;
  }
}
```

In-app language switcher. `null` = system locale, `Locale('ko')` = Korean, `Locale('en')` = English. The root `HansolHighSchool` widget does `ref.watch(localeProvider)` → passes it to `MaterialApp.locale`.

### `AppRefreshNotifier` / `appRefreshProvider`

```dart
class AppRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() => state++;
}
```

When `refresh()` is called, the counter increments → `ValueKey(refreshKey)` changes → the entire MainScreen is rebuilt. Called after login/logout/profile changes.

**Access from non-widget code**: `providerContainer.read(appRefreshProvider.notifier).refresh()`.

---

## theme_provider.dart

### `Theme` / `themeProvider`

```dart
@Riverpod(keepAlive: true)
class Theme extends _$Theme {
  @override
  ThemeMode build() => _indexToMode(SettingData().themeModeIndex);

  void setMode(int index) {
    SettingData().themeModeIndex = index;
    state = _indexToMode(index);
  }
}
```

Based on `riverpod_annotation` (code generation). `keepAlive: true` ensures the provider is not disposed.

Index mapping: 0 = Light, 1 = Dark, 2 = System.
