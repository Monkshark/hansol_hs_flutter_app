import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class _Time extends StatelessWidget {
  final int startTimeInMinutes;
  final int endTimeInMinutes;

  const _Time({
    required this.startTimeInMinutes,
    required this.endTimeInMinutes,
    Key? key,
  }) : super(key: key);

  TimeOfDay _getTimeOfDay(int minutes) {
    final hours = minutes ~/ 60;
    final minutesPart = minutes % 60;
    return TimeOfDay(hour: hours, minute: minutesPart);
  }

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: AppColors.theme.primaryColor,
    );

    final startTime = _getTimeOfDay(startTimeInMinutes);
    final endTime = _getTimeOfDay(endTimeInMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          startTime.format(context),
          style: textStyle,
        ),
        Text(
          endTime.format(context),
          style: textStyle.copyWith(
            fontSize: 16.0,
          ),
        ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  final String content;

  const _Content({
    required this.content,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        content,
      ),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  final int startTimeInMinutes;
  final int endTimeInMinutes;
  final String content;

  const ScheduleCard({
    required this.startTimeInMinutes,
    required this.endTimeInMinutes,
    required this.content,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.0,
          color: AppColors.theme.primaryColor,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Time(
                startTimeInMinutes: startTimeInMinutes,
                endTimeInMinutes: endTimeInMinutes,
              ),
              const SizedBox(
                width: 16.0,
              ),
              _Content(
                content: content,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
