// import 'package:workmanager/workmanager.dart';
// import 'notification_manager.dart';
//
// class MealNotificationWorker {
//   static void initialize() {
//     Workmanager().initialize(callbackDispatcher);
//   }
//
//   static void registerDailyMealNotificationTask() {
//     Workmanager().registerPeriodicTask(
//       "dailyMealNotificationTask",
//       "dailyMealNotification",
//       frequency: const Duration(hours: 24),
//       initialDelay: Duration(
//         milliseconds: _calculateInitialDelay().inMilliseconds,
//       ),
//     );
//   }
//
//   static Duration _calculateInitialDelay() {
//     final now = DateTime.now();
//     final midnight = DateTime(now.year, now.month, now.day + 1);
//     return midnight.difference(now);
//   }
// }
//
// void callbackDispatcher() {
//   Workmanager().executeTask((taskName, inputData) async {
//     final notificationManager = NotificationManager();
//     await notificationManager.updateNotifications();
//     return Future.value(true);
//   });
// }
