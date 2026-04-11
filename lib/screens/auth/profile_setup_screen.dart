import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isUpdate;

  const ProfileSetupScreen({Key? key, this.isUpdate = false}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _gradYearController = TextEditingController();
  final _teacherSubjectController = TextEditingController();
  String _userType = 'student';
  bool _isSaving = false;
  bool _privacyAgreed = false;

  @override
  void initState() {
    super.initState();
    if (widget.isUpdate) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final profile = await AuthService.getUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _nameController.text = profile.name;
        _userType = profile.userType;
        _studentIdController.text = profile.studentId;
        if (profile.graduationYear != null) {
          _gradYearController.text = profile.graduationYear.toString();
        }
        if (profile.teacherSubject != null) {
          _teacherSubjectController.text = profile.teacherSubject!;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _gradYearController.dispose();
    _teacherSubjectController.dispose();
    super.dispose();
  }

  String? _validateStudentId(String id, String msg) {
    if (id.isEmpty || id.length != 5 || int.tryParse(id) == null) return msg;
    final grade = int.parse(id[0]);
    final classNum = int.parse(id.substring(1, 3));
    final number = int.parse(id.substring(3, 5));
    if (grade < 1 || grade > 3 || classNum < 1 || classNum > 12 || number < 1 || number > 30) return msg;
    return null;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileSetup_nameRequired)));
      return;
    }
    if (name.contains(' ')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileSetup_nameNoSpace)));
      return;
    }

    if (_userType == 'student') {
      final error = _validateStudentId(_studentIdController.text.trim(), AppLocalizations.of(context)!.profileSetup_studentIdError);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isSaving = false);
        return;
      }

      String provider = 'google';
      if (user.uid.startsWith('kakao:')) {
        provider = 'kakao';
      } else if (user.providerData.any((p) => p.providerId == 'apple.com')) {
        provider = 'apple';
      } else if (user.providerData.any((p) => p.providerId == 'github.com')) {
        provider = 'github';
      }

      final profile = UserProfile(
        uid: user.uid,
        name: name,
        studentId: _userType == 'student' ? _studentIdController.text.trim() : '',
        grade: _userType == 'student' ? SettingData().grade : 0,
        classNum: _userType == 'student' ? SettingData().classNum : 0,
        email: user.email ?? '',
        userType: _userType,
        lastProfileUpdate: DateTime.now().year.toString(),
        graduationYear: _userType == 'graduate' ? int.tryParse(_gradYearController.text.trim()) : null,
        teacherSubject: _userType == 'teacher' ? _teacherSubjectController.text.trim() : null,
        loginProvider: provider,
      );

      await AuthService.saveUserProfile(profile);
      AuthService.clearProfileCache();

      if (!widget.isUpdate) {
        final signupTitle = AppLocalizations.of(context)!.profileSetup_signupRequest;
        final signupContent = AppLocalizations.of(context)!.profileSetup_signupNotification(name);
        _notifyAdminsNewSignup(name, signupTitle, signupContent);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('ProfileSetup: save failed: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileSetup_saveFailed)));
      }
    }
  }

  Future<void> _notifyAdminsNewSignup(String name, String postTitle, String content) async {
    try {
      final admins = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['admin', 'manager']).get();
      for (var doc in admins.docs) {
        await FirebaseFirestore.instance
            .collection('users').doc(doc.id).collection('notifications').add({
          'type': 'account',
          'postId': '',
          'postTitle': postTitle,
          'senderName': name,
          'content': content,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final fillColor = isDark ? const Color(0xFF1E2028) : const Color(0xFFF5F5F5);

    return PopScope(
      canPop: !widget.isUpdate,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          title: Text(widget.isUpdate ? AppLocalizations.of(context)!.profileSetup_updateTitle : AppLocalizations.of(context)!.profileSetup_setupTitle),
          centerTitle: true,
          automaticallyImplyLeading: !widget.isUpdate,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(widget.isUpdate ? AppLocalizations.of(context)!.profileSetup_updateSubtitle : AppLocalizations.of(context)!.profileSetup_setupSubtitle,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 8),
                Text(widget.isUpdate ? AppLocalizations.of(context)!.profileSetup_updateHint : AppLocalizations.of(context)!.profileSetup_setupHint,
                  style: TextStyle(fontSize: 14, color: AppColors.theme.mealTypeTextColor)),
                const SizedBox(height: 28),

                _label(AppLocalizations.of(context)!.profileSetup_userType),
                const SizedBox(height: 8),
                if (widget.isUpdate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.theme.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: AppColors.theme.primaryColor),
                        const SizedBox(width: 6),
                        Text(_userTypeLabel(_userType),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.theme.primaryColor)),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: [
                      _typeChip('student', AppLocalizations.of(context)!.profileSetup_student),
                      _typeChip('graduate', AppLocalizations.of(context)!.profileSetup_graduate),
                      _typeChip('teacher', AppLocalizations.of(context)!.profileSetup_teacher),
                      _typeChip('parent', AppLocalizations.of(context)!.profileSetup_parent),
                    ],
                  ),
                const SizedBox(height: 20),

                _label(AppLocalizations.of(context)!.profileSetup_name),
                const SizedBox(height: 8),
                _textField(_nameController, AppLocalizations.of(context)!.profileSetup_nameHint, fillColor),
                const SizedBox(height: 20),

                if (_userType == 'student') ...[
                  _label(AppLocalizations.of(context)!.profileSetup_studentId),
                  const SizedBox(height: 8),
                  _textField(_studentIdController, AppLocalizations.of(context)!.profileSetup_studentIdHint, fillColor, keyboard: TextInputType.number),
                  const SizedBox(height: 12),
                  if (SettingData().isGradeSet)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.theme.primaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.school, size: 18, color: AppColors.theme.primaryColor),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.profileSetup_gradeClass(SettingData().grade, SettingData().classNum),
                            style: TextStyle(fontSize: 13, color: AppColors.theme.primaryColor)),
                        ],
                      ),
                    ),
                ],

                if (_userType == 'graduate') ...[
                  _label(AppLocalizations.of(context)!.profileSetup_graduationYear),
                  const SizedBox(height: 8),
                  _textField(_gradYearController, AppLocalizations.of(context)!.profileSetup_graduationYearHint, fillColor, keyboard: TextInputType.number),
                ],

                if (_userType == 'teacher') ...[
                  _label(AppLocalizations.of(context)!.profileSetup_teacherSubject),
                  const SizedBox(height: 8),
                  _textField(_teacherSubjectController, AppLocalizations.of(context)!.profileSetup_teacherSubjectHint, fillColor),
                ],

                if (_userType == 'parent') ...[
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.profileSetup_parentInfo,
                    style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor)),
                ],

                if (!widget.isUpdate) ...[
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => setState(() => _privacyAgreed = !_privacyAgreed),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 22, height: 22, child: Checkbox(
                          value: _privacyAgreed,
                          onChanged: (v) => setState(() => _privacyAgreed = v ?? false),
                          activeColor: AppColors.theme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(AppLocalizations.of(context)!.profileSetup_privacyTitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: _privacyAgreed ? (isDark ? Colors.white : Colors.black87) : AppColors.theme.darkGreyColor)),
                          const SizedBox(height: 4),
                          Text(AppLocalizations.of(context)!.profileSetup_privacyDescription,
                            style: TextStyle(fontSize: 11, color: AppColors.theme.darkGreyColor, height: 1.5)),
                        ])),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: (_isSaving || (!widget.isUpdate && !_privacyAgreed)) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.isUpdate ? AppLocalizations.of(context)!.profileSetup_updateButton : AppLocalizations.of(context)!.profileSetup_completeButton,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.theme.darkGreyColor));

  Widget _textField(TextEditingController controller, String hint, Color fillColor,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _typeChip(String type, String label) {
    final selected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor,
          ),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.theme.darkGreyColor)),
      ),
    );
  }
}
