import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 학사일정 카드 위젯
/// - 왼쪽에 secondaryColor 컬러바로 학사일정 시각 표시
/// - 오른쪽에 '학사' 뱃지를 표시하여 개인일정과 구분
/// - 다크/라이트 테마 자동 대응
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: AppColors.theme.secondaryColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.theme.secondaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '학사',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.theme.secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
