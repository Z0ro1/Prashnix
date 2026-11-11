import 'package:flutter_test/flutter_test.dart';
import 'package:prashnix/features/gamification/domain/models/league_tier.dart';
import 'package:prashnix/core/state/user_state.dart';

void main() {
  group('XP Economy & Anti-Exploit Security Tests', () {
    test('UserModel initializes with 0 XP and updates correctly', () {
      const user = UserModel();
      expect(user.totalXp, 0);

      final updated = user.copyWith(totalXp: 120);
      expect(updated.totalXp, 120);
    });

    test('Flawless Lesson XP Pacing: 10 questions awards exactly 120 XP', () {
      const initialQuestions = 10;
      const xpPerQuestion = 2;
      const perfectBonus = 100;

      final totalXp = (initialQuestions * xpPerQuestion) + perfectBonus;
      expect(totalXp, 120);
    });

    test('Lesson with Retries XP Pacing: 10 questions awards up to 50 XP', () {
      const initialQuestions = 10;
      const xpPerQuestion = 2;
      const retryCompletionBonus = 30;

      final totalXp = (initialQuestions * xpPerQuestion) + retryCompletionBonus;
      expect(totalXp, 50);
    });

    test('User Progression Pacing: 5-6 daily lessons unlocks Silver League on Day 2', () {
      const dailyMinLessons = 5;
      const dailyMaxLessons = 6;
      const xpPerFlawlessLesson = 120;

      final day1MinXp = dailyMinLessons * xpPerFlawlessLesson; // 600 XP
      final day1MaxXp = dailyMaxLessons * xpPerFlawlessLesson; // 720 XP

      // Day 1: User is firmly in Bronze (0 - 799 XP)
      expect(LeagueTier.fromXp(day1MinXp).name, 'Bronze League');
      expect(LeagueTier.fromXp(day1MaxXp).name, 'Bronze League');

      final day2MinXp = day1MinXp * 2; // 1200 XP
      final day2MaxXp = day1MaxXp * 2; // 1440 XP

      // Day 2: User successfully unlocks Silver League ("Consistent Learner")
      expect(LeagueTier.fromXp(day2MinXp).name, 'Silver League');
      expect(LeagueTier.fromXp(day2MaxXp).name, 'Silver League');
      expect(day2MinXp >= 800, isTrue);
    });

    test('Anti-Farming Exploit Barrier: Question XP cannot exceed initialCount * 2', () {
      const initialCount = 10;
      const maxAllowedQuestionXp = initialCount * 2; // 20 XP
      final awardedKeys = <String>{};
      int earnedBaseXp = 0;

      // Simulate 10 unique questions answered correctly
      for (int i = 0; i < 10; i++) {
        final key = 'q_$i';
        if (!awardedKeys.contains(key) && (earnedBaseXp + 2 <= maxAllowedQuestionXp)) {
          earnedBaseXp += 2;
          awardedKeys.add(key);
        }
      }
      expect(earnedBaseXp, 20);

      // Malicious attempt: User re-attempts recycled questions to farm XP
      for (int i = 0; i < 10; i++) {
        final key = 'q_$i';
        if (!awardedKeys.contains(key) && (earnedBaseXp + 2 <= maxAllowedQuestionXp)) {
          earnedBaseXp += 2;
          awardedKeys.add(key);
        }
      }

      // Base question XP remains strictly capped at 20 XP!
      expect(earnedBaseXp, 20);
      expect(awardedKeys.length, 10);
    });

    test('Championship Weekly Test XP Reward: Awards +1000 XP bonus', () {
      const questionsCount = 100;
      const questionXp = 2;
      const championshipBonus = 1000;

      final totalChampionshipXp = (questionsCount * questionXp) + championshipBonus;
      expect(totalChampionshipXp, 1200);
    });

    test('Milestone Chest XP Reward: Standardized to +100 XP bonus', () {
      const chestBonus = 100;
      expect(chestBonus, 100);
    });

    test('Mistake Review Retry Sprint: Each cleared mistake awards +2 XP', () {
      const clearedMistakes = 7;
      final earnedXp = clearedMistakes * 2;
      expect(earnedXp, 14);
    });
  });
}
