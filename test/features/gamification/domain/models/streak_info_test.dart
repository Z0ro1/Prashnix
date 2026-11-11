import 'package:flutter_test/flutter_test.dart';
import 'package:prashnix/features/gamification/domain/models/streak_model.dart';

void main() {
  group('StreakInfo and DailyActivityRecord Tests', () {
    test('default state initialized correctly', () {
      const streak = StreakInfo();
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.streakFreezes, 2);
      expect(streak.isFreezeEquipped, true);
      expect(streak.activeDates, isEmpty);
      expect(streak.frozenDates, isEmpty);
      expect(streak.totalActiveDays, 0);
      expect(streak.lastActiveDate, isNull);
    });

    test('isPracticedOn and isFrozenOn detection', () {
      const streak = StreakInfo(
        currentStreak: 3,
        longestStreak: 5,
        activeDates: {'2026-10-27', '2026-10-28', '2026-10-29'},
        frozenDates: {'2026-10-26'},
      );

      expect(streak.isPracticedOn('2026-10-28'), isTrue);
      expect(streak.isPracticedOn('2026-10-25'), isFalse);
      expect(streak.isFrozenOn('2026-10-26'), isTrue);
      expect(streak.isFrozenOn('2026-10-27'), isFalse);
      expect(streak.totalActiveDays, 3);
    });

    test('daily activity map serialization and parsing', () {
      const record = DailyActivityRecord(lessonsCompleted: 3, xpEarned: 90);
      final map = record.toMap();

      expect(map['lessonsCompleted'], 3);
      expect(map['xpEarned'], 90);

      final parsed = DailyActivityRecord.fromMap(map);
      expect(parsed.lessonsCompleted, 3);
      expect(parsed.xpEarned, 90);
    });

    test('copyWith updates fields immutably', () {
      const streak = StreakInfo(currentStreak: 1, longestStreak: 1);
      final updated = streak.copyWith(
        currentStreak: 2,
        longestStreak: 2,
        streakFreezes: 1,
        activeDates: {'2026-10-29'},
      );

      expect(updated.currentStreak, 2);
      expect(updated.longestStreak, 2);
      expect(updated.streakFreezes, 1);
      expect(updated.activeDates, contains('2026-10-29'));
      expect(streak.currentStreak, 1); // original unchanged
    });
  });
}
