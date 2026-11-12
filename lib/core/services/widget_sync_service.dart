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
        statusMessage = 'शाब्बास! आजची ड्युटी पूर्ण! 🔥';
      } else if (hour >= 21) {
        // 9 PM - Midnight: Code Red Urgent Alert
        mascotMood = 'night';
        statusMessage = '🚨 शेवटची संधी! वाचवा माझी streak!';
      } else if (hour >= 18) {
        // 6 PM - 9 PM: Evening Alert
        mascotMood = 'evening';
        statusMessage = 'सावधान! Streak तुटणार! टेस्ट सोडवा!';
      } else if (hour >= 12) {
        // 12 PM - 6 PM: Afternoon Reminder
        mascotMood = 'afternoon';
        statusMessage = 'काय मग, अभ्यास झाला नाही का अजून?';
      } else {
        // 5 AM - 12 PM: Early Morning Motivation
        mascotMood = 'morning';
        statusMessage = 'उठा जवान! सकाळची ड्रिल पूर्ण करा!';
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
