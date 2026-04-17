package com.monkshark.hansol_high_school;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;
import android.app.PendingIntent;
import android.content.Intent;
import android.view.View;

public class CombinedWidgetProvider extends AppWidgetProvider {

    private static final int[] PERIOD_TEXT_IDS = {
            R.id.period_1, R.id.period_2, R.id.period_3,
            R.id.period_4, R.id.period_5, R.id.period_6, R.id.period_7
    };
    private static final int[] SUBJECT_TEXT_IDS = {
            R.id.subject_1, R.id.subject_2, R.id.subject_3,
            R.id.subject_4, R.id.subject_5, R.id.subject_6, R.id.subject_7
    };
    private static final int[] ROW_IDS = {
            R.id.row_1, R.id.row_2, R.id.row_3,
            R.id.row_4, R.id.row_5, R.id.row_6, R.id.row_7
    };

    @Override
    public void onEnabled(Context context) {
        super.onEnabled(context);
        WidgetUpdateReceiver.scheduleMidnightUpdate(context);
    }

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId);
        }
    }

    static void updateWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        try {
        SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);
        WidgetTheme theme = WidgetTheme.of(context);
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.combined_widget);

        views.setInt(R.id.widget_root, "setBackgroundResource", theme.background);

        String mealDate = prefs.getString("meal_date", "");
        String timetableDate = prefs.getString("timetable_date", "");
        views.setTextViewText(R.id.meal_date, mealDate);
        views.setTextColor(R.id.meal_date, theme.titleColor);
        views.setTextViewText(R.id.timetable_date, timetableDate);
        views.setTextColor(R.id.timetable_date, theme.titleColor);

        views.setTextColor(R.id.meal_label_breakfast, theme.titleColor);
        views.setTextColor(R.id.meal_label_lunch, theme.titleColor);
        views.setTextColor(R.id.meal_label_dinner, theme.titleColor);

        String breakfast = prefs.getString("meal_breakfast", "정보 없음");
        String lunch = prefs.getString("meal_lunch", "정보 없음");
        String dinner = prefs.getString("meal_dinner", "정보 없음");
        views.setTextViewText(R.id.meal_breakfast, MealWidgetProvider.formatMeal(breakfast));
        views.setTextColor(R.id.meal_breakfast, theme.contentColor);
        views.setTextViewText(R.id.meal_lunch, MealWidgetProvider.formatMeal(lunch));
        views.setTextColor(R.id.meal_lunch, theme.contentColor);
        views.setTextViewText(R.id.meal_dinner, MealWidgetProvider.formatMeal(dinner));
        views.setTextColor(R.id.meal_dinner, theme.contentColor);

        views.setInt(R.id.divider, "setBackgroundColor", theme.dividerColor);

        String data = prefs.getString("timetable_data", "");
        int currentPeriod = 0;
        try { currentPeriod = prefs.getInt("timetable_current", 0); } catch (Exception e) {}
        String[] subjects = data.isEmpty() ? new String[0] : data.split(",");

        for (int i = 0; i < 7; i++) {
            if (i < subjects.length) {
                views.setViewVisibility(ROW_IDS[i], View.VISIBLE);
                views.setTextViewText(PERIOD_TEXT_IDS[i], (i + 1) + "교시");
                String subjectText = subjects[i].isEmpty() ? "-" : subjects[i];
                views.setTextViewText(SUBJECT_TEXT_IDS[i], subjectText);

                boolean isCurrent = (currentPeriod == i + 1);
                views.setTextColor(SUBJECT_TEXT_IDS[i], isCurrent ? theme.currentTextColor : theme.contentColor);
                views.setTextColor(PERIOD_TEXT_IDS[i], isCurrent ? theme.currentTextColor : theme.periodColor);
            } else {
                views.setViewVisibility(ROW_IDS[i], View.GONE);
            }
        }

        if (subjects.length == 0) {
            views.setViewVisibility(R.id.empty_text, View.VISIBLE);
            views.setTextColor(R.id.empty_text, theme.subColor);
        } else {
            views.setViewVisibility(R.id.empty_text, View.GONE);
        }

        Intent intent = new Intent(context, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent);

        appWidgetManager.updateAppWidget(appWidgetId, views);
        } catch (Exception e) {
            android.util.Log.e("CombinedWidget", "Error updating widget", e);
        }
    }
}
