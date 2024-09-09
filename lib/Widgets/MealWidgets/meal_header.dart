import 'package:flutter/material.dart';
import 'package:hansol_high_school/Data/device.dart';
import 'package:hansol_high_school/Styles/app_colors.dart';
import 'package:intl/intl.dart';

class MealHeader extends StatefulWidget {
  final DateTime selectedDate;
  const MealHeader({
    required this.selectedDate,
    Key? key,
  }) : super(key: key);

  @override
  State<MealHeader> createState() => _MealHeaderState();
}

class _MealHeaderState extends State<MealHeader> {
  @override
  Widget build(BuildContext context) {
    bool isToday = DateFormat('yyyy-MM-dd').format(widget.selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      width: Device.getWidth(85),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: Device.getHeight(3),
                ),
                SizedBox(height: Device.getHeight(0.5)),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat("M월 d일 E요일", 'ko_KR')
                                .format(widget.selectedDate) +
                            (isToday ? " (오늘)" : ""),
                        style: TextStyle(
                          fontSize: Device.getWidth(6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      width: Device.getWidth(7),
                      height: Device.getWidth(7),
                      decoration: BoxDecoration(
                        color: AppColors.color.mealHeaderIconColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: IconButton(
                          onPressed: () => {},
                          icon: Icon(
                            Icons.keyboard_arrow_right_rounded,
                            color: AppColors.color.black,
                            size: Device.getWidth(7),
                          ),
                          constraints: BoxConstraints(
                            minWidth: Device.getWidth(7),
                            minHeight: Device.getWidth(7),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: Device.getHeight(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
