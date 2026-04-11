import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionSheet {
  static Future<bool> show(BuildContext context, {bool openSettings = false}) async {
    final l = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _Sheet(l: l, openSettings: openSettings),
    );
    return result ?? false;
  }
}

class _Sheet extends StatelessWidget {
  final AppLocalizations l;
  final bool openSettings;

  const _Sheet({required this.l, required this.openSettings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E2028) : Colors.white;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.theme.lightGreyColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.theme.primaryColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active_rounded, size: 36, color: AppColors.theme.primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            l.notiPermission_title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            openSettings ? l.notiPermission_settingsDesc : l.notiPermission_desc,
            style: TextStyle(fontSize: 15, color: AppColors.theme.darkGreyColor, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (openSettings) {
                  await openAppSettings();
                } else {
                  await Permission.notification.request();
                }
                if (context.mounted) Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                openSettings ? l.notiPermission_openSettings : l.notiPermission_allow,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                l.notiPermission_later,
                style: TextStyle(fontSize: 16, color: AppColors.theme.darkGreyColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
