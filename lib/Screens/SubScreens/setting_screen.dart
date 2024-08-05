import 'package:flutter/material.dart';
import 'package:hansol_high_school/API/timetable_data_api.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:hansol_high_school/Screens/SubScreens/timetable_select_screen.dart';
import 'package:hansol_high_school/Widgets/SettingWidgets/setting_card.dart';
import 'package:hansol_high_school/Widgets/SettingWidgets/setting_toggle_switch.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  int grade = 1;
  int classNum = 1;
  bool isDarkMode = false;
  bool isBreakfastNotificationOn = true;
  bool isLunchNotificationOn = true;
  bool isDinnerNotificationOn = true;
  bool isNullNotificationOn = true;

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
              SizedBox(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
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
                  ],
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

  void _selectGradeAndClass() async {
    int classCount = await TimetableDataApi.getClassCount(grade);
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
      });
    }
  }
}

class GradeAndClassPickerDialog extends StatefulWidget {
  final int initialGrade;
  final int initialClass;
  final int classCount;

  GradeAndClassPickerDialog({
    required this.initialGrade,
    required this.initialClass,
    required this.classCount,
  });

  @override
  _GradeAndClassPickerDialogState createState() =>
      _GradeAndClassPickerDialogState();
}

class _GradeAndClassPickerDialogState extends State<GradeAndClassPickerDialog> {
  late int selectedGrade;
  late int selectedClass;

  @override
  void initState() {
    super.initState();
    selectedGrade = widget.initialGrade;
    selectedClass = widget.initialClass;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('학년'),
              NumberPicker(
                minValue: 1,
                maxValue: 3,
                value: selectedGrade,
                onChanged: (value) {
                  setState(() {
                    selectedGrade = value;
                  });
                },
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('반'),
              NumberPicker(
                minValue: 1,
                maxValue: widget.classCount,
                value: selectedClass,
                onChanged: (value) {
                  setState(() {
                    selectedClass = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop([selectedGrade, selectedClass]);
          },
          child: Text('확인'),
        ),
      ],
    );
  }
}
