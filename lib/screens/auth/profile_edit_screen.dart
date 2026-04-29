import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/widgets/error_snackbar.dart';
import 'package:hansol_high_school/main.dart' show providerContainer;
import 'package:hansol_high_school/providers/settings_provider.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  String? _profilePhotoUrl;
  File? _newPhoto;
  bool _isSaving = false;
  bool _isLoading = true;

  String _name = '';
  String _userType = '';
  String _studentId = '';
  String _email = '';
  int? _graduationYear;
  String? _teacherSubject;
  int _grade = 0;
  int _classNum = 0;
  String _loginProvider = 'google';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.getUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _name = profile.name;
        _userType = profile.userType;
        _studentId = profile.studentId;
        _email = profile.email;
        _profilePhotoUrl = profile.profilePhotoUrl;
        _graduationYear = profile.graduationYear;
        _teacherSubject = profile.teacherSubject;
        _grade = profile.grade;
        _classNum = profile.classNum;
        _loginProvider = profile.loginProvider;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2028) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.camera_alt, color: isDark ? Colors.white70 : Colors.black87),
                title: Text(AppLocalizations.of(context)!.profileEdit_camera, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: isDark ? Colors.white70 : Colors.black87),
                title: Text(AppLocalizations.of(context)!.profileEdit_gallery, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (_profilePhotoUrl != null || _newPhoto != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: Text(AppLocalizations.of(context)!.profileEdit_deletePhoto, style: const TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removePhoto();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512);
    if (picked == null) return;

    final compressed = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      '${picked.path}_compressed.jpg',
      quality: 70,
      minWidth: 256,
      minHeight: 256,
    );

    if (compressed != null && mounted) {
      setState(() => _newPhoto = File(compressed.path));
      _savePhoto();
    }
  }

  Future<void> _savePhoto() async {
    setState(() => _isSaving = true);
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return;

      final ref = FirebaseStorage.instance.ref().child('profile_photos/$uid.jpg');
      await ref.putFile(_newPhoto!);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profilePhotoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AuthService.clearProfileCache();
      setState(() {
        _profilePhotoUrl = url;
        _newPhoto = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileEdit_photoChangedSuccess)));
      }
    } catch (e) {
      log('ProfileEdit: photo change error: $e');
      if (mounted) showErrorSnackbar(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _isSaving = true);
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profilePhotoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AuthService.clearProfileCache();
      setState(() {
        _profilePhotoUrl = null;
        _newPhoto = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileEdit_photoDeletedSuccess)));
      }
    } catch (e) {
      log('ProfileEdit: photo delete error: $e');
      if (mounted) showErrorSnackbar(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final profile = AuthService.cachedProfile ?? await AuthService.getUserProfile();
    if (!mounted) return;
    if (profile?.isSuspended == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.withdraw_blockedSuspended)));
      return;
    }

    final confirm1 = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _withdrawGraceSheet(ctx, isDark),
    );
    if (confirm1 != true) return;
    if (!mounted) return;

    final userEmail = AuthService.currentUser?.email ?? _email;
    final confirmValue = userEmail.isNotEmpty ? userEmail : _name;
    final confirmLabel = userEmail.isNotEmpty ? l10n.profileEdit_emailLabel : l10n.profileEdit_nameLabel;
    final confirm2 = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _deleteConfirmSheet(ctx, isDark, confirmValue, confirmLabel),
    );
    if (confirm2 != true) return;

    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      await FirebaseFunctions.instance
          .httpsCallable('requestAccountDeletion')
          .call();

      await AuthService.signOut();
      AuthService.clearProfileCache();
      providerContainer.read(appRefreshProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.withdraw_scheduled)));
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      log('ProfileEdit: withdrawal error: $e');
      if (mounted) showErrorSnackbar(context, e);
    }
  }

  Widget _withdrawGraceSheet(BuildContext ctx, bool isDark) {
    final l10n = AppLocalizations.of(ctx)!;
    final textColor = Theme.of(ctx).textTheme.bodyLarge?.color;
    final subColor = AppColors.theme.darkGreyColor;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2))),
            Text(l10n.withdraw_graceTitle,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 12),
            Text(l10n.withdraw_graceBody,
              style: TextStyle(fontSize: 14, height: 1.5, color: subColor)),
            const SizedBox(height: 8),
            Text(l10n.withdraw_anonymizeNotice,
              style: TextStyle(fontSize: 13, height: 1.5, color: subColor)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.common_cancel),
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.withdraw_confirmAction),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  String _userTypeLabel(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'student': return l10n.profileSetup_student;
      case 'graduate': return l10n.profileSetup_graduate;
      case 'teacher': return l10n.profileSetup_teacher;
      case 'parent': return l10n.profileSetup_parent;
      default: return type;
    }
  }

  String _providerLabel(String p) {
    switch (p) {
      case 'kakao': return 'Kakao';
      case 'apple': return 'Apple';
      case 'github': return 'GitHub';
      default: return 'Google';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = isDark ? const Color(0xFF1E2028) : Colors.white;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: textColor, elevation: 0,
          title: Text(AppLocalizations.of(context)!.profileEdit_accountTitle), centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_isSaving) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileEdit_savingPhotoBlockExit),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor, elevation: 0,
        title: Text(AppLocalizations.of(context)!.profileEdit_accountTitle), centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 32),
        child: Column(
          children: [
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isSaving ? null : _pickPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.theme.primaryColor.withAlpha(30),
                    backgroundImage: _newPhoto != null
                        ? FileImage(_newPhoto!)
                        : (_profilePhotoUrl != null
                            ? CachedNetworkImageProvider(_profilePhotoUrl!)
                            : null) as ImageProvider?,
                    child: (_newPhoto == null && _profilePhotoUrl == null)
                        ? Text(
                            _name.isNotEmpty ? _name[0] : '?',
                            style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700,
                              color: AppColors.theme.primaryColor),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.theme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2.5),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(_name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.theme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_userTypeLabel(_userType),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.theme.primaryColor)),
            ),

            const SizedBox(height: 28),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (_userType == 'student') ...[
                    _infoRow(AppLocalizations.of(context)!.profileEdit_studentId, _studentId),
                    if (_grade > 0) _infoRow(AppLocalizations.of(context)!.profileEdit_gradeClass, AppLocalizations.of(context)!.profileSetup_gradeClass(_grade, _classNum)),
                  ],
                  if (_userType == 'graduate' && _graduationYear != null)
                    _infoRow(AppLocalizations.of(context)!.profileEdit_graduationYear, '$_graduationYear'),
                  if (_userType == 'teacher' && _teacherSubject != null && _teacherSubject!.isNotEmpty)
                    _infoRow(AppLocalizations.of(context)!.profileEdit_teacherSubject, _teacherSubject!),
                  if (_email.isNotEmpty)
                    _infoRow(AppLocalizations.of(context)!.profileEdit_emailLabel, _email),
                  _infoRow(AppLocalizations.of(context)!.profileEdit_loginProvider, _providerLabel(_loginProvider)),
                ],
              ),
            ),

            const SizedBox(height: 48),

            GestureDetector(
              onTap: _deleteAccount,
              child: Text(AppLocalizations.of(context)!.profileEdit_deleteAccountTitle,
                style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor,
                  decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(
              fontSize: 13, color: AppColors.theme.darkGreyColor, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(
              fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _deleteConfirmSheet(BuildContext ctx, bool isDark, String confirmValue, String confirmLabel) {
    final controller = TextEditingController();
    bool matched = false;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2028) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.profileEdit_finalConfirmTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(AppLocalizations.of(context)!.profileEdit_finalConfirmMessage(confirmLabel),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.theme.darkGreyColor, height: 1.5))),
            const SizedBox(height: 4),
            Text(confirmValue, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.theme.primaryColor)),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.profileEdit_inputPlaceholder(confirmLabel),
                  hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (v) => setSheetState(() => matched = v.trim() == confirmValue),
              )),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
              Expanded(child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.common_cancel, style: TextStyle(color: AppColors.theme.darkGreyColor)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: matched ? () => Navigator.pop(ctx, true) : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: Text(AppLocalizations.of(context)!.profileEdit_withdrawButton),
              )),
            ])),
            const SizedBox(height: 12),
          ]),
        )),
      ),
    );
  }

}
