import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/main.dart' show providerContainer;
import 'package:hansol_high_school/providers/auth_provider.dart';
import 'package:hansol_high_school/providers/settings_provider.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

const List<String> _schoolDomains = [
  'edu.sje.go.kr',
  'sjhansol.sjeduhs.kr',
];

class EmailVerificationScreen extends StatefulWidget {
  final bool dismissible;

  const EmailVerificationScreen({super.key, this.dismissible = true});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _localPartController = TextEditingController();
  final _otpController = TextEditingController();
  String _selectedDomain = _schoolDomains.first;

  bool _otpSent = false;
  bool _isSending = false;
  bool _isVerifying = false;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _localPartController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _fullEmail => '${_localPartController.text.trim()}@$_selectedDomain';

  Future<void> _pickDomain() async {
    final l = AppLocalizations.of(context)!;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF1E2028) : Colors.white;
        final textColor = Theme.of(ctx).textTheme.bodyLarge?.color ?? Colors.black;
        int tempIndex = _schoolDomains.indexOf(_selectedDomain);
        if (tempIndex < 0) tempIndex = 0;
        final controller = FixedExtentScrollController(initialItem: tempIndex);

        return Dialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.emailVerify_pickDomainTitle,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: CupertinoPicker(
                    scrollController: controller,
                    itemExtent: 40,
                    diameterRatio: 1.2,
                    selectionOverlay: Container(
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(color: AppColors.theme.primaryColor.withAlpha(80)),
                        ),
                      ),
                    ),
                    onSelectedItemChanged: (i) => tempIndex = i,
                    children: _schoolDomains
                        .map((d) => Center(
                              child: Text('@$d',
                                  style: TextStyle(fontSize: 17, color: textColor)),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(_schoolDomains[tempIndex]),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(l.common_confirm,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedDomain = picked);
    }
  }

  Future<void> _sendOtp() async {
    final l = AppLocalizations.of(context)!;
    final localPart = _localPartController.text.trim();
    if (localPart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.emailVerify_localPartRequired)),
      );
      return;
    }
    if (RegExp(r'\s|@').hasMatch(localPart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.emailVerify_localPartInvalid)),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('sendSchoolEmailOTP')
          .call({'email': _fullEmail});
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _isSending = false;
        _resendCountdown = 120;
      });
      _startResendTimer();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapSendError(e, l))),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.emailVerify_sendFailed)),
      );
    }
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _resendCountdown <= 0) return false;
      setState(() => _resendCountdown--);
      return _resendCountdown > 0;
    });
  }

  Future<void> _verifyOtp() async {
    final l = AppLocalizations.of(context)!;
    final code = _otpController.text.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.emailVerify_otpFormatError)),
      );
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('verifySchoolEmailOTP')
          .call({'code': code});
      AuthService.clearProfileCache();
      await providerContainer.read(userProfileProvider.notifier).refresh();
      providerContainer.read(appRefreshProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.emailVerify_success)),
      );
      Navigator.of(context).pop(true);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapVerifyError(e, l))),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.emailVerify_failed)),
      );
    }
  }

  String _mapSendError(FirebaseFunctionsException e, AppLocalizations l) {
    switch (e.code) {
      case 'invalid-argument':
        return l.emailVerify_domainNotAllowed;
      case 'resource-exhausted':
        return e.message ?? l.emailVerify_rateLimited;
      case 'unauthenticated':
        return l.verify_login_required;
      default:
        return l.emailVerify_sendFailed;
    }
  }

  String _mapVerifyError(FirebaseFunctionsException e, AppLocalizations l) {
    switch (e.code) {
      case 'deadline-exceeded':
        return l.emailVerify_codeExpired;
      case 'resource-exhausted':
        return l.emailVerify_attemptsExceeded;
      case 'not-found':
        return l.emailVerify_codeNotFound;
      case 'invalid-argument':
        return l.emailVerify_codeMismatch;
      default:
        return l.emailVerify_failed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final fillColor = isDark ? const Color(0xFF1E2028) : const Color(0xFFF5F5F5);

    return PopScope(
      canPop: widget.dismissible,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          title: Text(l.emailVerify_title),
          centerTitle: true,
          automaticallyImplyLeading: widget.dismissible,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(l.emailVerify_subtitle,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 8),
                Text(l.emailVerify_hint,
                    style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor, height: 1.5)),
                const SizedBox(height: 32),

                _label(l.emailVerify_emailLabel),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _localPartController,
                        enabled: !_otpSent,
                        decoration: InputDecoration(
                          hintText: l.emailVerify_localPartHint,
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('@', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      flex: 7,
                      child: GestureDetector(
                        onTap: _otpSent ? null : _pickDomain,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: fillColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(_selectedDomain,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14, color: textColor)),
                              ),
                              Icon(Icons.expand_more,
                                  size: 18, color: AppColors.theme.darkGreyColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (!_otpSent) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(l.emailVerify_sendCode,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ] else ...[
                  _label(l.emailVerify_codeLabel),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      filled: true,
                      fillColor: fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l.emailVerify_codeSentTo(_fullEmail),
                      style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(l.emailVerify_verify,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          _otpSent = false;
                          _otpController.clear();
                        }),
                        child: Text(l.emailVerify_changeEmail,
                            style: TextStyle(color: AppColors.theme.darkGreyColor)),
                      ),
                      Text('·', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                      TextButton(
                        onPressed: (_resendCountdown > 0 || _isSending) ? null : _sendOtp,
                        child: Text(
                          _resendCountdown > 0
                              ? l.emailVerify_resendIn(_resendCountdown)
                              : l.emailVerify_resend,
                          style: TextStyle(
                            color: _resendCountdown > 0
                                ? AppColors.theme.darkGreyColor
                                : AppColors.theme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (widget.dismissible) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        l.emailVerify_skip,
                        style: TextStyle(color: AppColors.theme.darkGreyColor),
                      ),
                    ),
                  ),
                ],

                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.theme.darkGreyColor));
}
