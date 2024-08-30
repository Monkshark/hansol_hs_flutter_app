import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/Data/device.dart';
import 'package:hansol_high_school/Data/local_database.dart';
import 'package:hansol_high_school/Data/setting_data.dart';
import 'package:hansol_high_school/Notification/meal_notification_worker.dart';
import 'package:hansol_high_school/Screens/MainScreens/home_screen.dart';
import 'package:hansol_high_school/Screens/MainScreens/meal_screen.dart';
import 'package:hansol_high_school/Screens/MainScreens/notice_screen.dart';
import 'package:hansol_high_school/Notification/notification_manager.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  await NotificationManager().init();
  MealNotificationWorker.initialize();
  MealNotificationWorker.registerDailyMealNotificationTask();
  await _requestNotificationPermission();
  await SettingData().init();
  final database = LocalDataBase();
  GetIt.I.registerSingleton<LocalDataBase>(database);
  tz.initializeTimeZones();
  initializeDateFormatting().then((_) => runApp(HansolHighSchool()));
}

Future<void> _requestNotificationPermission() async {
  final status = await Permission.notification.request();
  if (status.isGranted) {
    log("Notification permission granted.");
  } else {
    log("Notification permission denied.");
  }
}

class HansolHighSchool extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Device.init(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  late List<Widget> _pages;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pages = [MealScreen(), HomeScreen(), const NoticeScreen()];
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (_pages.isNotEmpty)
          ? PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              physics: const PageScrollPhysics(),
              children: _pages,
            )
          : Container(),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Color(0xFF3B8EF2),
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeIn,
          );
        },
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood_outlined),
            label: '급식',
            // activeIcon: Icon(Icons.fastfood),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '홈',
            // activeIcon: Icon(Icons.home),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: '알림',
            // activeIcon: Icon(Icons.notifications),
          ),
        ],
      ),
    );
  }
}
