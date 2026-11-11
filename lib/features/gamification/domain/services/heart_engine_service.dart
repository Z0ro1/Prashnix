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
  static const int heartCostPerLesson = 2;
  static const int heartPenaltyPerMistake = 0;
  static const int regenIntervalMinutes = 120; // 1 heart per 2 hours (full refill in 10 hours)
  
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

  tz.Location get istLocation {
    if (!_tzInitialized) _initTz();
    return _istLocation;
  }

  /// Calculates regenerated hearts based on time elapsed since last regen,
  /// factoring in midnight IST resets and 2-hour rolling intervals.
  HeartEngineResult calculateRegeneratedHearts(int currentHearts, DateTime lastRegenTime, {DateTime? nowTime}) {
    if (!_tzInitialized) _initTz();
    
    final now = (nowTime ?? DateTime.now()).toUtc();
    final nowIst = tz.TZDateTime.from(now, _istLocation);
    final lastRegenIst = tz.TZDateTime.from(lastRegenTime.toUtc(), _istLocation);

    // Anti-Cheat / Clock Rollback Protection:
    // If the device clock was turned backward or an impossible time anomaly occurred
    if (nowIst.isBefore(lastRegenIst)) {
      return HeartEngineResult(
        updatedHearts: currentHearts.clamp(0, maxHearts),
        nextRegenTime: now,
        secondsUntilNextRegen: currentHearts >= maxHearts ? 0 : regenIntervalMinutes * 60,
      );
    }

    // 1. Check for Midnight IST Reset
    // If 'now' is on a different day than 'lastRegen', or midnight IST has passed.
    final lastMidnight = tz.TZDateTime(_istLocation, nowIst.year, nowIst.month, nowIst.day);
    if (lastRegenIst.isBefore(lastMidnight)) {
      // Midnight reset triggered -> Full Refill
      return HeartEngineResult(
        updatedHearts: maxHearts,
        nextRegenTime: now,
        secondsUntilNextRegen: 0,
      );
    }

    // 2. Already at max hearts
    if (currentHearts >= maxHearts) {
      return HeartEngineResult(
        updatedHearts: maxHearts,
        nextRegenTime: now,
        secondsUntilNextRegen: 0,
      );
    }

    // 3. Calculate 2-Hour Interval Regeneration
    final durationSinceLastRegen = nowIst.difference(lastRegenIst);
    final totalMinutesElapsed = durationSinceLastRegen.inMinutes;

    if (totalMinutesElapsed >= regenIntervalMinutes) {
      final heartsToRegen = totalMinutesElapsed ~/ regenIntervalMinutes;
      final newHearts = (currentHearts + heartsToRegen).clamp(0, maxHearts);
      
      if (newHearts >= maxHearts) {
        return HeartEngineResult(
          updatedHearts: maxHearts,
          nextRegenTime: now,
          secondsUntilNextRegen: 0,
        );
      }

      // Calculate the exact time the LAST regenerated heart was credited to maintain accurate rolling windows
      final exactRegenMinutes = heartsToRegen * regenIntervalMinutes;
      final exactLastRegenTime = lastRegenTime.add(Duration(minutes: exactRegenMinutes));
      
      final elapsedSinceLastCredit = nowIst.difference(tz.TZDateTime.from(exactLastRegenTime.toUtc(), _istLocation)).inSeconds;
      final remainingSeconds = ((regenIntervalMinutes * 60) - elapsedSinceLastCredit).clamp(0, regenIntervalMinutes * 60);

      return HeartEngineResult(
        updatedHearts: newHearts,
        nextRegenTime: exactLastRegenTime,
        secondsUntilNextRegen: remainingSeconds,
      );
    }

    // 4. Less than 2 hours passed, return remaining seconds
    final remainingSeconds = ((regenIntervalMinutes * 60) - durationSinceLastRegen.inSeconds).clamp(0, regenIntervalMinutes * 60);
    
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
