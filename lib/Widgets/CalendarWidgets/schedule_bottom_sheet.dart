import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/Data/device.dart';
import 'package:hansol_high_school/Widgets/CalendarWidgets/custom_text_field.dart';
import 'package:hansol_high_school/Styles/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onScheduleCreated;

  const ScheduleBottomSheet({
    required this.selectedDate,
    required this.onScheduleCreated,
    Key? key,
  }) : super(key: key);

  @override
  State<ScheduleBottomSheet> createState() => _ScheduleBottomSheetState();
}

class _ScheduleBottomSheetState extends State<ScheduleBottomSheet> {
  final GlobalKey<FormState> formKey = GlobalKey();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? content;
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    void onSavePressed() async {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();

        final prefs = await SharedPreferences.getInstance();
        final schedules = prefs.getStringList('schedules') ?? [];

        final newSchedule = {
          'startTime': startTime!.hour * 60 + startTime!.minute,
          'endTime': endTime!.hour * 60 + endTime!.minute,
          'content': content,
          'date': widget.selectedDate.toIso8601String(),
        };

        schedules.add(jsonEncode(newSchedule));
        await prefs.setStringList('schedules', schedules);

        Navigator.of(context).pop();

        widget.onScheduleCreated();
      }
    }

    Future<void> pickTime(BuildContext context, bool isStart) async {
      final now = TimeOfDay.now();
      final initialTime = isStart ? (startTime ?? now) : (endTime ?? now);

      if (Platform.isIOS) {
        showCupertinoModalPopup(
          context: context,
          builder: (context) {
            return Container(
              height: 250,
              color: Colors.white,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  widget.selectedDate.year,
                  widget.selectedDate.month,
                  widget.selectedDate.day,
                  initialTime.hour,
                  initialTime.minute,
                ),
                use24hFormat: false,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    if (isStart) {
                      startTime = TimeOfDay(
                        hour: newDateTime.hour,
                        minute: newDateTime.minute,
                      );
                      startTimeController.text = startTime!.format(context);
                    } else {
                      endTime = TimeOfDay(
                        hour: newDateTime.hour,
                        minute: newDateTime.minute,
                      );
                      endTimeController.text = endTime!.format(context);
                    }
                  });
                },
              ),
            );
          },
        );
      } else {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (context, child) {
            return MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
              child: child!,
            );
          },
        );

        if (pickedTime != null) {
          setState(() {
            if (isStart) {
              startTime = pickedTime;
              startTimeController.text = startTime!.format(context);
            } else {
              endTime = pickedTime;
              endTimeController.text = endTime!.format(context);
            }
          });
        }
      }
    }

    return Form(
      key: formKey,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              height: Device.getHeight(50) + bottomInset,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  topRight: Radius.circular(12.0),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  top: 8.0,
                  bottom: bottomInset,
                ),
                child: Column(
                  children: [
                    const Text(
                      '일정 만들기',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: '시작 시간',
                            isTime: true,
                            controller: startTimeController,
                            onTap: () => pickTime(context, true),
                            onSaved: (value) {},
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '시작 시간을 선택해주세요';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: CustomTextField(
                            label: '종료 시간',
                            isTime: true,
                            controller: endTimeController,
                            onTap: () => pickTime(context, false),
                            onSaved: (value) {},
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '종료 시간을 선택해주세요';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: CustomTextField(
                        label: '내용',
                        isTime: false,
                        controller: contentController,
                        onSaved: (val) {
                          content = val;
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "값을 입력해주세요";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onSavePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.color.primaryColor,
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0)
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
