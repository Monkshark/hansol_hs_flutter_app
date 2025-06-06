import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:hansol_high_school/data/device.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/notification/daily_meal_notification.dart';
import 'package:hansol_high_school/widgets/setting/grade_and_class_picker.dart';
import 'package:hansol_high_school/widgets/setting/theme_mode_buttons.dart';
import 'package:hansol_high_school/widgets/setting/single_setting_card.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/screens/sub/timetable_select_screen.dart';
import 'package:hansol_high_school/widgets/setting/setting_card.dart';
import 'package:hansol_high_school/widgets/setting/setting_toggle_switch.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late int grade;
  late int classNum;
  late bool isDarkMode;
  late bool isBreakfastNotificationOn;
  late bool isLunchNotificationOn;
  late bool isDinnerNotificationOn;

  late TimeOfDay breakfastTime;
  late TimeOfDay lunchTime;
  late TimeOfDay dinnerTime;

  late Future<void> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();
  }

  Future<void> _loadSettings() async {
    await SettingData().init();
    setState(() {
      grade = SettingData().grade;
      classNum = SettingData().classNum;
      isDarkMode = SettingData().isDarkMode;
      isBreakfastNotificationOn = SettingData().isBreakfastNotificationOn;
      breakfastTime = _parseTimeOfDay(SettingData().breakfastTime);
      isLunchNotificationOn = SettingData().isLunchNotificationOn;
      lunchTime = _parseTimeOfDay(SettingData().lunchTime);
      isDinnerNotificationOn = SettingData().isDinnerNotificationOn;
      dinnerTime = _parseTimeOfDay(SettingData().dinnerTime);
    });
  }

  TimeOfDay _parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      final hourPart = parts[0];
      final minutePart = parts[1];
      if (minutePart.contains(' ')) {
        final minuteParts = minutePart.split(' ');
        final minute = int.parse(minuteParts[0]);
        final period = minuteParts[1];
        int hour = int.parse(hourPart);
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
        return TimeOfDay(hour: hour, minute: minute);
      } else {
        final hour = int.parse(hourPart);
        final minute = int.parse(minutePart);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      return const TimeOfDay(hour: 6, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveSettings() async {
    SettingData().grade = grade;
    SettingData().classNum = classNum;
    SettingData().isDarkMode = isDarkMode;
    SettingData().isBreakfastNotificationOn = isBreakfastNotificationOn;
    SettingData().breakfastTime = _formatTimeOfDay(breakfastTime);
    SettingData().isLunchNotificationOn = isLunchNotificationOn;
    SettingData().lunchTime = _formatTimeOfDay(lunchTime);
    SettingData().isDinnerNotificationOn = isDinnerNotificationOn;
    SettingData().dinnerTime = _formatTimeOfDay(dinnerTime);
  }

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
        child: FutureBuilder<void>(
          future: _settingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading settings'));
            } else {
              return buildSettingsBody();
            }
          },
        ),
      ),
    );
  }

  Widget buildSettingsBody() {
    return Scaffold(
      backgroundColor: AppColors.theme.settingScreenBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.theme.settingScreenBackgroundColor,
        title: const Text(
          '설정',
        ),
        titleTextStyle: TextStyle(
          fontSize: Device.getWidth(5),
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            SettingCard(
              name: '학년 반 설정',
              child: GestureDetector(
                onTap: () => _selectGradeAndClass(),
                child: Text(
                  '$grade학년 $classNum반',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            SettingCard(
              name: '선택과목 시간표 설정',
              child: IconButton(
                onPressed: grade == 1
                    ? null
                    : () {
                        Navigator.of(context).push(_createRoute());
                      },
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: grade == 1 ? Colors.grey : Colors.black,
                ),
              ),
            ),
            SettingCard(
              name: '다크 모드',
              child: SettingToggleSwitch(
                value: isDarkMode,
                onChanged: (value) {
                  setState(() {
                    isDarkMode = value;
                    _saveSettings();
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
                  _saveSettings();
                  DailyMealNotification().updateNotifications();
                  log('notification setting changed');
                });
              },
              (newValue) {
                setState(() {
                  isBreakfastNotificationOn = newValue;
                  _saveSettings();
                  DailyMealNotification().updateNotifications();
                  log('notification setting changed');
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
                  _saveSettings();
                  DailyMealNotification().updateNotifications();
                  log('notification setting changed');
                });
              },
              (newValue) {
                setState(() {
                  isLunchNotificationOn = newValue;
                  _saveSettings();
                  DailyMealNotification().updateNotifications();
                  log('notification setting changed');
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
                  _saveSettings();
                  DailyMealNotification().updateNotifications();
                  log('notification setting changed');
                });
              },
              (newValue) {
                setState(() {
                  isDinnerNotificationOn = newValue;
                  _saveSettings();
                  DailyMealNotification().updateNotifications();
                  log('notification setting changed');
                });
              },
            ),
            const SingleSettingCard(
              text: '알림 설정',
              child: Text("a"),
            ),
            ThemeModeButtons(
              initialMode: ThemeType.light,
              onModeChanged: (ThemeType newMode) {
                print('Selected mode: $newMode');
              },
            ),
          ],
        ),
      ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const TimetableSelectScreen(),
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
              selectedTime.format(context),
              style: TextStyle(
                fontSize: 18,
                color: isSwitched ? Colors.black : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 15),
          SettingToggleSwitch(
            value: isSwitched,
            onChanged: (newValue) {
              onSwitchChanged(newValue);
              setState(() {});
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  void _selectGradeAndClass() async {
    int classCount = await TimetableDataApi.getClassCount(grade);
    if (!mounted) return;
    List<int>? selectedValues = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        return GradeAndClassPickerDialog(
          initialGrade: grade,
          initialClass: classNum,
          classCount: classCount,
        );
      },
    );

    if (selectedValues != null && selectedValues.length == 2) {
      setState(() {
        grade = selectedValues[0];
        classNum = selectedValues[1];
        _saveSettings();
      });
    }
  }
}
