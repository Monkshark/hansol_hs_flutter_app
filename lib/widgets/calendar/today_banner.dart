import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';

/// 선택 날짜 + 일정 개수 배너
/// - 선택된 날짜를 "M월 d일 (요일)" 한국어 형식으로 표시
/// - 해당 날짜의 일정 개수를 primaryColor 뱃지로 렌더링
/// - 캘린더 화면 하단에 배치되는 정보 배너
class TodayBanner extends StatelessWidget {
  final DateTime selectedDate;
  final int count;

  const TodayBanner({
    required this.selectedDate,
    required this.count,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('M월 d일 (E)', 'ko_KR').format(selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.theme.primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
