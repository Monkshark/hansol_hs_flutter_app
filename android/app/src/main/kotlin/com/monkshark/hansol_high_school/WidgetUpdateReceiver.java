package com.monkshark.hansol_high_school;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.net.Uri;
import android.util.Log;

import java.util.Calendar;

import es.antonborri.home_widget.HomeWidgetBackgroundIntent;

/** 자정 위젯 자동 갱신 리시버 */
public class WidgetUpdateReceiver extends BroadcastReceiver {

    private static final String TAG = "WidgetUpdateReceiver";
    private static final String ACTION_UPDATE = "com.monkshark.hansol_high_school.WIDGET_MIDNIGHT_UPDATE";

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        if (ACTION_UPDATE.equals(action) || Intent.ACTION_BOOT_COMPLETED.equals(action)) {
            Log.d(TAG, "Midnight widget update triggered");

            // Dart 백그라운드 콜백 실행 → API 호출 + 위젯 갱신
            try {
                PendingIntent backgroundIntent = HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(
                        context, Uri.parse("homeWidget://widgetUpdate"));
                backgroundIntent.send();
            } catch (Exception e) {
                Log.e(TAG, "Failed to trigger background callback", e);
            }

            scheduleMidnightUpdate(context);
        }
    }

    public static void scheduleMidnightUpdate(Context context) {
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarmManager == null) return;

        Intent intent = new Intent(context, WidgetUpdateReceiver.class);
        intent.setAction(ACTION_UPDATE);
        PendingIntent pendingIntent = PendingIntent.getBroadcast(context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Calendar midnight = Calendar.getInstance();
        midnight.add(Calendar.DAY_OF_YEAR, 1);
        midnight.set(Calendar.HOUR_OF_DAY, 0);
        midnight.set(Calendar.MINUTE, 1);
        midnight.set(Calendar.SECOND, 0);
        midnight.set(Calendar.MILLISECOND, 0);

        alarmManager.setInexactRepeating(
                AlarmManager.RTC,
                midnight.getTimeInMillis(),
                AlarmManager.INTERVAL_DAY,
                pendingIntent
        );

        Log.d(TAG, "Scheduled midnight update at " + midnight.getTime());
    }
}
