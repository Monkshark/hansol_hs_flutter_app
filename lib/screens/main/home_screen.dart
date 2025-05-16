import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/device.dart';
import 'package:hansol_high_school/screens/sub/setting_screen.dart';
import 'package:hansol_high_school/widgets/home/current_subject_card.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/widgets/home/news_card.dart';
import 'package:hansol_high_school/widgets/subject/subject_card.dart';
import 'package:hansol_high_school/widgets/subject/subject_card_stacker.dart';

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
          preferredSize: Size.fromHeight(Device.getHeight(23)),
          child: AppBar(
            backgroundColor: AppColors.theme.primaryColor,
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
        body: Column(
          children: [
            Center(
              child: Column(
                children: [
                  const CurrentSubjectCard(),
                  const NewsCard(
                    title: "{news_title_1}",
                  ),
                  Center(
                    child: SubjectCardStacker(
                      cards: [
                        SubjectCard(subjectName: '생명과학 I', classNumber: 1),
                        SubjectCard(subjectName: '생명과학 I', classNumber: 2),
                        SubjectCard(subjectName: '생명과학 I', classNumber: 3),
                      ],
                    ),
                  ),
                ],
              ),
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
