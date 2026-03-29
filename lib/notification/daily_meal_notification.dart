import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/main.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

/**
 * 급식 로컬 알림 스케줄링
 * - 조식/중식/석식 각각 평일(월~금) 반복 알림 등록
 * - SettingData의 알림 ON/OFF 및 시간 설정에 따라 스케줄 생성
 * - iOS/Android 권한 요청 및 플랫폼별 알림 채널 설정
 * - 테스트 알림(5초 후) 전송 기능 제공
 */
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

  Future<void> scheduleDailyNotifications() async {
    if (!_isInitialized) await initializeNotifications();
    await cancelAllNotifications();

    final settings = SettingData();
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
        mealLabel: '조식',
        time: _parseTimeOfDay(settings.breakfastTime),
        weekdays: weekdays,
      );
    }

    if (settings.isLunchNotificationOn) {
      await _scheduleWeeklyNotification(
        id: 2,
        mealLabel: '중식',
        time: _parseTimeOfDay(settings.lunchTime),
        weekdays: weekdays,
      );
    }

    if (settings.isDinnerNotificationOn) {
      await _scheduleWeeklyNotification(
        id: 3,
        mealLabel: '석식',
        time: _parseTimeOfDay(settings.dinnerTime),
        weekdays: weekdays,
      );
    }

    log('DailyMealNotification: scheduled ${settings.isBreakfastNotificationOn ? "조식" : ""} ${settings.isLunchNotificationOn ? "중식" : ""} ${settings.isDinnerNotificationOn ? "석식" : ""}');
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String mealLabel,
    required TimeOfDay time,
    required List<int> weekdays,
  }) async {
    for (int weekday in weekdays) {
      final scheduledDate = _nextInstanceOfWeekday(time, weekday);
      final notificationId = id * 10 + weekday;

      final androidDetails = AndroidNotificationDetails(
        'daily_meal_channel_id',
        '급식 알림',
        channelDescription: '급식 정보 알림을 제공합니다.',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          '오늘의 $mealLabel 메뉴가 준비되었습니다.\n앱을 열어서 확인하세요!',
          contentTitle: '🍽️ $mealLabel 알림',
          summaryText: '한솔고등학교',
        ),
        showWhen: true,
      );

      final iosDetails = DarwinNotificationDetails(
        subtitle: '오늘의 $mealLabel을 확인하세요',
      );

      await _localNotificationsPlugin.zonedSchedule(
        notificationId,
        '🍽️ $mealLabel 알림',
        '오늘의 $mealLabel 메뉴를 확인하세요',
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

    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

    final androidDetails = AndroidNotificationDetails(
      'daily_meal_channel_id',
      '급식 알림',
      channelDescription: '급식 정보 알림을 제공합니다.',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: const BigTextStyleInformation(
        '테스트 알림입니다.\n오늘의 중식 메뉴를 확인하세요!',
        contentTitle: '🍽️ 중식 알림 (테스트)',
        summaryText: '한솔고등학교',
      ),
      showWhen: true,
    );

    await _localNotificationsPlugin.zonedSchedule(
      999,
      '🍽️ 중식 알림 (테스트)',
      '5초 후 알림 테스트',
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
