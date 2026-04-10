import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/main.dart';
import 'package:hansol_high_school/notification/fcm_service.dart';
import 'package:hansol_high_school/screens/auth/profile_setup_screen.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

/// 로그인 화면
///
/// - Google / Apple / Kakao / GitHub 소셜 로그인 (SVG 브랜드 로고)
/// - 로그인 성공 시 FCM 토큰 갱신 + getIdToken 재시도
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
        SnackBar(content: Text(AppLocalizations.of(context)!.login_canceled)),
      );
      return;
    }

    FcmService.onUserLogin();

    // auth 토큰 강제 갱신 후 프로필 확인 (최대 3회 재시도)
    await user.getIdToken(true);
    bool hasProfile = false;
    for (int i = 0; i < 3; i++) {
      hasProfile = await AuthService.hasProfile();
      if (hasProfile) break;
      await Future.delayed(const Duration(milliseconds: 300));
    }
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
      debugPrint('KakaoLogin: got access token, calling signInWithKakao...');
      final user = await AuthService.signInWithKakao(token.accessToken);
      debugPrint('KakaoLogin: result = $user');
      return user;
    } catch (e, st) {
      debugPrint('KakaoLogin error: $e\n$st');
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
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/images/app_icon.png', width: 80, height: 80),
              ),
              const SizedBox(height: 24),
              Text(AppLocalizations.of(context)!.login_schoolName, style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.login_subtitle,
                style: TextStyle(fontSize: 14, color: AppColors.theme.mealTypeTextColor)),
              const Spacer(flex: 3),

              _loginButton(
                label: AppLocalizations.of(context)!.login_googleContinue,
                svgAsset: 'assets/icons/google.svg',
                bgColor: isDark ? const Color(0xFF2A2D35) : Colors.white,
                borderColor: isDark ? const Color(0xFF3A3D45) : const Color(0xFFDADCE0),
                textColor: isDark ? Colors.white : const Color(0xFF3C4043),
                onTap: () => _handleLogin(AuthService.signInWithGoogle),
              ),

              const SizedBox(height: 10),

              if (Platform.isIOS) ...[
                _loginButton(
                  label: AppLocalizations.of(context)!.login_appleContinue,
                  svgAsset: 'assets/icons/apple.svg',
                  svgColor: Colors.white,
                  bgColor: Colors.black,
                  textColor: Colors.white,
                  onTap: () => _handleLogin(AuthService.signInWithApple),
                ),
                const SizedBox(height: 10),
              ],

              _loginButton(
                label: AppLocalizations.of(context)!.login_kakaoContinue,
                svgAsset: 'assets/icons/kakao.svg',
                svgColor: isDark ? const Color(0xFFFEE500) : const Color(0xFF181600),
                bgColor: isDark ? const Color(0xFF2A2D35) : const Color(0xFFFEE500),
                borderColor: isDark ? const Color(0xFF3A3D45) : null,
                textColor: isDark ? Colors.white : const Color(0xFF181600),
                onTap: () => _handleLogin(_kakaoLogin),
              ),

              const SizedBox(height: 10),

              _loginButton(
                label: AppLocalizations.of(context)!.login_githubContinue,
                svgAsset: 'assets/icons/github.svg',
                svgColor: Colors.white,
                bgColor: isDark ? const Color(0xFF2A2D35) : const Color(0xFF24292F),
                borderColor: isDark ? const Color(0xFF3A3D45) : null,
                textColor: Colors.white,
                onTap: () => _handleLogin(AuthService.signInWithGitHub),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.login_skipButton, style: TextStyle(color: AppColors.theme.mealTypeTextColor)),
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
    required String svgAsset,
    Color? svgColor,
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
                  SvgPicture.asset(svgAsset, width: 22, height: 22,
                    colorFilter: svgColor != null ? ColorFilter.mode(svgColor, BlendMode.srcIn) : null),
                  const SizedBox(width: 10),
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                ],
              ),
      ),
    );
  }
}
