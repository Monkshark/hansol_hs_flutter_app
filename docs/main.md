# Main

> `lib/main.dart` — 앱 진입점, MainScreen

---

## `main()`

```dart
Future<void> main() async
```

**설명**: 앱 초기화를 수행한다

1. **Firebase 초기화**: 중복 방지 체크 후 초기화:
   ```dart
   if (Firebase.apps.isEmpty) {
     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   }
   ```

2. **App Check**: 릴리스 빌드는 Play Integrity, 디버그는 debug provider:
   ```dart
   androidProvider: const bool.fromEnvironment('dart.vm.product')
       ? AndroidProvider.playIntegrity
       : AndroidProvider.debug,
   ```

3. **Performance Monitoring** + **Analytics** 활성화

4. **Crashlytics**: FlutterError 핸들러 + Firestore `crash_logs` 컬렉션에 에러 기록:
   ```dart
   FlutterError.onError = (details) {
     FirebaseCrashlytics.instance.recordFlutterFatalError(details);
     _logCrashToFirestore(details);
   };
   ```

5. **Kakao SDK** 초기화

6. **[SettingData](data/setting_data.md)** 초기화 (알림 권한은 온보딩 완료 시 요청)

7. **Timezone** 초기화 (`Asia/Seoul`)

8. **테마 모드** 복원: `SettingData().themeModeIndex` → `ThemeMode`

9. **과목 데이터 프리로드** (2학년, 3학년 병렬):
   ```dart
   unawaited(_preloadSubjects(2));
   unawaited(_preloadSubjects(3));
   ```

10. **[ServiceLocator](data/service_locator.md)** 설정 (GetIt DI)

11. **로컬 급식 알림** 초기화 + 스케줄링

12. **FCM** 초기화 + **위젯 서비스** 초기화 (fire-and-forget)

13. `ProviderScope`로 감싼 `HansolHighSchool` 위젯 실행

---

## 전역 상태

| 변수 | 타입 | 용도 |
|------|------|------|
| `themeNotifier` | `ValueNotifier<ThemeMode>` | 레거시 테마 전환 (Riverpod으로 점진 마이그레이션) |
| `localeNotifier` | `ValueNotifier<Locale?>` | 인앱 언어 전환 (null=시스템, `Locale('ko')`, `Locale('en')`) |
| `appRefreshNotifier` | `ValueNotifier<int>` | 값 변경 시 MainScreen 전체 리빌드 |
| `rootNavigatorKey` | `GlobalKey<NavigatorState>` | FCM 딥링크에서 Navigator 접근용 |
| `notificationStream` | `StreamController<String?>` | 알림 탭 → MealScreen 전환용 |

---

## `HansolHighSchool` (루트 위젯)

```dart
class HansolHighSchool extends ConsumerStatefulWidget
```

**설명**: 앱의 루트 위젯. 테마 모드 전환과 MaterialApp 설정을 담당

1. `initState`에서 [`AnimatedAppColors`](styles/app_colors.md) 초기화 + `themeNotifier` 리스너 등록
2. `_resolveIsDark`: ThemeMode.system일 때 platformBrightness 확인
3. `build`: `ref.watch(themeProvider)` → `MaterialApp` 테마 적용
4. `localeNotifier` 기반 `ValueListenableBuilder<Locale?>` 로 즉시 언어 전환

```dart
return ValueListenableBuilder<Locale?>(
  valueListenable: localeNotifier,
  builder: (_, locale, __) => MaterialApp(
    navigatorKey: rootNavigatorKey,
    locale: locale,  // null이면 시스템 로캘 사용
    theme: _lightTheme,
    darkTheme: _darkTheme,
    themeMode: mode,
    home: ...,
  ),
);
```

`appRefreshNotifier` 값 변경 → `ValueKey` 변경 → MainScreen 재생성

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
