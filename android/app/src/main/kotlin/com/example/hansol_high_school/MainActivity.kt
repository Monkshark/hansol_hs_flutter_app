package com.example.hansol_high_school

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Data

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.hansol_high_school/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "scheduleMealNotification") {
                val hour = call.argument<Int>("hour") ?: return@setMethodCallHandler
                val minute = call.argument<Int>("minute") ?: return@setMethodCallHandler
                val mealType = call.argument<String>("mealType") ?: return@setMethodCallHandler
                val mealMenu = call.argument<String>("mealMenu") ?: return@setMethodCallHandler

                scheduleMealNotification(hour, minute, mealType, mealMenu)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun scheduleMealNotification(hour: Int, minute: Int, mealType: String, mealMenu: String) {
        val inputData = Data.Builder()
                .putString("mealType", mealType)
                .putString("mealMenu", mealMenu)
                .putInt("hour", hour)
                .putInt("minute", minute)
                .build()

        val workRequest = OneTimeWorkRequestBuilder<MealWorker>()
                .setInputData(inputData)
                .build()

        WorkManager.getInstance(this).enqueue(workRequest)
    }

    private fun getTriggerTime(hour: Int, minute: Int): Long {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)

            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }
        return calendar.timeInMillis
    }
}
