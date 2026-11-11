import 'package:flutter_test/flutter_test.dart';
import 'package:prashnix/features/gamification/domain/models/league_tier.dart';

void main() {
  group('LeagueTier Progression Tests', () {
    test('fromXp: correctly identifies all 6 League tiers', () {
      // Bronze: 0 - 799 XP
      expect(LeagueTier.fromXp(0).name, 'Bronze League');
      expect(LeagueTier.fromXp(500).name, 'Bronze League');
      expect(LeagueTier.fromXp(799).name, 'Bronze League');

      // Silver: 800 - 2,499 XP (Day 2 Consistent Learner Milestone)
      expect(LeagueTier.fromXp(800).name, 'Silver League');
      expect(LeagueTier.fromXp(1500).name, 'Silver League');
      expect(LeagueTier.fromXp(2499).name, 'Silver League');

      // Gold: 2,500 - 5,999 XP
      expect(LeagueTier.fromXp(2500).name, 'Gold League');
      expect(LeagueTier.fromXp(5999).name, 'Gold League');

      // Platinum: 6,000 - 12,499 XP
      expect(LeagueTier.fromXp(6000).name, 'Platinum League');
      expect(LeagueTier.fromXp(12499).name, 'Platinum League');

      // Diamond: 12,500 - 24,999 XP
      expect(LeagueTier.fromXp(12500).name, 'Diamond League');
      expect(LeagueTier.fromXp(24999).name, 'Diamond League');

      // Champion: 25,000+ XP
      expect(LeagueTier.fromXp(25000).name, 'Champion League');
      expect(LeagueTier.fromXp(50000).name, 'Champion League');
    });

    test('nextTier & xpNeededForNext work accurately across tiers', () {
      final bronze = LeagueTier.fromXp(500);
      expect(bronze.nextTier?.name, 'Silver League');
      expect(bronze.xpNeededForNext(500), 300); // 800 - 500 = 300

      final champion = LeagueTier.fromXp(30000);
      expect(champion.nextTier, isNull);
      expect(champion.xpNeededForNext(30000), 0);
    });

    test('progress calculates normalized progression from 0.0 to 1.0', () {
      final tier = LeagueTier.fromXp(800); // Silver (800 - 2499, range = 1700)
      expect(tier.progress(800), 0.0);
      expect(tier.progress(1650), closeTo(0.5, 0.01));
      expect(tier.progress(2499), closeTo(1.0, 0.01));
    });
  });
}
