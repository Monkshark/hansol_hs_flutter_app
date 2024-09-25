package com.example.hansol_high_school

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
}



//package com.example.hansol_high_school
//
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugin.common.MethodChannel
//import io.flutter.plugin.common.MethodCall
//import android.app.AlarmManager
//import android.app.PendingIntent
//import android.content.Context
//import android.content.Intent
//import java.util.Calendar
//
//class MainActivity : FlutterActivity() {
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.hansol_high_school/alarm")
//            .setMethodCallHandler(AlarmPlugin(this))
//    }
//
//    inner class AlarmPlugin(private val context: Context) : MethodChannel.MethodCallHandler {
//        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
//            if (call.method == "scheduleMidnightAlarm") {
//                scheduleAlarm()
//                result.success(null)
//            } else {
//                result.notImplemented()
//            }
//        }
//
//        fun scheduleAlarm() {
//            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
//            val intent = Intent(context, AlarmReceiver::class.java)
//            val pendingIntent = PendingIntent.getBroadcast(
//                context,
//                0,
//                intent,
//                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
//            )
//
//            val calendar = Calendar.getInstance().apply {
//                timeInMillis = System.currentTimeMillis()
//                set(Calendar.HOUR_OF_DAY, 0)
//                set(Calendar.MINUTE, 0)
//                set(Calendar.SECOND, 0)
//                set(Calendar.MILLISECOND, 0)
//                if (before(Calendar.getInstance())) {
//                    add(Calendar.DATE, 1)
//                }
//            }
//
//            alarmManager.setExactAndAllowWhileIdle(
//                AlarmManager.RTC_WAKEUP,
//                calendar.timeInMillis,
//                pendingIntent
//            )
//        }
//    }
//}
//
//
//
//
////package com.example.hansol_high_school
////
////import io.flutter.embedding.android.FlutterActivity
////import io.flutter.embedding.engine.FlutterEngine
////import io.flutter.plugin.common.MethodChannel
////import androidx.work.OneTimeWorkRequestBuilder
////import androidx.work.WorkManager
////import androidx.work.Data
////import android.util.Log
////import android.app.AlarmManager
////import android.app.PendingIntent
////import android.content.Context
////import android.content.Intent
////
////class MainActivity : FlutterActivity() {
////    private val channelName = "com.example.hansol_high_school/alarm"
////
////    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
////        super.configureFlutterEngine(flutterEngine)
////
////        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
////            when (call.method) {
////                "scheduleMealNotification" -> {
////                    val hour = call.argument<String>("hour")?.toIntOrNull()
////                    val minute = call.argument<String>("minute")?.toIntOrNull()
////                    val notificationTitle = call.argument<String>("notificationTitle")
////                    val mealMenu = call.argument<String>("mealMenu")
////
////                    if (hour != null && minute != null && notificationTitle != null && mealMenu != null) {
////                        Log.d("MainActivity", "Scheduling notification: $notificationTitle at $hour:$minute with menu: $mealMenu")
////                        scheduleMealNotification(hour, minute, notificationTitle, mealMenu)
////                        result.success(null)
////                    } else {
////                        Log.e("MainActivity", "Invalid arguments for scheduling notification")
////                        result.error("INVALID_ARGUMENTS", "Invalid arguments for scheduling notification", null)
////                    }
////                }
////                "cancelMealNotification" -> {
////                    val notificationTitle = call.argument<String>("notificationTitle")
////                    if (notificationTitle != null) {
////                        Log.d("MainActivity", "Cancelling notification: $notificationTitle")
////                        cancelMealNotification(notificationTitle)
////                        result.success(null)
////                    } else {
////                        Log.e("MainActivity", "Invalid arguments for cancelling notification")
////                        result.error("INVALID_ARGUMENTS", "Invalid arguments for cancelling notification", null)
////                    }
////                }
////                else -> result.notImplemented()
////            }
////        }
////    }
////
////    private fun scheduleMealNotification(hour: Int, minute: Int, notificationTitle: String, mealMenu: String) {
////        val inputData = Data.Builder()
////            .putString("notificationTitle", notificationTitle)
////            .putString("mealMenu", mealMenu)
////            .putInt("hour", hour)
////            .putInt("minute", minute)
////            .build()
////
////        val workRequest = OneTimeWorkRequestBuilder<MealWorker>()
////            .setInputData(inputData)
////            .build()
////
////        Log.d("MainActivity", "Enqueuing work request for notification: $notificationTitle at $hour:$minute")
////        WorkManager.getInstance(this).enqueue(workRequest)
////    }
////
////    private fun cancelMealNotification(notificationTitle: String) {
////        val intent = Intent(this, MealNotificationReceiver::class.java).apply {
////            action = "com.example.hansol_high_school.NOTIFY_MEAL"
////        }
////
////        val pendingIntent = PendingIntent.getBroadcast(
////            this, notificationTitle.hashCode(), intent,
////            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
////        )
////
////        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
////        alarmManager.cancel(pendingIntent)
////
////        Log.d("MainActivity", "Cancelled notification: $notificationTitle")
////    }
////}
//
//
//
