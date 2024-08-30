import 'package:flutter/material.dart';
import 'package:hansol_high_school/Styles/app_colors.dart';

class _Time extends StatelessWidget {
  final int startTime;
  final int endTime;

  const _Time({
    required this.startTime,
    required this.endTime,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: AppColors.color.secondaryColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${startTime.toString()}:40 AM',
          style: textStyle,
        ),
        Text(
          '${endTime.toString()}:20 PM',
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

class SchoolScheduleCard extends StatelessWidget {
  final int startTime;
  final int endTime;
  final String content;

  const SchoolScheduleCard({
    required this.startTime,
    required this.endTime,
    required this.content,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.0,
          color: AppColors.color.secondaryColor,
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
                startTime: startTime,
                endTime: endTime,
              ),
              const SizedBox(
                width: 16.0,
              ),
              _Content(
                content: "[학사일정] $content",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
