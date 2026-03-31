import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 프로필 설정 화면
///
/// - 신분 선택 (재학생/졸업생/교사/학부모)
/// - 신분별 추가 정보 입력
/// - 새 학기 프로필 업데이트에도 사용
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요')));
      return;
    }

    if (_userType == 'student' && _studentIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학번을 입력해주세요')));
      return;
    }

    setState(() => _isSaving = true);

    final user = AuthService.currentUser;
    if (user == null) return;

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
    );

    await AuthService.saveUserProfile(profile);
    AuthService.clearProfileCache();

    if (!widget.isUpdate) {
      _notifyAdminsNewSignup(name);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _notifyAdminsNewSignup(String name) async {
    try {
      final admins = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['admin', 'manager']).get();
      for (var doc in admins.docs) {
        await FirebaseFirestore.instance
            .collection('users').doc(doc.id).collection('notifications').add({
          'type': 'account',
          'postId': '',
          'postTitle': '가입 요청',
          'senderName': name,
          'content': '$name님이 가입을 요청했습니다.',
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
          title: Text(widget.isUpdate ? '프로필 업데이트' : '정보 입력'),
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
                Text(widget.isUpdate ? '새 학기 정보를 업데이트해주세요' : '환영합니다!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 8),
                Text(widget.isUpdate ? '학번, 학년/반을 확인해주세요' : '기본 정보를 입력해주세요',
                  style: TextStyle(fontSize: 14, color: AppColors.theme.mealTypeTextColor)),
                const SizedBox(height: 28),

                _label('신분'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _typeChip('student', '재학생'),
                    _typeChip('graduate', '졸업생'),
                    _typeChip('teacher', '교사'),
                    _typeChip('parent', '학부모'),
                  ],
                ),
                const SizedBox(height: 20),

                _label('이름'),
                const SizedBox(height: 8),
                _textField(_nameController, '이름을 입력하세요', fillColor),
                const SizedBox(height: 20),

                if (_userType == 'student') ...[
                  _label('학번'),
                  const SizedBox(height: 8),
                  _textField(_studentIdController, '예: 20301', fillColor, keyboard: TextInputType.number),
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
                          Text('${SettingData().grade}학년 ${SettingData().classNum}반',
                            style: TextStyle(fontSize: 13, color: AppColors.theme.primaryColor)),
                        ],
                      ),
                    ),
                ],

                if (_userType == 'graduate') ...[
                  _label('졸업연도'),
                  const SizedBox(height: 8),
                  _textField(_gradYearController, '예: 2025', fillColor, keyboard: TextInputType.number),
                ],

                if (_userType == 'teacher') ...[
                  _label('담당과목 (선택)'),
                  const SizedBox(height: 8),
                  _textField(_teacherSubjectController, '예: 수학', fillColor),
                ],

                if (_userType == 'parent') ...[
                  const SizedBox(height: 8),
                  Text('학부모로 가입하면 게시판을 이용할 수 있습니다.',
                    style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor)),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.isUpdate ? '업데이트' : '완료',
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
