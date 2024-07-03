import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/Data/local_database.dart';
import 'package:hansol_high_school/Screens/MainScreens/home_screen.dart';
import 'package:hansol_high_school/Screens/MainScreens/meal_screen.dart';
import 'package:hansol_high_school/Screens/MainScreens/notice_screen.dart';
import 'package:hansol_high_school/Firebase/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'Notification/notification_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationManager.requestNotificationPermissions();
  final database = LocalDataBase();
  GetIt.I.registerSingleton<LocalDataBase>(database);
  initializeDateFormatting().then((_) => runApp(HansolHighSchool()));
}

class HansolHighSchool extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
    NotificationManager.init();
    Future.delayed(
      const Duration(seconds: 3),
      () async => await NotificationManager.requestNotificationPermissions(),
    );

    _pages = [MealScreen(), HomeScreen(), const NoticeScreen()];
    _pageController = PageController(initialPage: 1);

    super.initState();
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
            icon: Icon(Icons.restaurant),
            label: '급식',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: '알림',
          ),
        ],
      ),
    );
  }
}
