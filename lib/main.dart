import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/device.dart';
import 'package:hansol_high_school/data/local_database.dart';
import 'package:hansol_high_school/data/service_locator.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/notification/daily_meal_notification.dart';
import 'package:hansol_high_school/notification/fcm_service.dart';
import 'package:hansol_high_school/notification/popup_notice.dart';
import 'package:hansol_high_school/notification/update_checker.dart';
import 'package:hansol_high_school/screens/auth/login_screen.dart';
import 'package:hansol_high_school/screens/auth/profile_setup_screen.dart';
import 'package:hansol_high_school/screens/sub/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hansol_high_school/screens/main/home_screen.dart';
import 'package:hansol_high_school/screens/main/meal_screen.dart';
import 'package:hansol_high_school/screens/main/notice_screen.dart';
import 'package:hansol_high_school/firebase_options.dart';
import 'package:hansol_high_school/widgets/offline_banner.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/providers/theme_provider.dart';
import 'package:hansol_high_school/api/kakao_keys.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:hansol_high_school/widgets/home_widget/widget_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' show KakaoSdk;

/// 앱 진입점, Firebase/알림/테마 초기화, 메인 네비게이션
///
/// - Firebase, 타임존, 알림 권한 등 앱 초기화
/// - 급식/홈/일정 3탭 하단 네비게이션 구성
/// - 앱 리프레시 및 업데이트 체크 지원
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<int> appRefreshNotifier = ValueNotifier(0);
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final StreamController<String?> notificationStream =
    StreamController<String?>.broadcast();

void onNotificationTap(NotificationResponse notificationResponse) {
  notificationStream.add(notificationResponse.payload);
  // FCM 포그라운드 로컬 알림 탭 → 딥링크 라우팅
  FcmService.handleLocalNotificationTap(notificationResponse.payload);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  try {
    // google-services.json 자동 초기화와 중복 호출되는 경우 무시
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e, st) {
    // Firebase 초기화 실패는 치명적이지만 앱 자체는 실행되어야 하므로
    // 디버그 로그 + 앞으로의 Crashlytics 호출은 무시되도록 둠
    log('Firebase init failed: $e\n$st', name: 'main');
  }

  // Firebase App Check: Android만 Play Integrity로 enforce
  // (iOS는 Apple Developer 계정 등록 후 appAttest로 전환 예정)
  // 개발 빌드는 debug provider 사용. 콘솔에서 enforce 활성화 필요.
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: const bool.fromEnvironment('dart.vm.product')
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } catch (e) {
    log('AppCheck activate failed: $e', name: 'main');
  }

  // Firebase Performance Monitoring (자동 HTTP/네트워크 트레이스)
  try {
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  } catch (e) {
    log('Performance enable failed: $e', name: 'main');
  }

  FlutterError.onError = (details) {
    try { FirebaseCrashlytics.instance.recordFlutterFatalError(details); } catch (_) {}
    try { _logCrashToFirestore(details); } catch (_) {}
  };

  KakaoSdk.init(nativeAppKey: KakaoKeys.nativeAppKey);
  await Future.wait([
    SettingData().init(),
    _requestNotificationPermission(),
  ]);
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  final modeIndex = SettingData().themeModeIndex;
  themeNotifier.value = _indexToThemeMode(modeIndex);

  unawaited(_preloadSubjects(2));
  unawaited(_preloadSubjects(3));

  await setupServiceLocator();
  await DailyMealNotification().initializeNotifications();
  await DailyMealNotification().scheduleDailyNotifications();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  unawaited(FcmService.initialize());
  unawaited(WidgetService.initialize().then((_) {
    WidgetService.updateAll();
    HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  }));

  initializeDateFormatting().then((_) => runApp(const ProviderScope(child: HansolHighSchool())));
}

ThemeMode _indexToThemeMode(int index) {
  switch (index) {
    case 1: return ThemeMode.dark;
    case 2: return ThemeMode.system;
    default: return ThemeMode.light;
  }
}

void _logCrashToFirestore(FlutterErrorDetails details) {
  try {
    if (!AuthService.isLoggedIn) return;
    FirebaseFirestore.instance.collection('crash_logs').add({
      'error': details.exceptionAsString().substring(0, details.exceptionAsString().length.clamp(0, 500)),
      'stack': details.stack?.toString().substring(0, details.stack.toString().length.clamp(0, 1000)) ?? '',
      'library': details.library ?? '',
      'uid': AuthService.currentUser?.uid ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {}
}

Future<void> _preloadSubjects(int grade) async {
  try {
    await TimetableDataApi.getAllSubjectCombinations(grade: grade);
  } catch (e) {
    log('Preload subjects error for grade $grade: $e');
  }
}

Future<void> _requestNotificationPermission() async {
  await Permission.notification.request();
}

final _lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF3F72AF),
  scaffoldBackgroundColor: const Color(0xFFF2F3F5),
  cardColor: Colors.white,
  dividerColor: const Color(0xFFE5E5EA),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF3F72AF),
    foregroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFFF2F3F5),
    indicatorColor: const Color(0xFF3F72AF).withAlpha(30),
    surfaceTintColor: Colors.transparent,
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF3F72AF),
    brightness: Brightness.light,
  ),
);

