package com.example.hansol_high_school

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.Calendar

class MealWorker(context: Context, workerParams: WorkerParameters) : Worker(context, workerParams) {
    override fun doWork(): Result {
        val notificationTitle = inputData.getString("notificationTitle") ?: return Result.failure()
        val mealMenu = inputData.getString("mealMenu") ?: return Result.failure()
        val hour = inputData.getInt("hour", 0)
        val minute = inputData.getInt("minute", 0)

        Log.d("MealWorker", "Received work request for notification: $notificationTitle at $hour:$minute with menu: $mealMenu")

        val intent = Intent(applicationContext, MealNotificationReceiver::class.java).apply {
            action = "com.example.hansol_high_school.NOTIFY_MEAL"
            putExtra("notificationTitle", notificationTitle)
            putExtra("mealMenu", mealMenu)
            putExtra("hour", hour)
            putExtra("minute", minute)
        }

        val triggerTime = getTriggerTime(hour, minute)
        val currentTime = System.currentTimeMillis()

        if (triggerTime <= currentTime) {
            Log.d("MealWorker", "$notificationTitle notification time has already passed for $hour:$minute")
            return Result.failure()
        }

        val pendingIntent = PendingIntent.getBroadcast(
            applicationContext, notificationTitle.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = applicationContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)

        Log.d("MealWorker", "Scheduled $notificationTitle notification for $hour:$minute with menu: $mealMenu")
        return Result.success()
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
