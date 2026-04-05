import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 긴급 팝업 공지
///
/// - Firestore app_config/popup에서 활성 팝업 조회
/// - 오늘 안 보기 지원 (SharedPreferences)
/// - 타입별 색상: emergency(빨강), notice(파랑), event(초록)
class PopupNotice {
  static Future<void> check(BuildContext context) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('popup')
          .get();

      if (!doc.exists) return;
      final data = doc.data()!;
      if (data['active'] != true) return;

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final startDate = data['startDate'] as String? ?? '';
      final endDate = data['endDate'] as String? ?? '';
      if (startDate.isNotEmpty && todayStr.compareTo(startDate) < 0) return;
      if (endDate.isNotEmpty && todayStr.compareTo(endDate) > 0) return;

      final prefs = await SharedPreferences.getInstance();
      final dismissKey = 'popup_dismissed_$todayStr';
      if (prefs.getBool(dismissKey) == true) return;

      if (!context.mounted) return;

      final title = data['title'] as String? ?? '공지';
      final content = data['content'] as String? ?? '';
      final type = data['type'] as String? ?? 'notice';
      final dismissible = data['dismissible'] ?? true;

      Color color;
      IconData icon;
      switch (type) {
        case 'emergency':
          color = Colors.red;
          icon = Icons.warning_amber_rounded;
          break;
        case 'event':
          color = const Color(0xFF4CAF50);
          icon = Icons.celebration;
          break;
        default:
          color = AppColors.theme.primaryColor;
          icon = Icons.campaign;
      }

      showDialog(
        context: context,
        barrierDismissible: dismissible,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return PopScope(
            canPop: dismissible,
            child: Dialog(
              backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 30, color: color),
                    ),
                    const SizedBox(height: 16),
                    Text(title, style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 12),
                    Text(content, style: TextStyle(
                      fontSize: 14, color: AppColors.theme.darkGreyColor, height: 1.6),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('확인'),
                      ),
                    ),
                    if (dismissible) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          prefs.setBool(dismissKey, true);
                          Navigator.pop(ctx);
                        },
                        child: Text('오늘 하루 안 보기',
                          style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (_) {}
  }
}
