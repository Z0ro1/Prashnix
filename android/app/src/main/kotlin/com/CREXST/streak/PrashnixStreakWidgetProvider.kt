package com.CREXST.streak

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class PrashnixStreakWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val streakCount = prefs.getString(KEY_STREAK, "1") ?: "1"
        val isPracticed = prefs.getBoolean(KEY_PRACTICED, false)
        val mascotMood = prefs.getString(KEY_MOOD, "morning") ?: "morning"
        val statusMessage = prefs.getString(KEY_STATUS, "Start early! Keep your streak alive.")
            ?: "Start early! Keep your streak alive."

        for (widgetId in appWidgetIds) {
            val views = buildRemoteViews(context, streakCount, isPracticed, mascotMood, statusMessage)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    companion object {
        const val PREFS_NAME = "prashnix_widget_prefs"
        const val KEY_STREAK = "streak_count"
        const val KEY_PRACTICED = "is_practiced_today"
        const val KEY_MOOD = "mascot_mood"
        const val KEY_STATUS = "status_message"

        fun updateWidgetData(
            context: Context,
            streakCount: String,
            isPracticed: Boolean,
            mascotMood: String,
            statusMessage: String
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().apply {
                putString(KEY_STREAK, streakCount)
                putBoolean(KEY_PRACTICED, isPracticed)
                putString(KEY_MOOD, mascotMood)
                putString(KEY_STATUS, statusMessage)
                apply()
            }

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, PrashnixStreakWidgetProvider::class.java)
            val widgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            if (widgetIds != null && widgetIds.isNotEmpty()) {
                val views = buildRemoteViews(context, streakCount, isPracticed, mascotMood, statusMessage)
                appWidgetManager.updateAppWidget(widgetIds, views)
            }
        }

        private fun buildRemoteViews(
            context: Context,
            streakCount: String,
            isPracticed: Boolean,
            mascotMood: String,
            statusMessage: String
        ): RemoteViews {
            return RemoteViews(context.packageName, R.layout.prashnix_streak_widget).apply {
                setTextViewText(R.id.widget_streak_count, streakCount)
                setTextViewText(R.id.widget_status_message, statusMessage)

                // Select dynamic emotional mascot
                val mascotRes = when {
                    isPracticed || mascotMood == "completed" -> R.drawable.ic_mascot_completed
                    mascotMood == "night" -> R.drawable.ic_mascot_night
                    mascotMood == "afternoon" -> R.drawable.ic_mascot_afternoon
                    else -> R.drawable.ic_mascot_morning
                }
                setImageViewResource(R.id.widget_mascot_image, mascotRes)

                // Button state text
                if (isPracticed) {
                    setTextViewText(R.id.widget_action_text, "STREAK SAFE")
                } else {
                    setTextViewText(R.id.widget_action_text, "PRACTICE NOW")
                }

                // 1-Tap Deep Link to launch app directly into lesson
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("prashnix://start_lesson")).apply {
                    setClass(context, MainActivity::class.java)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                setOnClickPendingIntent(R.id.widget_action_button, pendingIntent)
            }
        }
    }
}
