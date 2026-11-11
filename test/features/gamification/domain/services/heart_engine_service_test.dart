import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:prashnix/features/gamification/domain/services/heart_engine_service.dart';

void main() {
  late HeartEngineService engine;

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  setUp(() {
    engine = HeartEngineService();
  });

  group('HeartEngineService 10y Senior QA Bulletproof Tests', () {
    test('calculateRegeneratedHearts: returns full hearts if midnight IST has passed', () {
      final istLocation = tz.getLocation('Asia/Kolkata');
      final nowUtc = DateTime.now().toUtc();
      
      // Last regen was yesterday at 11:00 PM IST
      final yesterdayIst = tz.TZDateTime(istLocation, nowUtc.year, nowUtc.month, nowUtc.day - 1, 23, 0);
      final lastRegenUtc = yesterdayIst.toUtc();

      final result = engine.calculateRegeneratedHearts(1, lastRegenUtc);

      expect(result.updatedHearts, HeartEngineService.maxHearts);
      expect(result.secondsUntilNextRegen, 0);
    });

    test('calculateRegeneratedHearts: returns current hearts if less than 120 mins elapsed on same day', () {
      final now = DateTime.utc(2026, 9, 9, 12, 0); // Noon UTC
      final lastRegen = now.subtract(const Duration(minutes: 45));

      final result = engine.calculateRegeneratedHearts(3, lastRegen, nowTime: now);

      expect(result.updatedHearts, 3);
      // 120 - 45 = 75 minutes remaining
      expect(result.secondsUntilNextRegen, (120 * 60) - (45 * 60));
    });

    test('calculateRegeneratedHearts: adds 1 heart every 2 hours (120 mins) with rolling window', () {
      final now = DateTime.utc(2026, 9, 9, 12, 0); // Noon UTC
      // 4 hours and 15 mins elapsed = 255 mins -> 2 hearts added (4 hours), 15 mins towards 3rd heart
      final lastRegen = now.subtract(const Duration(hours: 4, minutes: 15));

      final result = engine.calculateRegeneratedHearts(1, lastRegen, nowTime: now);

      expect(result.updatedHearts, 3); // 1 + 2 hearts
      // 120 - 15 = 105 mins remaining until next heart
      expect(result.secondsUntilNextRegen, 105 * 60);
    });

    test('calculateRegeneratedHearts: 10 hours elapsed fully restores 5 hearts', () {
      final now = DateTime.utc(2026, 9, 9, 16, 0);
      final lastRegen = now.subtract(const Duration(hours: 10)); // 600 mins

      final result = engine.calculateRegeneratedHearts(0, lastRegen, nowTime: now);

      expect(result.updatedHearts, HeartEngineService.maxHearts);
      expect(result.secondsUntilNextRegen, 0);
    });

    test('calculateRegeneratedHearts: caps at maxHearts (5) and returns 0 remaining seconds', () {
      final now = DateTime.now().toUtc();
      final lastRegen = now.subtract(const Duration(hours: 100)); // many days

      final result = engine.calculateRegeneratedHearts(20, lastRegen);

      expect(result.updatedHearts, HeartEngineService.maxHearts);
      expect(result.secondsUntilNextRegen, 0);
    });

    test('calculateRegeneratedHearts: anti-cheat rollback protection when clock is turned backwards', () {
      final now = DateTime.utc(2026, 9, 9, 12, 0);
      // Clock anomaly: lastRegen is in the future
      final futureLastRegen = now.add(const Duration(hours: 2));

      final result = engine.calculateRegeneratedHearts(2, futureLastRegen, nowTime: now);

      expect(result.updatedHearts, 2);
      expect(result.secondsUntilNextRegen, 120 * 60);
    });

    test('calculateRegeneratedHearts: resets to full hearts when crossing 00:00 IST even on same UTC day', () {
      // 2026-10-29 18:25:00 UTC = 2026-10-29 23:55:00 IST (Day 1)
      final day1BeforeMidnightUtc = DateTime.utc(2026, 10, 29, 18, 25);
      // 2026-10-29 18:35:00 UTC = 2026-10-30 00:05:00 IST (Day 2 in IST, but still Day 1 in UTC!)
      final day2AfterMidnightUtc = DateTime.utc(2026, 10, 29, 18, 35);

      final result = engine.calculateRegeneratedHearts(
        1,
        day1BeforeMidnightUtc,
        nowTime: day2AfterMidnightUtc,
      );

      expect(result.updatedHearts, HeartEngineService.maxHearts);
      expect(result.secondsUntilNextRegen, 0);
    });

    test('calculateStreakBonus: returns 2 hearts every 5 consecutive correct answers', () {
      expect(engine.calculateStreakBonus(1), 0);
      expect(engine.calculateStreakBonus(4), 0);
      expect(engine.calculateStreakBonus(5), 2);
      expect(engine.calculateStreakBonus(10), 2);
      expect(engine.calculateStreakBonus(11), 0);
    });

    test('canLaunchLesson: returns true only if hearts >= 2', () {
      expect(engine.canLaunchLesson(0), isFalse);
      expect(engine.canLaunchLesson(1), isFalse);
      expect(engine.canLaunchLesson(2), isTrue);
      expect(engine.canLaunchLesson(3), isTrue);
      expect(engine.canLaunchLesson(5), isTrue);
    });
  });
}
