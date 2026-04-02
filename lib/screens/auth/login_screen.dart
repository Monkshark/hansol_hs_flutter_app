import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/main.dart';
import 'package:hansol_high_school/notification/fcm_service.dart';
import 'package:hansol_high_school/screens/auth/profile_setup_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

/// 로그인 화면 (LoginScreen)
///
/// - Google / Apple / Kakao 소셜 로그인 지원
/// - 로그인 성공 시 FCM 토큰 갱신
/// - 프로필 미설정 사용자는 프로필 설정 화면으로 자동 이동
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleLogin(Future<dynamic> Function() loginFn) async {
    setState(() => _isLoading = true);

    final user = await loginFn();

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

  Future<dynamic> _kakaoLogin() async {
    try {
      kakao.OAuthToken token;
      if (await kakao.isKakaoTalkInstalled()) {
        token = await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }
      return AuthService.signInWithKakao(token.accessToken);
    } catch (e) {
      return null;
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

              _loginButton(
                label: 'Google로 로그인',
                icon: Icons.g_mobiledata,
                iconColor: const Color(0xFF4285F4),
                bgColor: isDark ? const Color(0xFF1E2028) : Colors.white,
                borderColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE0E0E0),
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
                onTap: () => _handleLogin(AuthService.signInWithGoogle),
              ),

              const SizedBox(height: 10),

              if (Platform.isIOS) ...[
                _loginButton(
                  label: 'Apple로 로그인',
                  icon: Icons.apple,
                  iconColor: isDark ? Colors.white : Colors.black,
                  bgColor: isDark ? Colors.white.withAlpha(15) : Colors.black,
                  textColor: isDark ? Colors.white : Colors.white,
                  onTap: () => _handleLogin(AuthService.signInWithApple),
                ),
                const SizedBox(height: 10),
              ],

              _loginButton(
                label: 'Kakao로 로그인',
                icon: Icons.chat_bubble,
                iconColor: const Color(0xFF3C1E1E),
                bgColor: const Color(0xFFFEE500),
                textColor: const Color(0xFF3C1E1E),
                onTap: () => _handleLogin(_kakaoLogin),
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

  Widget _loginButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    Color? borderColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: iconColor),
                  const SizedBox(width: 10),
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                ],
              ),
      ),
    );
  }
}
