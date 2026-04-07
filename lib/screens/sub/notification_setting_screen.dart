import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/notification/daily_meal_notification.dart';
import 'package:hansol_high_school/notification/fcm_service.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 알림 설정 화면
///
/// - 급식 알림: 조식/중식/석식 시간 설정 + on/off
/// - 푸시 알림: 댓글/대댓글/새글/채팅/계정 카테고리별 on/off
/// - Firestore users/{uid}에 설정값 저장, Cloud Functions에서 체크
class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingScreen> createState() => _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  // 급식 알림 (로컬)
  late bool _breakfast;
  late bool _lunch;
  late bool _dinner;
  late TimeOfDay _breakfastTime;
  late TimeOfDay _lunchTime;
  late TimeOfDay _dinnerTime;

  // 푸시 알림 (Firestore)
  bool _notiComment = true;
  bool _notiReply = true;
  bool _notiMention = true;
  bool _notiNewPost = true;
  bool _notiChat = true;
  bool _notiAccount = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _breakfast = SettingData().isBreakfastNotificationOn;
    _lunch = SettingData().isLunchNotificationOn;
    _dinner = SettingData().isDinnerNotificationOn;
    _breakfastTime = _parseTime(SettingData().breakfastTime);
    _lunchTime = _parseTime(SettingData().lunchTime);
    _dinnerTime = _parseTime(SettingData().dinnerTime);
    _loadPushSettings();
  }

  TimeOfDay _parseTime(String time) {
    try {
      final parts = time.split(':');
      final h = parts[0];
      final m = parts[1];
      if (m.contains(' ')) {
        final mp = m.split(' ');
        int hour = int.parse(h);
        if (mp[1] == 'PM' && hour != 12) hour += 12;
        if (mp[1] == 'AM' && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: int.parse(mp[0]));
      }
      return TimeOfDay(hour: int.parse(h), minute: int.parse(m));
    } catch (_) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _loadPushSettings() async {
    if (!AuthService.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final uid = AuthService.currentUser!.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _notiComment = data['notiComment'] ?? true;
          _notiReply = data['notiReply'] ?? true;
          _notiMention = data['notiMention'] ?? true;
          _notiNewPost = data['notiNewPost'] ?? true;
          _notiChat = data['notiChat'] ?? true;
          _notiAccount = data['notiAccount'] ?? true;
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _savePushSetting(String field, bool value) async {
    if (!AuthService.isLoggedIn) return;
    final uid = AuthService.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({field: value});

    // 새 글 알림은 토픽 구독으로도 제어
    if (field == 'notiNewPost') {
      await FcmService.toggleBoardNotification(value);
    }
  }

  void _saveMealSettings() {
    SettingData().isBreakfastNotificationOn = _breakfast;
    SettingData().breakfastTime = _formatTime(_breakfastTime);
    SettingData().isLunchNotificationOn = _lunch;
    SettingData().lunchTime = _formatTime(_lunchTime);
    SettingData().isDinnerNotificationOn = _dinner;
    SettingData().dinnerTime = _formatTime(_dinnerTime);
    DailyMealNotification().updateNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2028) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF14151A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF14151A) : const Color(0xFFF5F5F5),
        foregroundColor: textColor,
        title: const Text('알림 설정'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('급식 알림'),
                  _card(cardColor, [
                    _mealRow('조식 알림', _breakfastTime, _breakfast, (t) {
                      setState(() { _breakfastTime = t; _saveMealSettings(); });
                    }, (v) {
                      setState(() { _breakfast = v; _saveMealSettings(); });
                    }),
                    _divider(),
                    _mealRow('중식 알림', _lunchTime, _lunch, (t) {
                      setState(() { _lunchTime = t; _saveMealSettings(); });
                    }, (v) {
                      setState(() { _lunch = v; _saveMealSettings(); });
                    }),
                    _divider(),
                    _mealRow('석식 알림', _dinnerTime, _dinner, (t) {
                      setState(() { _dinnerTime = t; _saveMealSettings(); });
                    }, (v) {
                      setState(() { _dinner = v; _saveMealSettings(); });
                    }),
                  ]),

                  if (AuthService.isLoggedIn) ...[
                    _sectionTitle('게시판 알림'),
                    _card(cardColor, [
                      _pushRow('내 글 댓글 알림', '내 게시글에 댓글이 달리면 알림', _notiComment, (v) {
                        setState(() => _notiComment = v);
                        _savePushSetting('notiComment', v);
                      }),
                      _divider(),
                      _pushRow('대댓글 알림', '내 댓글에 답글이 달리면 알림', _notiReply, (v) {
                        setState(() => _notiReply = v);
                        _savePushSetting('notiReply', v);
                      }),
                      _divider(),
                      _pushRow('멘션 알림', '댓글에서 누군가 나를 @로 언급하면 알림', _notiMention, (v) {
                        setState(() => _notiMention = v);
                        _savePushSetting('notiMention', v);
                      }),
                      _divider(),
                      _pushRow('새 글 알림', '게시판에 새 글이 올라오면 알림', _notiNewPost, (v) {
                        setState(() => _notiNewPost = v);
                        _savePushSetting('notiNewPost', v);
                      }),
                    ]),

                    _sectionTitle('채팅 알림'),
                    _card(cardColor, [
                      _pushRow('메시지 알림', '새 채팅 메시지가 오면 알림', _notiChat, (v) {
                        setState(() => _notiChat = v);
                        _savePushSetting('notiChat', v);
                      }),
                    ]),

                    _sectionTitle('계정 알림'),
                    _card(cardColor, [
                      _pushRow('승인/정지/역할 변경', '계정 상태 변경 시 알림', _notiAccount, (v) {
                        setState(() => _notiAccount = v);
                        _savePushSetting('notiAccount', v);
                      }),
                    ]),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, top: 20, bottom: 8),
    child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.theme.darkGreyColor)),
  );

  Widget _card(Color color, List<Widget> children) => Container(
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
    child: Column(children: children),
  );

  Widget _divider() => Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.theme.lightGreyColor);

  Widget _pushRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor)),
            ],
          )),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.theme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _mealRow(String name, TimeOfDay time, bool enabled,
      ValueChanged<TimeOfDay> onTime, ValueChanged<bool> onSwitch) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(name, style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color))),
          GestureDetector(
            onTap: enabled ? () async {
              final picked = await showTimePicker(context: context, initialTime: time);
              if (picked != null) onTime(picked);
            } : null,
            child: Text(time.format(context), style: TextStyle(
              fontSize: 14, color: enabled ? AppColors.theme.primaryColor : AppColors.theme.darkGreyColor)),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(value: enabled, activeColor: AppColors.theme.primaryColor, onChanged: onSwitch),
        ],
      ),
    );
  }
}
