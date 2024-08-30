import 'package:flutter/material.dart';
import 'package:hansol_high_school/Screens/SubScreens/setting_screen.dart';
import 'package:hansol_high_school/Widgets/HomeWidgets/current_subject_card.dart';
import 'package:hansol_high_school/Styles/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSwitched = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(200),
          child: AppBar(
            backgroundColor: AppColors.color.primaryColor,
            actions: [
              SizedBox(
                child: IconButton(
                  color: Colors.white,
                  onPressed: () {
                    Navigator.of(context).push(_createRoute());
                  },
                  icon: const Icon(Icons.settings_outlined),
                  iconSize: 27,
                ),
              ),
            ],
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
          ),
        ),
        body: const Column(
          children: [
            Center(
              child: CurrentSubjectCard(),
            ),
          ],
        ),
      ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SettingScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
