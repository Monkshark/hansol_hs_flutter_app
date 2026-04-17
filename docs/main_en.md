# Main

> 한국어: [main.md](./main.md)
>
> `lib/main.dart` — App entry point, MainScreen

---

## `main()`

```dart
Future<void> main() async
```

**Description**: Performs app initialization. For startup performance, only initialization essential to the UI runs before `runApp`; the rest is handled in the background via `_deferredInit()`.

### Before runApp (essential initialization)

1. **Firebase initialization**: Check for duplicates before initializing
2. **Crashlytics**: FlutterError handler + log errors to the Firestore `crash_logs` collection
3. **Kakao SDK** initialization
4. **Timezone** initialization (`Asia/Seoul`)
5. Create `providerContainer = ProviderContainer()`
6. **[SettingData](data/setting_data.md)** + **[ServiceLocator](data/service_locator.md)** initialized in parallel:
   ```dart
   await Future.wait([SettingData().init(), setupServiceLocator()]);
   ```
7. `runApp` → run `HansolHighSchool` widget wrapped in `UncontrolledProviderScope`

### After runApp (`_deferredInit`)

Once the UI is up, `unawaited(_deferredInit())` runs the remaining initialization in the background:

1. **App Check** / **Performance Monitoring** — each fire-and-forget via `_safeInit()`
1. **Analytics** — reads `SharedPreferences('analyticsEnabled')` and checks release mode; collection is enabled only when both conditions are met. Then calls `AnalyticsService.logAppOpen(source: 'organic')`
2. **Subject data preload** (grades 2 and 3 in parallel)
3. **Local meal notifications** initialization + scheduling
4. **FCM** init + **deep link** init + **widget service** init (fire-and-forget)
5. **[OfflineQueueManager](network/offline_queue_manager.md)** initialization — open sqflite DB + register network-restored listener

### `_safeInit`

```dart
Future<void> _safeInit(String name, Future<void> Function() fn) async
```

A try/catch wrapper. Ensures an individual initialization failure does not block the whole app — errors are logged and ignored.

---

## Global State

| Variable | Type | Purpose |
|------|------|------|
| `providerContainer` | `ProviderContainer` | Access Riverpod providers from non-widget code (login_screen, setting_screen, etc.) |
| `rootNavigatorKey` | `GlobalKey<NavigatorState>` | Access Navigator from FCM deep links |
| `notificationStream` | `StreamController<String?>` | Switch to MealScreen on notification tap |

> The previous `themeNotifier`, `localeNotifier`, `appRefreshNotifier` (3 ValueNotifiers) have been unified into Riverpod providers — see the [providers doc](providers/providers.md).

---

## `HansolHighSchool` (root widget)

```dart
class HansolHighSchool extends ConsumerStatefulWidget
```

**Description**: The app's root widget. Handles theme mode switching and MaterialApp configuration.

1. Initializes [`AnimatedAppColors`](styles/app_colors.md) in `initState`
2. `_resolveIsDark`: checks platformBrightness when ThemeMode.system
3. Watches 3 providers in `build`:

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

A change in `appRefreshProvider` → `ValueKey` changes → MainScreen is rebuilt.

---

## `MainScreen`

```dart
class MainScreen extends StatefulWidget
```

**Description**: A 3-tab bottom navigation (Meal / Home / Schedule) plus initial check logic.

### `initState` check order

1. `_checkAccountExists()`: logs out if no profile (handles deleted accounts)
2. `_checkNewSemester()`: on semester change, prompts profile update + clears elective subject/timetable cache
3. If onboarding is incomplete → `OnboardingScreen`
4. If not signed in → `LoginScreen`
5. If signed in, restore schedules from Firestore: `GetIt.I<LocalDataBase>().loadFromFirestore()`
6. [`UpdateChecker`](notification/update_checker.md)`.check()` + [`PopupNotice`](notification/popup_notice.md)`.check()`

### Navigation

```dart
_pages = [const MealScreen(), HomeScreen(key: _homeKey), const NoticeScreen()];
```

- `PageView` + `NavigationBar` (icon-only, labels hidden)
- On switching to the Home tab, calls `_homeKey.currentState?.refresh()`
- Notification tap (`meal_screen` payload) → switches to the Meal tab

---

## `_logCrashToFirestore`

```dart
void _logCrashToFirestore(FlutterErrorDetails details)
```

Saves error info to the Firestore `crash_logs` collection. Error messages are truncated to 500 chars, stack traces to 1000 chars.
