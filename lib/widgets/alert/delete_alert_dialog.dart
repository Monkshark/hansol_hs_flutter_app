import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 삭제 확인 다이얼로그
/// - 제목과 안내 메시지를 표시하는 확인 다이얼로그
/// - '취소'(false) / '삭제'(true) 버튼으로 반환
/// - 다크/라이트 테마 자동 대응
class DeleteAlertDialog extends StatelessWidget {
  const DeleteAlertDialog({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 12),
            Text(content, style: TextStyle(
              fontSize: 14, color: AppColors.theme.mealTypeTextColor),
              textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF2A2D35) : const Color(0xFFF0F0F0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('취소', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('삭제'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
