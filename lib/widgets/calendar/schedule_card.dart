import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

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

  String _formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h < 12 ? '오전' : '오후';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $hour:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: AppColors.theme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          if (startTimeInMinutes >= 0 && endTimeInMinutes >= 0) ...[
            const SizedBox(height: 4),
            Text(
              '${_formatTime(startTimeInMinutes)} - ${_formatTime(endTimeInMinutes)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.theme.darkGreyColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
