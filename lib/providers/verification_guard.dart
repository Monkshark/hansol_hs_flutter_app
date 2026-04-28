import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/providers/auth_provider.dart';
import 'package:hansol_high_school/screens/sub/appeal_screen.dart';

class VerificationGuard {
  static Future<bool> check(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final profileAsync = ref.read(userProfileProvider);
    final profile = profileAsync.valueOrNull;

    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.verify_login_required)),
      );
      return false;
    }

    if (profile.isSuspended) {
      await _showSuspendedDialog(context, profile);
      return false;
    }

    if (!profile.isVerified) {
      await _showUnverifiedDialog(context, l);
      return false;
    }

    return true;
  }

  static Future<void> _showUnverifiedDialog(BuildContext context, AppLocalizations l) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.verify_required_title),
        content: Text(l.verify_required_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.verify_required_action),
          ),
        ],
      ),
    );
  }

  static Future<void> _showSuspendedDialog(BuildContext context, UserProfile profile) async {
    final l = AppLocalizations.of(context)!;
    String remaining;
    if (profile.suspendedUntil == null) {
      remaining = l.suspend_banner_permanent;
    } else {
      final days = profile.suspendedUntil!.difference(DateTime.now()).inDays + 1;
      remaining = l.suspend_banner_remaining(days);
    }
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.suspend_banner_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(remaining),
            if (profile.suspendReason != null && profile.suspendReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l.suspend_banner_reason(profile.suspendReason!)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AppealScreen()),
              );
            },
            child: Text(l.suspend_banner_appeal),
          ),
        ],
      ),
    );
  }
}

class SuspensionBanner extends ConsumerWidget {
  const SuspensionBanner({super.key, this.onAppeal});

  final VoidCallback? onAppeal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    if (profile == null || !profile.isSuspended) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String remaining;
    if (profile.suspendedUntil == null) {
      remaining = l.suspend_banner_permanent;
    } else {
      final days = profile.suspendedUntil!.difference(DateTime.now()).inDays + 1;
      remaining = l.suspend_banner_remaining(days);
    }

    return Semantics(
      liveRegion: true,
      label: '${l.suspend_banner_title}. $remaining',
      container: true,
      child: Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A2024) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l.suspend_banner_title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                  )),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(remaining, style: TextStyle(
            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
          )),
          if (profile.suspendReason != null && profile.suspendReason!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(l.suspend_banner_reason(profile.suspendReason!),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
              )),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: l.suspend_banner_appeal,
              child: TextButton(
                onPressed: onAppeal ?? () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppealScreen()),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
                child: Text(l.suspend_banner_appeal),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class UnverifiedBadge extends StatelessWidget {
  const UnverifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(l.verify_badge_unverified,
        style: const TextStyle(fontSize: 10, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600)),
    );
  }
}
