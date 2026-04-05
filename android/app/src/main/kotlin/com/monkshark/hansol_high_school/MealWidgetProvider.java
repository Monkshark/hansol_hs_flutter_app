package com.monkshark.hansol_high_school;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;
import android.app.PendingIntent;
import android.content.Intent;

public class MealWidgetProvider extends AppWidgetProvider {

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
        SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);
        WidgetTheme theme = WidgetTheme.of(context);

        String date = prefs.getString("meal_date", "");
        String breakfast = prefs.getString("meal_breakfast", "정보 없음");
        String lunch = prefs.getString("meal_lunch", "정보 없음");
        String dinner = prefs.getString("meal_dinner", "정보 없음");

        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.meal_widget);
        views.setInt(R.id.widget_root, "setBackgroundResource", theme.background);
        views.setTextViewText(R.id.meal_date, date);
        views.setTextColor(R.id.meal_date, theme.titleColor);
        views.setTextViewText(R.id.meal_label_breakfast, "조식");
        views.setTextColor(R.id.meal_label_breakfast, theme.titleColor);
        views.setTextViewText(R.id.meal_label_lunch, "중식");
        views.setTextColor(R.id.meal_label_lunch, theme.titleColor);
        views.setTextViewText(R.id.meal_label_dinner, "석식");
        views.setTextColor(R.id.meal_label_dinner, theme.titleColor);
        views.setTextViewText(R.id.meal_breakfast, formatMeal(breakfast));
        views.setTextColor(R.id.meal_breakfast, theme.contentColor);
        views.setTextViewText(R.id.meal_lunch, formatMeal(lunch));
        views.setTextColor(R.id.meal_lunch, theme.contentColor);
        views.setTextViewText(R.id.meal_dinner, formatMeal(dinner));
        views.setTextColor(R.id.meal_dinner, theme.contentColor);

        Intent intent = new Intent(context, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent);

        appWidgetManager.updateAppWidget(appWidgetId, views);
    }

    static String formatMeal(String meal) {
        if (meal == null || meal.isEmpty() || meal.equals("정보 없음")) return "정보 없음";
        String[] lines = meal.split("\n");
        StringBuilder sb = new StringBuilder();
        int count = 0;
        for (String line : lines) {
            String trimmed = line.trim();
            if (trimmed.isEmpty()) continue;
            if (count > 0) sb.append("\n");
            sb.append(trimmed);
            count++;
            if (count >= 5) { sb.append("\n..."); break; }
        }
        return sb.toString();
    }
}
