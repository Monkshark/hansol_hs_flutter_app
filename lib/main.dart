import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:hansol_high_school/data/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/device.dart';
import 'package:hansol_high_school/data/local_database.dart';
import 'package:hansol_high_school/data/service_locator.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/notification/daily_meal_notification.dart';
import 'package:hansol_high_school/network/offline_queue_manager.dart';
import 'package:hansol_high_school/notification/deep_link_service.dart';
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
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/providers/settings_provider.dart';
import 'package:hansol_high_school/providers/theme_provider.dart' hide Theme;
import 'package:hansol_high_school/api/kakao_keys.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:hansol_high_school/widgets/home_widget/widget_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' show KakaoSdk;

/// 글로벌 ProviderContainer — main()이나 non-widget 코드에서 Riverpod 접근용
late final ProviderContainer providerContainer;
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final StreamController<String?> notificationStream =
    StreamController<String?>.broadcast();

void onNotificationTap(NotificationResponse notificationResponse) {
  notificationStream.add(notificationResponse.payload);
  FcmService.handleLocalNotificationTap(notificationResponse.payload);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e, st) {
    log('Firebase init failed: $e\n$st', name: 'main');
  }

  FlutterError.onError = (details) {
    try { FirebaseCrashlytics.instance.recordFlutterFatalError(details); } catch (e) { log('Crashlytics report error: $e', name: 'main'); }
    try { _logCrashToFirestore(details); } catch (e) { log('Firestore crash log error: $e', name: 'main'); }
  };

  KakaoSdk.init(nativeAppKey: KakaoKeys.nativeAppKey);
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  providerContainer = ProviderContainer();

  // 필수: SettingData + ServiceLocator만 await (UI에 필요)
  await Future.wait([SettingData().init(), setupServiceLocator()]);

  await initializeDateFormatting();
  runApp(UncontrolledProviderScope(container: providerContainer, child: const HansolHighSchool()));

  // UI가 뜬 후 나머지 초기화를 백그라운드로 실행
  unawaited(_deferredInit());
}

Future<void> _deferredInit() async {
  unawaited(_safeInit('AnalyticsOpen', () => AnalyticsService.logAppOpen(source: 'organic')));
  unawaited(_safeInit('OfflineQueue', () => OfflineQueueManager.instance.initialize()));
  unawaited(_safeInit('AppCheck', () => FirebaseAppCheck.instance.activate(
    androidProvider: const bool.fromEnvironment('dart.vm.product')
        ? AndroidProvider.playIntegrity
        : AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  )));
  unawaited(_safeInit('Performance', () => FirebasePerformance.instance.setPerformanceCollectionEnabled(true)));
  unawaited(_safeInit('Analytics', () async {
    final prefs = await SharedPreferences.getInstance();
    final userEnabled = prefs.getBool('analyticsEnabled') ?? true;
    final isRelease = const bool.fromEnvironment('dart.vm.product');
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(isRelease && userEnabled);
  }));

  unawaited(_preloadSubjects(2));
  unawaited(_preloadSubjects(3));

  final meal = DailyMealNotification();
  await meal.initializeNotifications();
  await meal.scheduleDailyNotifications();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  unawaited(_safeInit('FcmService', () => FcmService.initialize()));
  unawaited(_safeInit('DeepLink', () => DeepLinkService.initialize()));
  unawaited(_safeInit('WidgetService', () async {
    await WidgetService.initialize();
    WidgetService.updateAll();
    HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  }));
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
  } catch (e) {
    log('_logCrashToFirestore error: $e', name: 'main');
  }
}

Future<void> _safeInit(String name, Future<void> Function() fn) async {
  try {
    await fn();
  } catch (e) {
    log('$name init failed: $e', name: 'main');
  }
}

Future<void> _preloadSubjects(int grade) async {
  try {
    await TimetableDataApi.getAllSubjectCombinations(grade: grade);
  } catch (e) {
    log('Preload subjects error for grade $grade: $e');
  }
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

class HansolHighSchool extends ConsumerStatefulWidget {
  const HansolHighSchool({super.key});

  @override
  ConsumerState<HansolHighSchool> createState() => _HansolHighSchoolState();
}

class _HansolHighSchoolState extends ConsumerState<HansolHighSchool> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsService.markSessionStart();

    final mode = ref.read(themeProvider);
    final isDark = _resolveIsDark(mode);
    AnimatedAppColors.instance.setDark(isDark, animate: false);
    AnimatedAppColors.instance.tick(isDark ? 1.0 : 0.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shortestSide = MediaQuery.of(context).size.shortestSide;
      if (shortestSide >= 600) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      unawaited(AnalyticsService.logSessionEnd());
    } else if (state == AppLifecycleState.resumed) {
      AnalyticsService.markSessionStart();
    }
  }

  bool _resolveIsDark(ThemeMode mode) {
    if (mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final refreshKey = ref.watch(appRefreshProvider);

    // 테마 변경 시 AnimatedAppColors 동기화
    final isDark = _resolveIsDark(mode);
    AnimatedAppColors.instance.setDark(isDark, animate: false);
    AnimatedAppColors.instance.tick(isDark ? 1.0 : 0.0);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      navigatorObservers: [AnalyticsService.observer],
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: mode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final size = MediaQuery.of(context).size;
        final maxWidth = size.width > size.height
            ? size.height * (9 / 16)
            : size.width;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
      home: MainScreen(key: ValueKey(refreshKey)),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

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
      if (!mounted) return;
      await _checkNewSemester();
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (prefs.getBool('onboarding_done') != true) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        if (!mounted) return;
      }
      if (!AuthService.isLoggedIn) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        if (!mounted) return;
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

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen(isUpdate: true)),
      );
      if (!mounted) return;
      AuthService.clearProfileCache();
      providerContainer.read(appRefreshProvider.notifier).refresh();
    } catch (e) {
      log('_checkProfileUpdate error: $e', name: 'main');
    }
  }

  Future<void> _checkAccountExists() async {
    if (!AuthService.isLoggedIn) return;
    try {
      final profile = await AuthService.getUserProfile();
      if (profile == null && mounted) {
        await AuthService.signOut();
        AuthService.clearProfileCache();
        providerContainer.read(appRefreshProvider.notifier).refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.main_accountDeleted)),
          );
        }
      }
    } catch (e) {
      log('_checkAccountExists error: $e', name: 'main');
    }
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
      bottomNavigationBar: Container(
        color: Theme.of(context).navigationBarTheme.backgroundColor,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
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
        ),
      ),
    );
  }
}
