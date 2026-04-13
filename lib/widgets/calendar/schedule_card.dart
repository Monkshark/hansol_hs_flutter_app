import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleCard extends StatelessWidget {
  final int startTimeInMinutes;
  final int endTimeInMinutes;
  final String content;
  final int color;
  final String? endDate;
  final String? date;

  const ScheduleCard({
    required this.startTimeInMinutes,
    required this.endTimeInMinutes,
    required this.content,
    this.color = 0xFF3F72AF,
    this.endDate,
    this.date,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Color(color);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: cardColor, width: 3),
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
          if (endDate != null && date != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_formatDate(date!)} ~ ${_formatDate(endDate!)}',
              style: TextStyle(fontSize: 12, color: cardColor),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('M/d').format(dt);
    } catch (e) {
      log('ScheduleCard: date parse error: $e');
      return isoDate;
    }
  }
}
