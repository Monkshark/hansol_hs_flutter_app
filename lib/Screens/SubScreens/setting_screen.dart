import 'package:flutter/material.dart';
import 'package:hansol_high_school/Screens/SubScreens/timetable_select_screen.dart';
import 'package:hansol_high_school/Widgets/SettingWidgets/setting_card.dart';
import 'package:hansol_high_school/Widgets/SettingWidgets/setting_toggle_switch.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool isDarkMode = false;
  bool isBreakfastNotificationOn = false;
  bool isLunchNotificationOn = false;
  bool isDinnerNotificationOn = false;
  bool isNullNotificationOn = false;

  TimeOfDay breakfastTime = TimeOfDay.now();
  TimeOfDay lunchTime = TimeOfDay.now();
  TimeOfDay dinnerTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('설정'),
          ),
          body: Column(
            children: [
              SettingCard(
                name: '선택과목 시간표 설정',
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(_createRoute());
                  },
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ),
              SettingCard(
                name: '다크 모드',
                child: SettingToggleSwitch(
                  value: isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      isDarkMode = value;
                    });
                  },
                ),
              ),
              buildNotificationCard(
                '조식 알림',
                breakfastTime,
                isBreakfastNotificationOn,
                (newTime) {
                  setState(() {
                    breakfastTime = newTime;
                  });
                },
                (newValue) {
                  setState(() {
                    isBreakfastNotificationOn = newValue;
                  });
                },
              ),
              buildNotificationCard(
                '중식 알림',
                lunchTime,
                isLunchNotificationOn,
                (newTime) {
                  setState(() {
                    lunchTime = newTime;
                  });
                },
                (newValue) {
                  setState(() {
                    isLunchNotificationOn = newValue;
                  });
                },
              ),
              buildNotificationCard(
                '석식 알림',
                dinnerTime,
                isDinnerNotificationOn,
                (newTime) {
                  setState(() {
                    dinnerTime = newTime;
                  });
                },
                (newValue) {
                  setState(() {
                    isDinnerNotificationOn = newValue;
                  });
                },
              ),
              SettingCard(
                name: '정보 없는 알림',
                child: SettingToggleSwitch(
                  value: isNullNotificationOn,
                  onChanged: (value) {
                    setState(() {
                      isNullNotificationOn = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          TimetableSelectScreen(),
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

  Widget buildNotificationCard(
    String name,
    TimeOfDay selectedTime,
    bool isSwitched,
    ValueChanged<TimeOfDay> onTimeChanged,
    ValueChanged<bool> onSwitchChanged,
  ) {
    return SettingCard(
      name: name,
      child: Row(
        children: [
          GestureDetector(
            onTap: isSwitched
                ? () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );

                    if (pickedTime != null && pickedTime != selectedTime) {
                      onTimeChanged(pickedTime);
                    }
                  }
                : null,
            child: Text(
              '${selectedTime.format(context)}',
              style: TextStyle(
                fontSize: 18,
                color: isSwitched ? Colors.black : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 15),
          SettingToggleSwitch(
            value: isSwitched,
            onChanged: onSwitchChanged,
          ),
        ],
      ),
    );
  }
}
