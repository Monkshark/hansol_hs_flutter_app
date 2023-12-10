import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/Screens/homeScreen.dart';
import 'package:hansol_high_school/Screens/noticeScreen.dart';

import '../Firebase/firebase_options.dart';
import 'mealScreen.dart';

Future<void> main() async {
  runApp(HansolHighSchool());
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class HansolHighSchool extends StatelessWidget {
  const HansolHighSchool({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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
