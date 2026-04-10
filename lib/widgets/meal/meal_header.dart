import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';

/// 급식 화면 날짜 헤더
/// - 선택된 날짜를 "M월 d일 (요일)" 한국어 형식으로 표시
/// - 오늘 날짜일 경우 '오늘' 뱃지를 함께 렌더링
/// - primaryColor 기반 뱃지 스타일 적용
class MealHeader extends StatelessWidget {
  final DateTime selectedDate;

  const MealHeader({required this.selectedDate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Text(
            DateFormat('M월 d일 (E)', 'ko_KR').format(selectedDate),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.theme.primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppLocalizations.of(context)!.meal_today,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.theme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
