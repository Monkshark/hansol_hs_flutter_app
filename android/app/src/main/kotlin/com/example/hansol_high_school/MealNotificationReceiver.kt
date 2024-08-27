package com.example.hansol_high_school

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class MealNotificationReceiver : BroadcastReceiver() {
    private val channelId = "meal_notification_channel"
    private val channelName = "Meal Notifications"

    override fun onReceive(context: Context, intent: Intent) {
        val notificationTitle = intent.getStringExtra("notificationTitle")
        val mealMenu = intent.getStringExtra("mealMenu")
        val hour = intent.getIntExtra("hour", 0)
        val minute = intent.getIntExtra("minute", 0)

        Log.d("MealNotificationReceiver", "Received notification intent: $notificationTitle at $hour:$minute with menu: $mealMenu")

        createNotificationChannel(context)

        val notificationManager = NotificationManagerCompat.from(context)

        val notificationIntent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setContentTitle(notificationTitle)
            .setContentText("아래로 당겨서 메뉴 확인")
            .setStyle(NotificationCompat.BigTextStyle().bigText(mealMenu))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        notificationManager.notify(notificationTitle.hashCode(), notification)
        Log.d("MealNotificationReceiver", "Notification sent for $notificationTitle")
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Channel for meal notifications"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 500, 500)
                setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION), null)
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
            Log.d("MealNotificationReceiver", "Notification channel created")
        }
    }
}
