import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/**
 * Firestore 기반 앱 버전 체크
 * - Firestore app_config/version 문서에서 최신/최소 버전 조회
 * - 현재 버전과 비교하여 필수 업데이트 또는 선택 업데이트 판별
 * - 필수 업데이트 시 닫기 불가능한 다이얼로그 표시
 * - 업데이트 URL로 스토어 이동 지원
 */
class UpdateChecker {
  static Future<void> check(BuildContext context) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version')
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final latestVersion = data['latest'] as String? ?? '';
      final minVersion = data['min'] as String? ?? '';
      final updateUrl = data['updateUrl'] as String? ?? '';
      final updateMessage = data['message'] as String? ?? '새로운 버전이 출시되었습니다.';

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final forceUpdate = _compareVersions(currentVersion, minVersion) < 0;
      final optionalUpdate = _compareVersions(currentVersion, latestVersion) < 0;

      if (!forceUpdate && !optionalUpdate) return;
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: !forceUpdate,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return PopScope(
            canPop: !forceUpdate,
            child: Dialog(
              backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.system_update,
                      size: 48, color: AppColors.theme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      forceUpdate ? '필수 업데이트' : '업데이트 안내',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: Theme.of(ctx).textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      updateMessage,
                      style: TextStyle(fontSize: 14, color: AppColors.theme.darkGreyColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentVersion → $latestVersion',
                      style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (updateUrl.isNotEmpty) {
                            launchUrl(Uri.parse(updateUrl), mode: LaunchMode.externalApplication);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('업데이트'),
                      ),
                    ),
                    if (!forceUpdate) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('나중에', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (_) {
    }
  }

  static int _compareVersions(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final aParts = a.split('.').map(int.parse).toList();
    final bParts = b.split('.').map(int.parse).toList();
    final len = aParts.length > bParts.length ? aParts.length : bParts.length;

    for (int i = 0; i < len; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av < bv) return -1;
      if (av > bv) return 1;
    }
    return 0;
  }
}
