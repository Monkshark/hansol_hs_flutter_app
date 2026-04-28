import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/main.dart' show providerContainer;
import 'package:hansol_high_school/notification/fcm_service.dart';
import 'package:hansol_high_school/providers/settings_provider.dart';
import 'package:hansol_high_school/screens/auth/profile_setup_screen.dart';
import 'package:hansol_high_school/screens/sub/setting_screen.dart' show PrivacyPolicyScreen;
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _agreeAge = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _showLoginButtons = false;

  bool get _allAgreed => _agreeAge && _agreeTerms && _agreePrivacy;

  void _toggleAll(bool? value) {
    final v = value ?? false;
    setState(() {
      _agreeAge = v;
      _agreeTerms = v;
      _agreePrivacy = v;
    });
    _maybeSlide();
  }

  void _maybeSlide() {
    if (_allAgreed && !_showLoginButtons) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        if (_allAgreed) setState(() => _showLoginButtons = true);
      });
    } else if (!_allAgreed && _showLoginButtons) {
      setState(() => _showLoginButtons = false);
    }
  }

  Future<void> _handleLogin(Future<dynamic> Function() loginFn) async {
    if (!_allAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.login_consentRequired)),
      );
      return;
    }
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

    await user.getIdToken(true);
    bool hasProfile = false;
    for (int i = 0; i < 3; i++) {
      hasProfile = await AuthService.hasProfile();
      if (hasProfile) break;
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;

    if (hasProfile) {
      final profile = await AuthService.getUserProfile();
      if (profile != null) {
        SettingData().restoreGradeIfNeeded(
          profileGrade: profile.grade,
          profileClassNum: profile.classNum,
        );
      }
      if (!mounted) return;
      AuthService.clearProfileCache();
      providerContainer.read(appRefreshProvider.notifier).refresh();
      Navigator.of(context).pop(true);
    } else {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
      if (result == true && mounted) {
        AuthService.clearProfileCache();
        providerContainer.read(appRefreshProvider.notifier).refresh();
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
    final l = AppLocalizations.of(context)!;

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
              Text(l.login_schoolName, style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 8),
              Text(l.login_subtitle,
                style: TextStyle(fontSize: 14, color: AppColors.theme.mealTypeTextColor)),
              const Spacer(flex: 3),

              Expanded(
                flex: 8,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(animation);
                    return SlideTransition(
                      position: slide,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: _showLoginButtons
                      ? _buildLoginButtons(isDark, l)
                      : _buildConsentBox(isDark, l),
                ),
              ),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.login_skipButton, style: TextStyle(color: AppColors.theme.mealTypeTextColor)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentBox(bool isDark, AppLocalizations l) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = AppColors.theme.mealTypeTextColor;
    final borderColor = isDark ? const Color(0xFF3A3D45) : const Color(0xFFE5E7EB);
    final bgColor = isDark ? const Color(0xFF2A2D35) : const Color(0xFFF9FAFB);

    return Container(
      key: const ValueKey('consent'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
            child: Text(l.login_consentTitle,
              style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.w500)),
          ),
          _consentTile(
            value: _allAgreed,
            label: l.login_consentAll,
            bold: true,
            textColor: textColor,
            onChanged: _toggleAll,
          ),
          Divider(height: 1, color: borderColor),
          _consentTile(
            value: _agreeAge,
            label: l.login_consentAge,
            textColor: textColor,
            onChanged: (v) {
              setState(() => _agreeAge = v ?? false);
              _maybeSlide();
            },
          ),
          _consentTile(
            value: _agreeTerms,
            label: l.login_consentTerms,
            textColor: textColor,
            trailing: _viewLink(l.login_consentTermsView),
            onChanged: (v) {
              setState(() => _agreeTerms = v ?? false);
              _maybeSlide();
            },
          ),
          _consentTile(
            value: _agreePrivacy,
            label: l.login_consentPrivacy,
            textColor: textColor,
            trailing: _viewLink(l.login_consentPrivacyView),
            onChanged: (v) {
              setState(() => _agreePrivacy = v ?? false);
              _maybeSlide();
            },
          ),
        ],
      ),
    );
  }

  Widget _consentTile({
    required bool value,
    required String label,
    required Color? textColor,
    bool bold = false,
    Widget? trailing,
    required ValueChanged<bool?> onChanged,
  }) {
    return Semantics(
      checked: value,
      toggled: value,
      label: label,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 28, height: 28,
                  child: ExcludeSemantics(
                    child: Checkbox(
                      value: value,
                      onChanged: onChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: TextStyle(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                  )),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewLink(String label) {
    return TextButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
      ),
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 32),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
    );
  }

  Widget _buildLoginButtons(bool isDark, AppLocalizations l) {
    return SingleChildScrollView(
      key: const ValueKey('buttons'),
      child: Column(
        children: [
          _loginButton(
            label: l.login_googleContinue,
            svgAsset: 'assets/icons/google.svg',
            bgColor: isDark ? const Color(0xFF2A2D35) : Colors.white,
            borderColor: isDark ? const Color(0xFF3A3D45) : const Color(0xFFDADCE0),
            textColor: isDark ? Colors.white : const Color(0xFF3C4043),
            onTap: () => _handleLogin(AuthService.signInWithGoogle),
          ),
          const SizedBox(height: 10),
          if (Platform.isIOS) ...[
            _loginButton(
              label: l.login_appleContinue,
              svgAsset: 'assets/icons/apple.svg',
              svgColor: Colors.white,
              bgColor: Colors.black,
              textColor: Colors.white,
              onTap: () => _handleLogin(AuthService.signInWithApple),
            ),
            const SizedBox(height: 10),
          ],
          _loginButton(
            label: l.login_kakaoContinue,
            svgAsset: 'assets/icons/kakao.svg',
            svgColor: isDark ? const Color(0xFFFEE500) : const Color(0xFF181600),
            bgColor: isDark ? const Color(0xFF2A2D35) : const Color(0xFFFEE500),
            borderColor: isDark ? const Color(0xFF3A3D45) : null,
            textColor: isDark ? Colors.white : const Color(0xFF181600),
            onTap: () => _handleLogin(_kakaoLogin),
          ),
          const SizedBox(height: 10),
          _loginButton(
            label: l.login_githubContinue,
            svgAsset: 'assets/icons/github.svg',
            svgColor: Colors.white,
            bgColor: isDark ? const Color(0xFF2A2D35) : const Color(0xFF24292F),
            borderColor: isDark ? const Color(0xFF3A3D45) : null,
            textColor: Colors.white,
            onTap: () => _handleLogin(AuthService.signInWithGitHub),
          ),
        ],
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