final _darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF3D5A80),
  scaffoldBackgroundColor: const Color(0xFF17191E),
  cardColor: const Color(0xFF1E2028),
  dividerColor: const Color(0xFF2A2D35),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E2028),
    foregroundColor: Color(0xFFEEEEEE),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFF1E2028),
    surfaceTintColor: Colors.transparent,
    indicatorColor: const Color(0xFF3D5A80).withAlpha(50),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: Color(0xFF7EB8DA));
      }
      return const IconThemeData(color: Color(0xFF8B8F99));
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(color: Color(0xFF7EB8DA), fontSize: 12);
      }
      return const TextStyle(color: Color(0xFF8B8F99), fontSize: 12);
    }),
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF3D5A80),
    brightness: Brightness.dark,
    surface: const Color(0xFF1E2028),
  ),
);

/// 앱 루트 위젯 (테마 모드 전환 및 MaterialApp 구성)
///
/// `ConsumerStatefulWidget`으로 Riverpod `themeProvider`를 구독한다.
/// 기존의 전역 `ValueNotifier<ThemeMode> themeNotifier`도 호환성을 위해
/// 유지되며, 양쪽이 동기화된다 (점진적 마이그레이션).
class HansolHighSchool extends ConsumerStatefulWidget {
  const HansolHighSchool({Key? key}) : super(key: key);

  @override
  ConsumerState<HansolHighSchool> createState() => _HansolHighSchoolState();
}

class _HansolHighSchoolState extends ConsumerState<HansolHighSchool> {
  @override
  void initState() {
    super.initState();
    final isDark = _resolveIsDark(themeNotifier.value);
    AnimatedAppColors.instance.setDark(isDark, animate: false);
    AnimatedAppColors.instance.tick(isDark ? 1.0 : 0.0);
    themeNotifier.addListener(_onThemeChanged);
  }

  bool _resolveIsDark(ThemeMode mode) {
    if (mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  void _onThemeChanged() {
    final newMode = themeNotifier.value;
    final isDark = _resolveIsDark(newMode);
    AnimatedAppColors.instance.setDark(isDark, animate: false);
    AnimatedAppColors.instance.tick(isDark ? 1.0 : 0.0);
    // Riverpod 상태와 동기화
    final idx = newMode == ThemeMode.dark
        ? 1
        : (newMode == ThemeMode.system ? 2 : 0);
    ref.read(themeProvider.notifier).setMode(idx);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeProvider);
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: mode,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ValueListenableBuilder<int>(
        valueListenable: appRefreshNotifier,
        builder: (_, value, __) => MainScreen(key: ValueKey(value)),
      ),
    );
  }
}

/// 메인 화면 (급식/홈/일정 3탭 하단 네비게이션 + 온보딩·로그인 체크)
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  final _homeKey = GlobalKey<HomeScreenState>();
  late final List<Widget> _pages;
  final PageController _pageController = PageController(initialPage: 1);
  StreamSubscription<String?>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _pages = [const MealScreen(), HomeScreen(key: _homeKey), const NoticeScreen()];
    _notificationSubscription = notificationStream.stream.listen((payload) {
      if (payload == 'meal_screen') {
        setState(() => _currentIndex = 0);
        _pageController.jumpToPage(0);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAccountExists();
      await _checkNewSemester();
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('onboarding_done') != true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      }
      if (!AuthService.isLoggedIn && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      if (AuthService.isLoggedIn) {
        unawaited(GetIt.I<LocalDataBase>().loadFromFirestore());
      }
      if (mounted) UpdateChecker.check(context);
      if (mounted) PopupNotice.check(context);
    });
  }

  Future<void> _checkNewSemester() async {
    if (!AuthService.isLoggedIn) return;
    try {
      final profile = await AuthService.getCachedProfile();
      if (profile == null) return;
      if (!profile.needsProfileUpdate) return;
      if (!mounted) return;

      if (profile.isStudent) {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().where((k) => k.startsWith('selected_subjects_')).toList();
        for (var k in keys) {
          await prefs.remove(k);
        }
        final ttKeys = prefs.getKeys().where((k) => k.contains('timetable') || k.contains('subject_colors') || k.contains('conflict_')).toList();
        for (var k in ttKeys) {
          await prefs.remove(k);
        }
      }

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen(isUpdate: true)),
      );
      AuthService.clearProfileCache();
      appRefreshNotifier.value++;
    } catch (_) {}
  }

  Future<void> _checkAccountExists() async {
    if (!AuthService.isLoggedIn) return;
    try {
      final profile = await AuthService.getUserProfile();
      if (profile == null && mounted) {
        await AuthService.signOut();
        AuthService.clearProfileCache();
        appRefreshNotifier.value++;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('계정이 삭제되었습니다. 다시 가입해주세요.')),
          );
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Device.init(context);
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) _homeKey.currentState?.refresh();
        },
        physics: const PageScrollPhysics(),
        children: _pages,
      )),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 56 + MediaQuery.of(context).padding.bottom,
        child: NavigationBar(
          selectedIndex: _currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          onDestinationSelected: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeIn,
            );
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: ''),
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: ''),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: ''),
          ],
        ),
      ),
    );
  }
}
