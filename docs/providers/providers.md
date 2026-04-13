# Providers

> `lib/providers/` — Riverpod Notifier/AsyncNotifier 전체

---

## auth_provider.dart

### `authStateProvider`

```dart
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
```

Firebase Auth 상태 스트림. 로그인/로그아웃 시 자동 갱신

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

`authStateProvider`를 watch → 로그인 상태 변경 시 자동 재조회

#### `refresh()`

```dart
Future<void> refresh() async {
  state = const AsyncLoading();
  AuthService.clearProfileCache();
  state = await AsyncValue.guard(() => AuthService.getUserProfile());
}
```

프로필 수정 후 호출. 캐시 초기화 + Firestore에서 새로 조회

#### `save(profile)`

```dart
Future<void> save(UserProfile profile) async {
  state = AsyncData(profile);                    // 낙관적 UI 업데이트
  await AuthService.saveUserProfile(profile);    // 서버 저장
  AuthService.clearProfileCache();
}
```

### 파생 Provider

| Provider | 타입 | 설명 |
|----------|------|------|
| `isLoggedInProvider` | `Provider<bool>` | `authStateProvider.user != null` |
| `isManagerProvider` | `Provider<bool>` | `profile?.isManager ?? false` |
| `isAdminProvider` | `Provider<bool>` | `profile?.isAdmin ?? false` |
| `isSuspendedProvider` | `Provider<bool>` | `profile?.isSuspended ?? false` |

---

## grade_provider.dart

### `ExamsNotifier` / `examsProvider`

```dart
class ExamsNotifier extends AsyncNotifier<List<Exam>> {
  @override
  Future<List<Exam>> build() => GradeManager.loadExams();
}
```

모든 mutator는 `await future`로 초기 build 완료를 보장한 뒤 직접 state를 갱신 (`invalidateSelf` race condition 회피). 데이터 저장은 [`GradeManager`](../data/grade_manager.md) 정적 메서드에 위임

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
await GradeManager.deleteExam(id);  // 낙관적: UI 먼저 갱신, 저장은 후처리
```

### `examsByTypeProvider`

```dart
final examsByTypeProvider = Provider.family<List<Exam>, ExamTab>((ref, tab) {
  final exams = ref.watch(examsProvider).valueOrNull ?? [];
  if (tab == 0) return exams.where((e) => e.type == 'midterm' || e.type == 'final').toList();
  return exams.where((e) => e.type == 'mock' || e.type == 'private_mock').toList();
});
```

탭 0 = 수시 (중간/기말), 탭 1 = 정시 (모의/사설)

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

수시 목표 등급 (과목명 → 등급 double)

### `JeongsiGoalsNotifier` / `jeongsiGoalsProvider`

정시 목표 백분위. `GoalsNotifier`와 동일 구조, `GradeManager.loadJeongsiGoals()` 사용

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

동기 `Notifier`. [SettingData](../data/setting_data.md) 싱글톤과 양방향 동기화

#### 메서드

| 메서드 | 설명 |
|--------|------|
| `setGrade(grade)` | 학년만 변경 |
| `setClassNum(classNum)` | 반만 변경 |
| `setBoth(grade, classNum)` | 학년+반 동시 변경 |

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

알림 설정 통합 상태. 각 setter(`setBreakfast`, `setLunch`, `setDinner`, `setBoard`)가 [SettingData](../data/setting_data.md)와 state를 동시에 갱신

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

인앱 언어 전환. `null` = 시스템 로캘, `Locale('ko')` = 한국어, `Locale('en')` = 영어. `HansolHighSchool` 루트 위젯에서 `ref.watch(localeProvider)` → `MaterialApp.locale`에 전달

### `AppRefreshNotifier` / `appRefreshProvider`

```dart
class AppRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() => state++;
}
```

`refresh()` 호출 시 카운터 증가 → `ValueKey(refreshKey)` 변경 → MainScreen 전체 재생성. 로그인/로그아웃/프로필 변경 후 호출

**비위젯 코드에서 접근**: `providerContainer.read(appRefreshProvider.notifier).refresh()`

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

`riverpod_annotation` (코드 생성) 기반. `keepAlive: true`로 Provider가 dispose되지 않음

인덱스 매핑: 0 = 라이트, 1 = 다크, 2 = 시스템
