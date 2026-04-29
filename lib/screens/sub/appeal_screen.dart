import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/providers/auth_provider.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class AppealScreen extends ConsumerStatefulWidget {
  const AppealScreen({super.key});

  @override
  ConsumerState<AppealScreen> createState() => _AppealScreenState();
}

class _AppealScreenState extends ConsumerState<AppealScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;
  bool _alreadySubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final query = await FirebaseFirestore.instance
        .collection('appeals')
        .where('uid', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'reviewing'])
        .limit(1)
        .get();
    if (!mounted) return;
    setState(() => _alreadySubmitted = query.docs.isNotEmpty);
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    final text = _controller.text.trim();
    if (text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.appeal_tooShort)),
      );
      return;
    }
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance.collection('appeals').add({
        'uid': uid,
        'content': text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.appeal_submitted)),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor = AppColors.theme.mealTypeTextColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l.appeal_title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.appeal_intro, style: TextStyle(fontSize: 14, color: subColor)),
              const SizedBox(height: 12),
              if (profile?.suspendReason != null && profile!.suspendReason!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2D35) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(l.suspend_banner_reason(profile.suspendReason!),
                    style: TextStyle(fontSize: 13, color: subColor)),
                ),
              const SizedBox(height: 16),
              if (_alreadySubmitted)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(l.appeal_alreadySubmitted,
                    style: const TextStyle(color: Color(0xFF92400E))),
                )
              else ...[
                TextField(
                  controller: _controller,
                  maxLength: 500,
                  minLines: 6, maxLines: 12,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l.appeal_hint,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    counterText: l.appeal_charCount(_controller.text.length),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(l.appeal_submit, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
