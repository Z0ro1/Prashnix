import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class HeartEngineResult {
  final int updatedHearts;
  final DateTime nextRegenTime;
  final int secondsUntilNextRegen;

  HeartEngineResult({
    required this.updatedHearts,
    required this.nextRegenTime,
    required this.secondsUntilNextRegen,
  });
}

class HeartEngineService {
  static const int maxHearts = 5;
  static const int heartCostPerLesson = 1;
  static const int heartPenaltyPerMistake = 0;
  static const int regenIntervalMinutes = 60;
  
  static bool _tzInitialized = false;
  static late final tz.Location _istLocation;

  HeartEngineService() {
    _initTz();
  }

  void _initTz() {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _istLocation = tz.getLocation('Asia/Kolkata');
      _tzInitialized = true;
    }
  }

  /// Calculates regenerated hearts based on time elapsed since last regen,
  /// factoring in midnight IST resets and hourly ticks.
  HeartEngineResult calculateRegeneratedHearts(int currentHearts, DateTime lastRegenTime, {DateTime? nowTime}) {
    if (!_tzInitialized) _initTz();
    
    final now = (nowTime ?? DateTime.now()).toUtc();
    final nowIst = tz.TZDateTime.from(now, _istLocation);
    final lastRegenIst = tz.TZDateTime.from(lastRegenTime.toUtc(), _istLocation);

    // 1. Check for Midnight IST Reset
    // If 'now' is on a different day than 'lastRegen', or multiple days have passed.
    final lastMidnight = tz.TZDateTime(_istLocation, nowIst.year, nowIst.month, nowIst.day);
    if (lastRegenIst.isBefore(lastMidnight)) {
      // Midnight reset triggered
      return HeartEngineResult(
        updatedHearts: maxHearts,
        nextRegenTime: now,
        secondsUntilNextRegen: 0,
      );
    }

    // 2. Calculate Hourly Regeneration
    if (currentHearts >= maxHearts) {
      return HeartEngineResult(
        updatedHearts: maxHearts,
        nextRegenTime: now,
        secondsUntilNextRegen: 0,
      );
    }

    final durationSinceLastRegen = nowIst.difference(lastRegenIst);
    final totalMinutesElapsed = durationSinceLastRegen.inMinutes;

    if (totalMinutesElapsed >= regenIntervalMinutes) {
      final heartsToRegen = totalMinutesElapsed ~/ regenIntervalMinutes;
      final newHearts = (currentHearts + heartsToRegen).clamp(0, maxHearts);
      
      // Calculate the exact time the LAST regenerated heart was credited to maintain accurate rolling windows
      final exactRegenMinutes = heartsToRegen * regenIntervalMinutes;
      final exactLastRegenTime = lastRegenTime.add(Duration(minutes: exactRegenMinutes));
      
      final remainingSeconds = (regenIntervalMinutes * 60) - nowIst.difference(tz.TZDateTime.from(exactLastRegenTime, _istLocation)).inSeconds;

      return HeartEngineResult(
        updatedHearts: newHearts,
        nextRegenTime: exactLastRegenTime,
        secondsUntilNextRegen: newHearts == maxHearts ? 0 : remainingSeconds,
      );
    }

    // 3. Less than an hour passed, just return the remaining time
    final remainingSeconds = (regenIntervalMinutes * 60) - durationSinceLastRegen.inSeconds;
    
    return HeartEngineResult(
      updatedHearts: currentHearts,
      nextRegenTime: lastRegenTime,
      secondsUntilNextRegen: remainingSeconds,
    );
  }

  bool canLaunchLesson(int currentHearts) {
    return currentHearts >= heartCostPerLesson;
  }

  int calculateStreakBonus(int currentConsecutiveCorrect) {
    if (currentConsecutiveCorrect > 0 && currentConsecutiveCorrect % 5 == 0) {
      return 2; // +2 hearts every 5 consecutive answers
    }
    return 0;
  }
}
