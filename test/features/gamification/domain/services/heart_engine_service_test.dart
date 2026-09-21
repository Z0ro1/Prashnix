import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:streak/features/gamification/domain/services/heart_engine_service.dart';

void main() {
  late HeartEngineService engine;

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  setUp(() {
    engine = HeartEngineService();
  });

  group('HeartEngineService Calculations', () {
    test('calculateRegeneratedHearts: returns full hearts if midnight IST has passed', () {
      final istLocation = tz.getLocation('Asia/Kolkata');
      
      // Assume "now" is noon on a specific day in UTC
      final nowUtc = DateTime.now().toUtc();
      
      // Last regen was yesterday at 11:00 PM IST
      final yesterdayIst = tz.TZDateTime(istLocation, nowUtc.year, nowUtc.month, nowUtc.day - 1, 23, 0);
      final lastRegenUtc = yesterdayIst.toUtc();

      final result = engine.calculateRegeneratedHearts(5, lastRegenUtc);

      expect(result.updatedHearts, HeartEngineService.maxHearts);
      expect(result.secondsUntilNextRegen, 0);
    });

    test('calculateRegeneratedHearts: returns current hearts if less than 60 mins elapsed on same day', () {
      final now = DateTime.utc(2026, 9, 9, 12, 0); // Noon UTC
      final lastRegen = now.subtract(const Duration(minutes: 30));

      final result = engine.calculateRegeneratedHearts(10, lastRegen, nowTime: now);

      expect(result.updatedHearts, 10);
      expect(result.secondsUntilNextRegen, (60 * 60) - (30 * 60)); // 30 mins remaining
    });

    test('calculateRegeneratedHearts: calculates correct number of hearts added if multiple hours passed', () {
      final now = DateTime.utc(2026, 9, 9, 12, 0); // Noon UTC
      final lastRegen = now.subtract(const Duration(hours: 3, minutes: 15)); // 195 mins elapsed

      final result = engine.calculateRegeneratedHearts(10, lastRegen, nowTime: now);

      expect(result.updatedHearts, 13); // 10 + 3
      // Next regen should be in 45 mins (since 15 mins have passed towards the next hour)
      expect(result.secondsUntilNextRegen, (45 * 60)); 
    });

    test('calculateRegeneratedHearts: caps at maxHearts', () {
      final now = DateTime.now().toUtc();
      final lastRegen = now.subtract(const Duration(hours: 100)); // many days

      final result = engine.calculateRegeneratedHearts(20, lastRegen);

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

    test('canLaunchLesson: returns true only if hearts >= 20', () {
      expect(engine.canLaunchLesson(19), isFalse);
      expect(engine.canLaunchLesson(20), isTrue);
      expect(engine.canLaunchLesson(25), isTrue);
    });
  });
}
