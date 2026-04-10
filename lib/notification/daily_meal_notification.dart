import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hansol_high_school/api/meal_data_api.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/main.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

/// 급식 로컬 알림 스케줄링
/// - 조식/중식/석식 각각 평일(월~금) 반복 알림 등록
/// - SettingData의 알림 ON/OFF 및 시간 설정에 따라 스케줄 생성
/// - iOS/Android 권한 요청 및 플랫폼별 알림 채널 설정
/// - 테스트 알림(5초 후) 전송 기능 제공
class DailyMealNotification {
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotificationsPlugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
    );

    await _requestPermissions();
    _isInitialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    log('Notification tapped: ${response.payload}');
    notificationStream.add(response.payload);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotification(NotificationResponse response) {
    log('Background notification: ${response.payload}');
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final iosPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  Future<AppLocalizations> _getLocalizations() async {
    return await AppLocalizations.delegate.load(const Locale('ko'));
  }

  Future<void> scheduleDailyNotifications() async {
    if (!_isInitialized) await initializeNotifications();
    await cancelAllNotifications();

    final settings = SettingData();
    final l = await _getLocalizations();
    const weekdays = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ];

    if (settings.isBreakfastNotificationOn) {
      await _scheduleWeeklyNotification(
        id: 1,
        mealLabel: l.meal_breakfast,
        notiTitle: l.noti_mealBreakfast,
        l: l,
        time: _parseTimeOfDay(settings.breakfastTime),
        weekdays: weekdays,
      );
    }

    if (settings.isLunchNotificationOn) {
      await _scheduleWeeklyNotification(
        id: 2,
        mealLabel: l.meal_lunch,
        notiTitle: l.noti_mealLunch,
        l: l,
        time: _parseTimeOfDay(settings.lunchTime),
        weekdays: weekdays,
      );
    }

    if (settings.isDinnerNotificationOn) {
      await _scheduleWeeklyNotification(
        id: 3,
        mealLabel: l.meal_dinner,
        notiTitle: l.noti_mealDinner,
        l: l,
        time: _parseTimeOfDay(settings.dinnerTime),
        weekdays: weekdays,
      );
    }

    log('DailyMealNotification: scheduled ${settings.isBreakfastNotificationOn ? "breakfast" : ""} ${settings.isLunchNotificationOn ? "lunch" : ""} ${settings.isDinnerNotificationOn ? "dinner" : ""}');
  }

  String _cleanMenu(String? menu) {
    if (menu == null || menu.isEmpty) return '';
    return menu
        .split('\n')
        .map((e) => e.replaceAll(RegExp(r'\([0-9.,\s]+\)'), '').trim())
        .where((e) => e.isNotEmpty)
        .join(' · ');
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String mealLabel,
    required String notiTitle,
    required AppLocalizations l,
    required TimeOfDay time,
    required List<int> weekdays,
  }) async {
    final mealType = id == 1 ? MealDataApi.BREAKFAST : id == 2 ? MealDataApi.LUNCH : MealDataApi.DINNER;
    String menuPreview = '';
    try {
      final meal = await MealDataApi.getMeal(date: DateTime.now(), mealType: mealType, type: MealDataApi.MENU);
      menuPreview = _cleanMenu(meal?.meal);
    } catch (_) {}

    final body = menuPreview.isNotEmpty ? menuPreview : l.noti_mealConfirm(mealLabel);

    for (int weekday in weekdays) {
      final scheduledDate = _nextInstanceOfWeekday(time, weekday);
      final notificationId = id * 10 + weekday;

      final androidDetails = AndroidNotificationDetails(
        'daily_meal_channel_id',
        l.noti_mealChannelName,
        channelDescription: l.noti_mealChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: notiTitle,
          summaryText: l.noti_schoolName,
        ),
        showWhen: true,
      );

      final iosDetails = DarwinNotificationDetails(
        subtitle: body,
      );

      await _localNotificationsPlugin.zonedSchedule(
        notificationId,
        notiTitle,
        body,
        scheduledDate,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'meal_screen',
      );
    }
  }

  Future<void> sendTestNotification() async {
    if (!_isInitialized) await initializeNotifications();

    final l = await _getLocalizations();
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

    final androidDetails = AndroidNotificationDetails(
      'daily_meal_channel_id',
      l.noti_mealChannelName,
      channelDescription: l.noti_mealChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        l.noti_mealTestDetail,
        contentTitle: l.noti_mealTestTitle,
        summaryText: l.noti_schoolName,
      ),
      showWhen: true,
    );

    await _localNotificationsPlugin.zonedSchedule(
      999,
      l.noti_mealTestTitle,
      l.noti_mealTestBody,
      scheduledDate,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      payload: 'meal_screen',
    );

    log('DailyMealNotification: test notification scheduled at $scheduledDate');
  }

  Future<void> updateNotifications() async {
    await cancelAllNotifications();
    await scheduleDailyNotifications();
  }

  Future<void> cancelAllNotifications() async {
    await _localNotificationsPlugin.cancelAll();
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final format = DateFormat.Hm();
    DateTime dateTime = format.parse(timeString);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  tz.TZDateTime _nextInstanceOfWeekday(TimeOfDay time, int weekday) {
    var scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != weekday ||
        scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay timeOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
