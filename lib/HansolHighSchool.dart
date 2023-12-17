import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/API/MealDataApi.dart';
import 'package:hansol_high_school/API/NoticeDataApi.dart';
import 'package:hansol_high_school/API/TimetableDataApi.dart';
import 'package:hansol_high_school/Screens/MainScreens/HomeScreen.dart';
import 'package:hansol_high_school/Screens/MainScreens/MealScreen.dart';
import 'package:hansol_high_school/Screens/MainScreens/NoticeScreen.dart';
import 'package:hansol_high_school/Firebase/firebase_options.dart';

import 'Notification/NotificationManager.dart';

Future<void> main() async {
  runApp(const HansolHighSchool());
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class HansolHighSchool extends StatelessWidget {
  const HansolHighSchool({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  final _pages = [MealScreen(), HomeScreen(), NoticeScreen()];
  final PageController _pageController = PageController();

  @override
  void initState() {
    NotificationManager.init();
    Future.delayed(
      const Duration(seconds: 3),
      () async => await NotificationManager.requestNotificationPermissions(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(1);
    });
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const AlwaysScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 0),
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
