import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/main.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 내 계정 화면
///
/// - 프로필 사진 변경
/// - 내 정보 카드 (읽기 전용)
/// - 회원 탈퇴
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

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
                title: Text('카메라', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: isDark ? Colors.white70 : Colors.black87),
                title: Text('갤러리', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (_profilePhotoUrl != null || _newPhoto != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('사진 삭제', style: TextStyle(color: Colors.redAccent)),
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
          const SnackBar(content: Text('프로필 사진이 변경되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 변경에 실패했습니다')));
      }
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
          const SnackBar(content: Text('프로필 사진이 삭제되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했습니다')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('정말 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('확인', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm1 != true) return;

    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('최종 확인'),
        content: const Text('회원 탈퇴를 진행합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('탈퇴', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm2 != true) return;

    try {
      final uid = AuthService.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      }
      await AuthService.currentUser?.delete();
      await AuthService.signOut();
      AuthService.clearProfileCache();
      appRefreshNotifier.value++;
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      log('Account deletion error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원 탈퇴에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    }
  }

  String _userTypeLabel(String type) {
    switch (type) {
      case 'student': return '재학생';
      case 'graduate': return '졸업생';
      case 'teacher': return '교사';
      case 'parent': return '학부모';
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
          title: const Text('내 계정'), centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor, elevation: 0,
        title: const Text('내 계정'), centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 32),
        child: Column(
          children: [
            // 프로필 사진 + 이름
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

            // 내 정보 카드
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
                    _infoRow('학번', _studentId),
                    if (_grade > 0) _infoRow('학년/반', '$_grade학년 $_classNum반'),
                  ],
                  if (_userType == 'graduate' && _graduationYear != null)
                    _infoRow('졸업연도', '$_graduationYear년'),
                  if (_userType == 'teacher' && _teacherSubject != null && _teacherSubject!.isNotEmpty)
                    _infoRow('담당과목', _teacherSubject!),
                  if (_email.isNotEmpty)
                    _infoRow('이메일', _email),
                  _infoRow('로그인', _providerLabel(_loginProvider)),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // 회원 탈퇴
            GestureDetector(
              onTap: _deleteAccount,
              child: Text('회원 탈퇴',
                style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor,
                  decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    );
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
}
