import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/screens/auth/login_screen.dart';
import 'package:hansol_high_school/screens/auth/profile_edit_screen.dart';
import 'package:hansol_high_school/screens/sub/feedback_screen.dart';
import 'package:hansol_high_school/screens/sub/notification_setting_screen.dart';
import 'package:hansol_high_school/widgets/setting/grade_and_class_picker.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/screens/sub/timetable_select_screen.dart';
import 'package:hansol_high_school/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 설정 화면 (SettingScreen)
///
/// - 로그인/프로필 정보 확인 및 수정
/// - 학년/반 설정 및 테마(라이트/다크) 변경
/// - 급식 알림(조식/중식/석식) 시간 설정
/// - 캐시 크기 확인 및 초기화 기능
class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late int grade;
  late int classNum;
  late int themeModeIndex;
  late bool isBreakfastNotificationOn;
  late bool isLunchNotificationOn;
  late bool isDinnerNotificationOn;

  late TimeOfDay breakfastTime;
  late TimeOfDay lunchTime;
  late TimeOfDay dinnerTime;

  late Future<void> _settingsFuture;
  String _cacheSize = '';

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();
    _calcCacheSize();
  }

  Future<void> _calcCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    int bytes = 0;
    for (var key in keys) {
      final val = prefs.get(key);
      if (val is String) bytes += val.length * 2;
      else if (val is List<String>) {
        for (var s in val) bytes += s.length * 2;
      }
      bytes += key.length * 2;
    }
    final mb = bytes / (1024 * 1024);
    setState(() {
      _cacheSize = mb < 0.01 ? '${(bytes / 1024).toStringAsFixed(1)} KB' : '${mb.toStringAsFixed(2)} MB';
    });
  }

  Future<void> _loadSettings() async {
    await SettingData().init();
    setState(() {
      grade = SettingData().grade;
      classNum = SettingData().classNum;
      themeModeIndex = SettingData().themeModeIndex;
      isBreakfastNotificationOn = SettingData().isBreakfastNotificationOn;
      breakfastTime = _parseTimeOfDay(SettingData().breakfastTime);
      isLunchNotificationOn = SettingData().isLunchNotificationOn;
      lunchTime = _parseTimeOfDay(SettingData().lunchTime);
      isDinnerNotificationOn = SettingData().isDinnerNotificationOn;
      dinnerTime = _parseTimeOfDay(SettingData().dinnerTime);
    });
  }

  TimeOfDay _parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      final hourPart = parts[0];
      final minutePart = parts[1];
      if (minutePart.contains(' ')) {
        final minuteParts = minutePart.split(' ');
        final minute = int.parse(minuteParts[0]);
        final period = minuteParts[1];
        int hour = int.parse(hourPart);
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
        return TimeOfDay(hour: hour, minute: minute);
      } else {
        final hour = int.parse(hourPart);
        final minute = int.parse(minutePart);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      return const TimeOfDay(hour: 6, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveSettings() async {
    SettingData().grade = grade;
    SettingData().classNum = classNum;
    SettingData().themeModeIndex = themeModeIndex;
    SettingData().isBreakfastNotificationOn = isBreakfastNotificationOn;
    SettingData().breakfastTime = _formatTimeOfDay(breakfastTime);
    SettingData().isLunchNotificationOn = isLunchNotificationOn;
    SettingData().lunchTime = _formatTimeOfDay(lunchTime);
    SettingData().isDinnerNotificationOn = isDinnerNotificationOn;
    SettingData().dinnerTime = _formatTimeOfDay(dinnerTime);
  }

  void _applyThemeMode(int index) {
    themeModeIndex = index;
    SettingData().themeModeIndex = index;

    switch (index) {
      case 0:
        SettingData().isDarkMode = false;
        themeNotifier.value = ThemeMode.light;
        break;
      case 1:
        SettingData().isDarkMode = true;
        themeNotifier.value = ThemeMode.dark;
        break;
      case 2:
        final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
        SettingData().isDarkMode = isDark;
        themeNotifier.value = ThemeMode.system;
        break;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            Navigator.of(context).pop();
          }
        },
        child: FutureBuilder<void>(
          future: _settingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading settings'));
            } else {
              return _buildSettingsBody();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSettingsBody() {
    return Scaffold(
      backgroundColor: AppColors.theme.settingScreenBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.theme.settingScreenBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        title: const Text('설정'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildAuthCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('학교 정보'),
              _buildGroupedCard([
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _selectGradeAndClass(),
                  child: _buildSettingRow(
                    '학년 반 설정',
                    trailing: Text(
                      '$grade학년 $classNum반',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                _buildDivider(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: grade == 1 ? null : () {
                    if (!SettingData().isGradeSet) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('학년/반을 먼저 설정해주세요')),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TimetableSelectScreen()),
                    );
                  },
                  child: _buildSettingRow(
                    '선택과목 시간표',
                    trailing: Icon(Icons.chevron_right, color: grade == 1
                        ? AppColors.theme.darkGreyColor : AppColors.theme.primaryColor),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('테마'),
              _buildGroupedCard([
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      _buildThemeButton(0, '라이트', Icons.light_mode),
                      const SizedBox(width: 8),
                      _buildThemeButton(1, '다크', Icons.dark_mode),
                      const SizedBox(width: 8),
                      _buildThemeButton(2, '시스템', Icons.settings_brightness),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('알림'),
              _buildGroupedCard([
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationSettingScreen())),
                  child: _buildSettingRow(
                    '알림 설정',
                    trailing: Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                  ),
                ),
              ]),
              if (AuthService.isLoggedIn) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('건의사항'),
                _buildGroupedCard([
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FeedbackScreen(type: 'app'))),
                    child: _buildSettingRow(
                      '앱 건의사항 & 버그 제보',
                      trailing: Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                    ),
                  ),
                  _buildDivider(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FeedbackScreen(type: 'council'))),
                    child: _buildSettingRow(
                      '학생회 건의사항',
                      trailing: Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 24),
              _buildSectionTitle('기타'),
              _buildGroupedCard([
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const _PrivacyPolicyScreen())),
                  child: _buildSettingRow(
                    '개인정보 처리방침',
                    trailing: Icon(Icons.chevron_right, size: 18, color: AppColors.theme.darkGreyColor),
                  ),
                ),
                _buildDivider(),
                _buildSettingRow(
                  '캐시 삭제${_cacheSize.isNotEmpty ? ' ($_cacheSize)' : ''}',
                  trailing: TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      const preserveKeys = {
                        'Grade', 'Class', 'isDarkMode', 'themeModeIndex',
                        'isBreakfastNotificationOn', 'breakfastTime',
                        'isLunchNotificationOn', 'lunchTime',
                        'isDinnerNotificationOn', 'dinnerTime',
                      };
                      final allKeys = prefs.getKeys().toList();
                      int removed = 0;
                      for (var key in allKeys) {
                        if (!preserveKeys.contains(key) && !key.startsWith('selected_subjects_')) {
                          await prefs.remove(key);
                          removed++;
                        }
                      }
                      log('Cache clear: removed $removed / ${allKeys.length} keys');
                      _calcCacheSize();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('캐시가 삭제되었습니다')),
                        );
                      }
                    },
                    child: Text('삭제', style: TextStyle(color: Colors.red[400])),
                  ),
                ),
                _buildDivider(),
                _buildSettingRow(
                  '앱 버전',
                  trailing: Text(
                    'v1.0.0',
                    style: TextStyle(color: AppColors.theme.darkGreyColor, fontSize: 14),
                  ),
                ),
              ]),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.theme.darkGreyColor,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.theme.mealCardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingRow(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.theme.lightGreyColor,
    );
  }

  Widget _buildAuthCard() {
    final isLoggedIn = AuthService.isLoggedIn;

    if (isLoggedIn) {
      return FutureBuilder<UserProfile?>(
        future: AuthService.getUserProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final name = profile?.name ?? AuthService.currentUser?.displayName ?? '';
          final email = AuthService.currentUser?.email ?? '';

          return Column(
            children: [
              _buildGroupedCard([
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.theme.primaryColor,
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(name.isNotEmpty ? name : '이름 없음',
                    style: TextStyle(fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email.isNotEmpty ? email : _providerLabel(profile?.loginProvider ?? 'google'),
                        style: TextStyle(fontSize: 12, color: AppColors.theme.mealTypeTextColor)),
                      const SizedBox(height: 2),
                      Text(
                        profile?.approved == true ? '승인됨' : '승인 대기중',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: profile?.approved == true ? const Color(0xFF4CAF50) : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await AuthService.signOut();
                      AuthService.clearProfileCache();
                      appRefreshNotifier.value++;
                      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    child: Text('로그아웃', style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor)),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              _buildGroupedCard([
                ListTile(
                  leading: Icon(Icons.edit, size: 20, color: AppColors.theme.primaryColor),
                  title: Text('내 계정', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
                  trailing: Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
                    if (mounted) setState(() {});
                  },
                ),
              ]),
            ],
          );
        },
      );
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        if (result == true && mounted) setState(() {});
      },
      child: _buildGroupedCard([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.theme.lightGreyColor,
                child: Icon(Icons.person, color: AppColors.theme.darkGreyColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                    Text('Google 계정으로 로그인하세요', style: TextStyle(
                        fontSize: 12, color: AppColors.theme.mealTypeTextColor)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildThemeButton(int index, String label, IconData icon) {
    final isSelected = themeModeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyThemeMode(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.theme.primaryColor
                : AppColors.theme.lightGreyColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.theme.darkGreyColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.theme.darkGreyColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _providerLabel(String provider) {
    switch (provider) {
      case 'kakao': return 'Kakao 로그인';
      case 'apple': return 'Apple 로그인';
      case 'github': return 'GitHub 로그인';
      default: return 'Google 로그인';
    }
  }

  void _selectGradeAndClass() async {
    final pickerGrade = grade > 0 ? grade : 1;
    final pickerClass = classNum > 0 ? classNum : 1;
    int classCount = await TimetableDataApi.getClassCount(pickerGrade);
    if (classCount <= 0) classCount = 10;
    if (!mounted) return;
    List<int>? selectedValues = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        return GradeAndClassPickerDialog(
          initialGrade: pickerGrade,
          initialClass: pickerClass,
          classCount: classCount,
        );
      },
    );

    if (selectedValues != null && selectedValues.length == 2) {
      setState(() {
        grade = selectedValues[0];
        classNum = selectedValues[1];
        _saveSettings();
      });
    }
  }
}

class _PrivacyPolicyScreen extends StatelessWidget {
  const _PrivacyPolicyScreen();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = AppColors.theme.darkGreyColor;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Theme.of(context).scaffoldBackgroundColor, foregroundColor: textColor,
        title: const Text('개인정보 처리방침'), centerTitle: true, elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _t('1. 수집하는 개인정보 항목', textColor),
          _b('이름, 학번, 학년/반(재학생), 졸업연도(졸업생), 담당과목(교사), 이메일, 프로필 사진(선택), 기기 토큰(푸시 알림용)', subColor),
          _t('2. 수집·이용 목적', textColor),
          _b('사용자 식별 및 가입 승인, 커뮤니티 서비스 제공, 맞춤 정보 제공, 푸시 알림, 부적절한 이용 방지', subColor),
          _t('3. 보유 및 이용 기간', textColor),
          _b('회원 탈퇴 시 즉시 삭제. 게시글은 작성일로부터 1년 후 자동 삭제.', subColor),
          _t('4. 제3자 제공', textColor),
          _b('수집된 개인정보는 제3자에게 제공하지 않습니다. 법령에 의한 요청 시 예외.', subColor),
          _t('5. 파기 절차', textColor),
          _b('회원 탈퇴 시 Firebase Authentication, Firestore 데이터, Storage 프로필 사진 즉시 삭제.', subColor),
          _t('6. 이용자의 권리', textColor),
          _b('언제든지 회원정보 조회, 수정, 탈퇴 가능.', subColor),
          _t('7. 보호 조치', textColor),
          _b('Firebase 보안 규칙, 역할 기반 권한, HTTPS 암호화, API 키 환경변수 분리.', subColor),
          const SizedBox(height: 16),
          Text('시행일: 2025년 1월 1일', style: TextStyle(fontSize: 12, color: subColor)),
        ]),
      ),
    );
  }

  Widget _t(String text, Color? c) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c)));
  Widget _b(String text, Color c) => Text(text, style: TextStyle(fontSize: 13, color: c, height: 1.7));
}
