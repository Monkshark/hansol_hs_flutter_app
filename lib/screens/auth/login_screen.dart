/** Login screen with Google sign-in and navigation to profile setup for new users. */
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/main.dart';
import 'package:hansol_high_school/notification/fcm_service.dart';
import 'package:hansol_high_school/screens/auth/profile_setup_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/**
 * 로그인 화면 (LoginScreen)
 *
 * - Google 계정을 통한 소셜 로그인 처리
 * - 로그인 성공 시 FCM 토큰 갱신
 * - 프로필 미설정 사용자는 프로필 설정 화면으로 자동 이동
 */
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    final user = await AuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 취소되었습니다')),
      );
      return;
    }

    FcmService.onUserLogin();

    final hasProfile = await AuthService.hasProfile();
    if (!mounted) return;

    if (hasProfile) {
      AuthService.clearProfileCache();
      appRefreshNotifier.value++;
      Navigator.of(context).pop(true);
    } else {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
      if (result == true && mounted) {
        AuthService.clearProfileCache();
        appRefreshNotifier.value++;
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.theme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('HS', style: TextStyle(
                    color: Colors.white, fontSize: 32,
                    fontWeight: FontWeight.w800, letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 24),
              Text('한솔고등학교', style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 8),
              Text('로그인하면 더 많은 기능을 이용할 수 있어요',
                style: TextStyle(fontSize: 14, color: AppColors.theme.mealTypeTextColor)),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
                    foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE0E0E0)),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.g_mobiledata, size: 28, color: AppColors.theme.primaryColor),
                            const SizedBox(width: 8),
                            const Text('Google로 로그인',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('나중에 하기', style: TextStyle(color: AppColors.theme.mealTypeTextColor)),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
