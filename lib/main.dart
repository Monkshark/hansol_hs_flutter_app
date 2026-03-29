import 'dart:async';
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/device.dart';
import 'package:hansol_high_school/data/local_database.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/notification/daily_meal_notification.dart';
import 'package:hansol_high_school/notification/fcm_service.dart';
import 'package:hansol_high_school/notification/update_checker.dart';
import 'package:hansol_high_school/screens/sub/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hansol_high_school/screens/main/home_screen.dart';
import 'package:hansol_high_school/screens/main/meal_screen.dart';
import 'package:hansol_high_school/screens/main/notice_screen.dart';
import 'package:hansol_high_school/firebase_options.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';

/**
 * 앱 진입점, Firebase/알림/테마 초기화, 메인 네비게이션
 *
 * - Firebase, 타임존, 알림 권한 등 앱 초기화
 * - 급식/홈/일정 3탭 하단 네비게이션 구성
 * - 앱 리프레시 및 업데이트 체크 지원
 */
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<int> appRefreshNotifier = ValueNotifier(0);

final StreamController<String?> notificationStream =
    StreamController<String?>.broadcast();

void onNotificationTap(NotificationResponse notificationResponse) {
  notificationStream.add(notificationResponse.payload);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    SettingData().init(),
    _requestNotificationPermission(),
  ]);
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  final modeIndex = SettingData().themeModeIndex;
  themeNotifier.value = _indexToThemeMode(modeIndex);

  unawaited(_preloadSubjects(2));
  unawaited(_preloadSubjects(3));

  final localDb = LocalDataBase();
  GetIt.I.registerSingleton<LocalDataBase>(localDb);
  await localDb.migrateFromPrefs();
  await DailyMealNotification().initializeNotifications();
  await DailyMealNotification().scheduleDailyNotifications();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  unawaited(FcmService.initialize());

  initializeDateFormatting().then((_) => runApp(const HansolHighSchool()));
}

ThemeMode _indexToThemeMode(int index) {
  switch (index) {
    case 1: return ThemeMode.dark;
    case 2: return ThemeMode.system;
    default: return ThemeMode.light;
  }
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
  scaffoldBackgroundColor: Colors.white,
  cardColor: Colors.white,
  dividerColor: const Color(0xFFE5E5EA),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF3F72AF),
    foregroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
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

class HansolHighSchool extends StatefulWidget {
  const HansolHighSchool({Key? key}) : super(key: key);

  @override
  State<HansolHighSchool> createState() => _HansolHighSchoolState();
}

class _HansolHighSchoolState extends State<HansolHighSchool> {
  ThemeMode _mode = themeNotifier.value;

  @override
  void initState() {
    super.initState();
    final isDark = _resolveIsDark(_mode);
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
    setState(() => _mode = newMode);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _mode,
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

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  final List<Widget> _pages = const [MealScreen(), HomeScreen(), NoticeScreen()];
  final PageController _pageController = PageController(initialPage: 1);
  StreamSubscription<String?>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _notificationSubscription = notificationStream.stream.listen((payload) {
      if (payload == 'meal_screen') {
        setState(() => _currentIndex = 0);
        _pageController.jumpToPage(0);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAccountExists();
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('onboarding_done') != true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      }
      if (mounted) UpdateChecker.check(context);
    });
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        physics: const PageScrollPhysics(),
        children: _pages,
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
