# Main

> `lib/main.dart` — 앱 진입점, MainScreen

---

## `main()`

```dart
Future<void> main() async
```

**설명**: 앱 초기화를 수행함. 속도 최적화를 위해 `runApp` 전에는 UI에 필수적인 초기화만 수행하고, 나머지는 `_deferredInit()`으로 백그라운드 처리함

### runApp 전 (필수 초기화)

1. **Firebase 초기화**: 중복 방지 체크 후 초기화
2. **Crashlytics**: FlutterError 핸들러 + Firestore `crash_logs` 컬렉션에 에러 기록
3. **Kakao SDK** 초기화
4. **Timezone** 초기화 (`Asia/Seoul`)
5. `providerContainer = ProviderContainer()` 생성
6. **[SettingData](data/setting_data.md)** + **[ServiceLocator](data/service_locator.md)** 병렬 초기화:
   ```dart
   await Future.wait([SettingData().init(), setupServiceLocator()]);
   ```
7. `runApp` → `UncontrolledProviderScope`로 감싼 `HansolHighSchool` 위젯 실행

### runApp 후 (`_deferredInit`)

UI가 뜬 뒤 `unawaited(_deferredInit())`로 나머지 초기화를 백그라운드 실행:

1. **App Check** / **Performance Monitoring** — 각각 `_safeInit()`으로 fire-and-forget
1. **Analytics** — `SharedPreferences('analyticsEnabled')` 값과 릴리스 모드 여부를 확인하여, 두 조건 모두 충족할 때만 수집 활성화. 이후 `AnalyticsService.logAppOpen(source: 'organic')` 호출
2. **과목 데이터 프리로드** (2학년, 3학년 병렬)
3. **로컬 급식 알림** 초기화 + 스케줄링
4. **FCM** 초기화 + **딥링크** 초기화 + **위젯 서비스** 초기화 (fire-and-forget)
5. **[OfflineQueueManager](network/offline_queue_manager.md)** 초기화 — sqflite DB 열기 + 네트워크 복원 리스너 등록

### `_safeInit`

```dart
Future<void> _safeInit(String name, Future<void> Function() fn) async
```

try/catch 래퍼. 개별 초기화 실패가 앱 전체를 막지 않도록 에러를 로그만 남기고 무시함

---

## 전역 상태

| 변수 | 타입 | 용도 |
|------|------|------|
| `providerContainer` | `ProviderContainer` | 비위젯 코드에서 Riverpod provider 접근용 (login_screen, setting_screen 등) |
| `rootNavigatorKey` | `GlobalKey<NavigatorState>` | FCM 딥링크에서 Navigator 접근용 |
| `notificationStream` | `StreamController<String?>` | 알림 탭 → MealScreen 전환용 |

> 기존 `themeNotifier`, `localeNotifier`, `appRefreshNotifier` (ValueNotifier 3개)는 Riverpod provider로 통일됨 → [providers 문서](providers/providers.md) 참조

---

## `HansolHighSchool` (루트 위젯)

```dart
class HansolHighSchool extends ConsumerStatefulWidget
```

**설명**: 앱의 루트 위젯. 테마 모드 전환과 MaterialApp 설정을 담당

1. `initState`에서 [`AnimatedAppColors`](styles/app_colors.md) 초기화
2. `_resolveIsDark`: ThemeMode.system일 때 platformBrightness 확인
3. `build`에서 3개 provider를 watch:

```dart
final mode = ref.watch(themeProvider);
final locale = ref.watch(localeProvider);
final refreshKey = ref.watch(appRefreshProvider);

return MaterialApp(
  navigatorKey: rootNavigatorKey,
  locale: locale,  // null이면 시스템 로캘 사용
  theme: _lightTheme,
  darkTheme: _darkTheme,
  themeMode: mode,
  home: MainScreen(key: ValueKey(refreshKey)),
);
```

`appRefreshProvider` 값 변경 → `ValueKey` 변경 → MainScreen 재생성

---

## `MainScreen`

```dart
class MainScreen extends StatefulWidget
```

**설명**: 급식/홈/일정 3탭 하단 네비게이션 + 초기 체크 로직

### `initState` 체크 순서

1. `_checkAccountExists()`: 프로필이 없으면 로그아웃 (삭제된 계정 처리)
2. `_checkNewSemester()`: 학기 변경 시 프로필 업데이트 안내 + 선택과목/시간표 캐시 초기화
3. 온보딩 미완료 시 → `OnboardingScreen`
4. 비로그인 시 → `LoginScreen`
5. 로그인 상태면 Firestore에서 일정 복원: `GetIt.I<LocalDataBase>().loadFromFirestore()`
6. [`UpdateChecker`](notification/update_checker.md)`.check()` + [`PopupNotice`](notification/popup_notice.md)`.check()`

### 네비게이션

```dart
_pages = [const MealScreen(), HomeScreen(key: _homeKey), const NoticeScreen()];
```

- `PageView` + `NavigationBar` (아이콘 only, 라벨 숨김)
- 홈 탭 전환 시 `_homeKey.currentState?.refresh()` 호출
- 알림 탭 (`meal_screen` payload) → 급식 탭으로 이동

---

## `_logCrashToFirestore`

```dart
void _logCrashToFirestore(FlutterErrorDetails details)
```

Firestore `crash_logs` 컬렉션에 에러 정보 저장. 에러 메시지 500자, 스택 1000자로 절삭
