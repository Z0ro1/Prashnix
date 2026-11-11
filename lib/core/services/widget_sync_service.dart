import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WidgetSyncService {
  WidgetSyncService._();

  static const MethodChannel _channel = MethodChannel('com.crexst.streak/widget');

  /// Initializes widget sync on app launch
  static Future<void> initialize() async {
    // Ready for native platform communication
  }

  /// Syncs streak, mascot emotional mood, and daily practice status to the native home screen widget (in English).
  static Future<void> syncStreakWidget({
    required int streakCount,
    required bool isPracticedToday,
    int? heartCount,
  }) async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return;

      final hour = DateTime.now().hour;
      String mascotMood;
      String statusMessage;

      if (isPracticedToday) {
        mascotMood = 'completed';
        statusMessage = 'Streak safe for today! See you tomorrow! 🔥';
      } else if (hour >= 21) {
        // 9 PM - Midnight: Code Red Urgent Alert
        mascotMood = 'night';
        statusMessage = 'Protect your streak! Less than 3 hrs left!';
      } else if (hour >= 18) {
        // 6 PM - 9 PM: Evening Alert
        mascotMood = 'night';
        statusMessage = "Don't break your streak! Quick lesson now?";
      } else if (hour >= 12) {
        // 12 PM - 6 PM: Afternoon Reminder
        mascotMood = 'afternoon';
        statusMessage = 'Afternoon practice time! Keep the momentum.';
      } else {
        // 5 AM - 12 PM: Early Morning Motivation
        mascotMood = 'morning';
        statusMessage = 'Start early! Keep your streak alive.';
      }

      final safeStreak = streakCount > 0 ? streakCount.toString() : '0';

      if (Platform.isAndroid) {
        await _channel.invokeMethod('updateStreakWidget', {
          'streak_count': safeStreak,
          'is_practiced_today': isPracticedToday,
          'mascot_mood': mascotMood,
          'status_message': statusMessage,
          'heart_count': ?heartCount,
        });
      }

      debugPrint('[WidgetSyncService] Widget updated -> streak: $safeStreak, mood: $mascotMood, done: $isPracticedToday');
    } catch (e) {
      debugPrint('[WidgetSyncService] syncStreakWidget error: $e');
    }
  }
}
