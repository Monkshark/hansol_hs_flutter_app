import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/auth/login_screen.dart';
import 'package:hansol_high_school/screens/auth/profile_edit_screen.dart';
import 'package:hansol_high_school/screens/sub/community_rules_screen.dart';
import 'package:hansol_high_school/screens/sub/feedback_screen.dart';
import 'package:hansol_high_school/screens/sub/notification_setting_screen.dart';
import 'package:hansol_high_school/widgets/setting/grade_and_class_picker.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';
import 'package:hansol_high_school/screens/sub/timetable_select_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hansol_high_school/main.dart' show providerContainer;
import 'package:hansol_high_school/providers/settings_provider.dart';
import 'package:hansol_high_school/providers/theme_provider.dart' show themeProvider;
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

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
  bool _analyticsEnabled = true;

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
      if (val is String) {
        bytes += val.length * 2;
      } else if (val is List<String>) {
        for (var s in val) { bytes += s.length * 2; }
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
    final prefs = await SharedPreferences.getInstance();
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
      _analyticsEnabled = prefs.getBool('analyticsEnabled') ?? true;
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

    providerContainer.read(themeProvider.notifier).setMode(index);

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
        title: Text(AppLocalizations.of(context)!.settings_title),
        titleTextStyle: TextStyle(
          fontSize: Responsive.sp(context, 20),
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Text(
              SettingData().localeCode == 'en' ? 'EN' : '한',
              style: TextStyle(
                fontSize: Responsive.sp(context, 15),
                fontWeight: FontWeight.w700,
                color: AppColors.theme.primaryColor,
              ),
            ),
            onPressed: () {
              final newCode = SettingData().localeCode == 'en' ? 'ko' : 'en';
              providerContainer.read(localeProvider.notifier).setLocale(Locale(newCode));
              setState(() {});
            },
          ),
        ],
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
              _buildSectionTitle(AppLocalizations.of(context)!.settings_schoolSection),
              _buildGroupedCard([
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _selectGradeAndClass(),
                  child: _buildSettingRow(
                    AppLocalizations.of(context)!.settings_gradeClass,
                    trailing: Text(
                      AppLocalizations.of(context)!.settings_gradeClassLabel(grade, classNum),
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 16),
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
                        SnackBar(content: Text(AppLocalizations.of(context)!.settings_gradeClassError)),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TimetableSelectScreen()),
                    );
                  },
                  child: _buildSettingRow(
                    AppLocalizations.of(context)!.settings_selectiveSubject,
                    trailing: Icon(Icons.chevron_right, size: Responsive.r(context, 24), color: grade == 1
                        ? AppColors.theme.darkGreyColor : AppColors.theme.primaryColor),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle(AppLocalizations.of(context)!.settings_themeSection),
              _buildGroupedCard([
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      _buildThemeButton(0, AppLocalizations.of(context)!.settings_light, Icons.light_mode),
                      const SizedBox(width: 8),
                      _buildThemeButton(1, AppLocalizations.of(context)!.settings_dark, Icons.dark_mode),
                      const SizedBox(width: 8),
                      _buildThemeButton(2, AppLocalizations.of(context)!.settings_system, Icons.settings_brightness),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle(AppLocalizations.of(context)!.settings_notificationSection),
              _buildGroupedCard([
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationSettingScreen())),
                  child: _buildSettingRow(
                    AppLocalizations.of(context)!.settings_notification,
                    trailing: Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle(AppLocalizations.of(context)!.settings_a11ySection),
              _buildGroupedCard([
                _buildA11yFontScaleRow(),
                _buildDivider(),
                _buildA11yHighContrastRow(),
                _buildDivider(),
                _buildA11yColorBlindRow(),
              ]),
              if (AuthService.isLoggedIn) ...[
                const SizedBox(height: 24),
                _buildSectionTitle(AppLocalizations.of(context)!.settings_feedbackSection),
                _buildGroupedCard([
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FeedbackScreen(type: 'app'))),
                    child: _buildSettingRow(
                      AppLocalizations.of(context)!.settings_appFeedback,
                      trailing: Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                    ),
                  ),
                  _buildDivider(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FeedbackScreen(type: 'council'))),
                    child: _buildSettingRow(
                      AppLocalizations.of(context)!.settings_councilFeedback,
                      trailing: Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 24),
              _buildSectionTitle(AppLocalizations.of(context)!.settings_etcSection),
              _buildGroupedCard([
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                  child: _buildSettingRow(
                    AppLocalizations.of(context)!.settings_privacy,
                    trailing: Icon(Icons.chevron_right, size: Responsive.r(context, 18), color: AppColors.theme.darkGreyColor),
                  ),
                ),
                _buildDivider(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CommunityRulesScreen())),
                  child: _buildSettingRow(
                    AppLocalizations.of(context)!.community_rules_title,
                    trailing: Icon(Icons.chevron_right, size: Responsive.r(context, 18), color: AppColors.theme.darkGreyColor),
                  ),
                ),
                _buildDivider(),
                _buildSettingRow(
                  AppLocalizations.of(context)!.settings_analyticsCollection,
                  trailing: Switch.adaptive(
                    value: _analyticsEnabled,
                    activeTrackColor: AppColors.theme.primaryColor,
                    onChanged: (v) async {
                      setState(() => _analyticsEnabled = v);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('analyticsEnabled', v);
                      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(v);
                    },
                  ),
                ),
                _buildDivider(),
                _buildSettingRow(
                  AppLocalizations.of(context)!.settings_cacheLabel(_cacheSize.isNotEmpty ? ' ($_cacheSize)' : ''),
                  trailing: TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      const preserveKeys = {
                        'Grade', 'Class', 'isDarkMode', 'themeModeIndex',
                        'localeCode',
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
                          SnackBar(content: Text(AppLocalizations.of(context)!.settings_cacheSuccess)),
                        );
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.settings_cacheDelete, style: TextStyle(color: Colors.red[400])),
                  ),
                ),
                _buildDivider(),
                _buildSettingRow(
                  AppLocalizations.of(context)!.settings_appVersion,
                  trailing: Text(
                    'v1.0.0',
                    style: TextStyle(color: AppColors.theme.darkGreyColor, fontSize: Responsive.sp(context, 14)),
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
          fontSize: Responsive.sp(context, 13),
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
              fontSize: Responsive.sp(context, 16),
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
                      style: TextStyle(fontSize: Responsive.sp(context, 14), color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(name.isNotEmpty ? name : AppLocalizations.of(context)!.settings_nameDefault,
                    style: TextStyle(fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email.isNotEmpty ? email : _providerLabel(profile?.loginProvider ?? 'google'),
                        style: TextStyle(fontSize: Responsive.sp(context, 12), color: AppColors.theme.mealTypeTextColor)),
                      const SizedBox(height: 2),
                      Text(
                        profile?.approved == true ? AppLocalizations.of(context)!.settings_approved : AppLocalizations.of(context)!.settings_pendingApproval,
                        style: TextStyle(
                          fontSize: Responsive.sp(context, 11),
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
                      providerContainer.read(appRefreshProvider.notifier).refresh();
                      if (!context.mounted) return;
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    child: Text(AppLocalizations.of(context)!.settings_logout, style: TextStyle(fontSize: Responsive.sp(context, 13), color: AppColors.theme.darkGreyColor)),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              _buildGroupedCard([
                ListTile(
                  leading: Icon(Icons.edit, size: Responsive.r(context, 20), color: AppColors.theme.primaryColor),
                  title: Text(AppLocalizations.of(context)!.settings_myAccount, style: TextStyle(fontSize: Responsive.sp(context, 15), fontWeight: FontWeight.w500,
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
                    Text(AppLocalizations.of(context)!.settings_login, style: TextStyle(fontSize: Responsive.sp(context, 16), fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                    Text(AppLocalizations.of(context)!.settings_loginDesc, style: TextStyle(
                        fontSize: Responsive.sp(context, 12), color: AppColors.theme.mealTypeTextColor)),
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

  Widget _buildA11yFontScaleRow() {
    final l = AppLocalizations.of(context)!;
    final current = SettingData().fontScale;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.settings_fontScale,
              style: TextStyle(fontSize: Responsive.sp(context, 16), fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildA11yFontButton(1.0, l.settings_fontScaleNormal, current),
              const SizedBox(width: 8),
              _buildA11yFontButton(1.3, l.settings_fontScaleLarge, current),
              const SizedBox(width: 8),
              _buildA11yFontButton(1.6, l.settings_fontScaleXLarge, current),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildA11yFontButton(double value, String label, double current) {
    final isSelected = (current - value).abs() < 0.05;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          providerContainer.read(a11ySettingsProvider.notifier).setFontScale(value);
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.theme.primaryColor : AppColors.theme.lightGreyColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: Responsive.sp(context, 13),
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.theme.darkGreyColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildA11yHighContrastRow() {
    final l = AppLocalizations.of(context)!;
    final current = SettingData().highContrast;
    return _buildSettingRow(
      l.settings_highContrast,
      trailing: Switch.adaptive(
        value: current,
        activeTrackColor: AppColors.theme.primaryColor,
        onChanged: (v) {
          providerContainer.read(a11ySettingsProvider.notifier).setHighContrast(v);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildA11yColorBlindRow() {
    final l = AppLocalizations.of(context)!;
    final current = SettingData().colorBlindMode;
    String labelOf(String mode) {
      switch (mode) {
        case 'protanopia': return l.settings_colorBlindProtanopia;
        case 'deuteranopia': return l.settings_colorBlindDeuteranopia;
        case 'tritanopia': return l.settings_colorBlindTritanopia;
        default: return l.settings_colorBlindNone;
      }
    }
    return _buildSettingRow(
      l.settings_colorBlindMode,
      trailing: DropdownButton<String>(
        value: current,
        underline: const SizedBox.shrink(),
        items: const ['none', 'protanopia', 'deuteranopia', 'tritanopia']
            .map((m) => DropdownMenuItem(value: m, child: Text(labelOf(m))))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          providerContainer.read(a11ySettingsProvider.notifier).setColorBlindMode(v);
          setState(() {});
        },
      ),
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
              Icon(icon, size: Responsive.r(context, 20), color: isSelected ? Colors.white : AppColors.theme.darkGreyColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.sp(context, 12),
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
    final l = AppLocalizations.of(context)!;
    switch (provider) {
      case 'kakao': return l.settings_loginKakao;
      case 'apple': return l.settings_loginApple;
      case 'github': return l.settings_loginGithub;
      default: return l.settings_loginGoogle;
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
      _syncGradeToFirestore(selectedValues[0], selectedValues[1]);
    }
  }
  Future<void> _syncGradeToFirestore(int g, int c) async {
    if (!AuthService.isLoggedIn) return;
    try {
      final uid = AuthService.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'grade': g,
        'classNum': c,
      });
    } catch (e) {
      log('SettingScreen: Firestore grade sync error: $e');
    }
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = AppColors.theme.darkGreyColor;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Theme.of(context).scaffoldBackgroundColor, foregroundColor: textColor,
        title: Text(l.settings_privacyTitle), centerTitle: true, elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.settings_privacyEffectiveDate, style: TextStyle(fontSize: Responsive.sp(context, 12), color: subColor)),
          const SizedBox(height: 8),
          _b(l.settings_privacyIntro, subColor, ctx: context),

          _t(l.settings_privacySection1Title, textColor, ctx: context),
          _b(l.settings_privacySection1Intro, subColor, ctx: context),
          _b(l.settings_privacySection1Content, subColor, ctx: context),

          _t(l.settings_privacySection2Title, textColor, ctx: context),
          _s(l.settings_privacySection2Required, textColor, ctx: context),
          _b(l.settings_privacySection2RequiredContent, subColor, ctx: context),
          _s(l.settings_privacySection2Optional, textColor, ctx: context),
          _b(l.settings_privacySection2OptionalContent, subColor, ctx: context),
          _s(l.settings_privacySection2Auto, textColor, ctx: context),
          _b(l.settings_privacySection2AutoContent, subColor, ctx: context),
          _s(l.settings_privacySection2AutoCollect, textColor, ctx: context),
          _b(l.settings_privacySection2AutoCollectContent, subColor, ctx: context),
          _s(l.settings_privacySection2LocalOnly, textColor, ctx: context),
          _b(l.settings_privacySection2LocalOnlyContent, subColor, ctx: context),

          _t(l.settings_privacySection3Title, textColor, ctx: context),
          _b(l.settings_privacySection3Content, subColor, ctx: context),

          _t(l.settings_privacySection4Title, textColor, ctx: context),
          _b(l.settings_privacySection4Content, subColor, ctx: context),

          _t(l.settings_privacySection5Title, textColor, ctx: context),
          _b(l.settings_privacySection5Content, subColor, ctx: context),

          _t(l.settings_privacySection6Title, textColor, ctx: context),
          _b(l.settings_privacySection6Content, subColor, ctx: context),

          _t(l.settings_privacySection7Title, textColor, ctx: context),
          _b(l.settings_privacySection7Content, subColor, ctx: context),

          _t(l.settings_privacySection8Title, textColor, ctx: context),
          _b(l.settings_privacySection8Content, subColor, ctx: context),

          _t(l.settings_privacySection9Title, textColor, ctx: context),
          _b(l.settings_privacySection9Content, subColor, ctx: context),

          _t(l.settings_privacySection10Title, textColor, ctx: context),
          _b(l.settings_privacySection10Content, subColor, ctx: context),

          _t(l.settings_privacySection11Title, textColor, ctx: context),
          _b(l.settings_privacySection11Content, subColor, ctx: context),

          _t(l.settings_privacySection12Title, textColor, ctx: context),
          _b(l.settings_privacySection12Content, subColor, ctx: context),

          _t(l.settings_privacySectionAutomatedTitle, textColor, ctx: context),
          _b(l.settings_privacySectionAutomatedContent, subColor, ctx: context),

          _t(l.settings_privacySection13Title, textColor, ctx: context),
          _b(l.settings_privacySection13Content, subColor, ctx: context),

          _t(l.settings_privacySection14Title, textColor, ctx: context),
          _b(l.settings_privacySection14Content, subColor, ctx: context),
          const SizedBox(height: 8),
          _link(l.settings_privacySection14Link1, l.settings_privacySection14Phone1, l.settings_privacySection14Url1, ctx: context),
          _link(l.settings_privacySection14Link2, l.settings_privacySection14Phone2, l.settings_privacySection14Url2, ctx: context),
          _link(l.settings_privacySection14Link3, l.settings_privacySection14Phone3, l.settings_privacySection14Url3, ctx: context),
          _link(l.settings_privacySection14Link4, l.settings_privacySection14Phone4, l.settings_privacySection14Url4, ctx: context),

          _t(l.settings_privacySection15Title, textColor, ctx: context),
          _b(l.settings_privacySection15Content, subColor, ctx: context),
        ]),
      ),
    );
  }

  Widget _t(String text, Color? c, {required BuildContext ctx}) => Padding(padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(text, style: TextStyle(fontSize: Responsive.sp(ctx, 15), fontWeight: FontWeight.w700, color: c)));
  Widget _s(String text, Color? c, {required BuildContext ctx}) => Padding(padding: const EdgeInsets.only(top: 14, bottom: 4),
    child: Text(text, style: TextStyle(fontSize: Responsive.sp(ctx, 13), fontWeight: FontWeight.w600, color: c)));
  Widget _b(String text, Color c, {required BuildContext ctx}) => Padding(padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: TextStyle(fontSize: Responsive.sp(ctx, 13), color: c, height: 1.7)));
  Widget _link(String name, String phone, String url, {required BuildContext ctx}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Row(children: [
        Text('• ', style: TextStyle(fontSize: Responsive.sp(ctx, 13), color: AppColors.theme.darkGreyColor)),
        Expanded(child: Text.rich(TextSpan(children: [
          TextSpan(text: name, style: TextStyle(fontSize: Responsive.sp(ctx, 13), color: AppColors.theme.primaryColor, decoration: TextDecoration.underline)),
          TextSpan(text: ' / $phone', style: TextStyle(fontSize: Responsive.sp(ctx, 13), color: AppColors.theme.darkGreyColor)),
        ]))),
      ]),
    ),
  );
}
