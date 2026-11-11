package com.CREXST.streak

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.crexst.streak/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateStreakWidget" -> {
                    val streakCount = call.argument<String>("streak_count") ?: "1"
                    val isPracticed = call.argument<Boolean>("is_practiced_today") ?: false
                    val mascotMood = call.argument<String>("mascot_mood") ?: "morning"
                    val statusMessage = call.argument<String>("status_message")
                        ?: "Start early! Keep your streak alive."

                    PrashnixStreakWidgetProvider.updateWidgetData(
                        applicationContext,
                        streakCount,
                        isPracticed,
                        mascotMood,
                        statusMessage
                    )
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
