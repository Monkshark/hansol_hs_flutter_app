package com.monkshark.hansol_high_school;

import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Color;
import android.widget.RemoteViews;

public class WidgetTheme {
    public final int background;
    public final int primaryColor;
    public final int titleColor;
    public final int contentColor;
    public final int subColor;
    public final int dividerColor;
    public final int currentTextColor;
    public final int periodColor;

    private WidgetTheme(boolean isDark) {
        if (isDark) {
            background = R.drawable.widget_background_dark;
            primaryColor = Color.parseColor("#7EB8DA");
            titleColor = Color.parseColor("#7EB8DA");
            contentColor = Color.parseColor("#CCCCCC");
            subColor = Color.parseColor("#888888");
            dividerColor = Color.parseColor("#2A2D35");
            currentTextColor = Color.parseColor("#7EB8DA");
            periodColor = Color.parseColor("#888888");
        } else {
            background = R.drawable.widget_background;
            primaryColor = Color.parseColor("#3F72AF");
            titleColor = Color.parseColor("#3F72AF");
            contentColor = Color.parseColor("#555555");
            subColor = Color.parseColor("#999999");
            dividerColor = Color.parseColor("#E0E0E0");
            currentTextColor = Color.parseColor("#3F72AF");
            periodColor = Color.parseColor("#999999");
        }
    }

    public static WidgetTheme of(Context context) {
        int uiMode = context.getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK;
        return new WidgetTheme(uiMode == Configuration.UI_MODE_NIGHT_YES);
    }
}
