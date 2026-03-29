import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 프로필 설정 화면 (ProfileSetupScreen)
///
/// - 사용자 이름 및 학번 입력
/// - 입력값 유효성 검사 후 Firestore에 프로필 저장
/// - 최초 로그인 시 필수 진행 단계
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final studentId = _studentIdController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요')),
      );
      return;
    }
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학번을 입력해주세요')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = AuthService.currentUser;
    if (user == null) return;

    final profile = UserProfile(
      uid: user.uid,
      name: name,
      studentId: studentId,
      grade: SettingData().grade,
      classNum: SettingData().classNum,
      email: user.email ?? '',
    );

    await AuthService.saveUserProfile(profile);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        title: const Text('정보 입력'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('환영합니다!', style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 8),
              Text('기본 정보를 입력해주세요', style: TextStyle(
                fontSize: 14, color: AppColors.theme.mealTypeTextColor)),
              const SizedBox(height: 32),
              Text('이름', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.theme.darkGreyColor)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '이름을 입력하세요',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E2028) : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              Text('학번', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.theme.darkGreyColor)),
              const SizedBox(height: 8),
              TextField(
                controller: _studentIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '예: 20301',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E2028) : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
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
                      Text('${SettingData().grade}학년 ${SettingData().classNum}반 자동 연동',
                        style: TextStyle(fontSize: 13, color: AppColors.theme.primaryColor)),
                    ],
                  ),
                ),
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
                      : const Text('완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
