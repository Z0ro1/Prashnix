import 'package:flutter/material.dart';

/// League tiers progression ladder based on Total XP.
/// Bronze (0-499), Silver (500-1499), Gold (1500-2999),
/// Platinum (3000-4999), Diamond (5000-9999), Champion (10000+).
class LeagueTier {
  final String name;
  final int minXp;
  final int? maxXp; // null for highest tier
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String description;
  final int tierLevel; // 1 to 6

  const LeagueTier({
    required this.name,
    required this.minXp,
    required this.maxXp,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.description,
    required this.tierLevel,
  });

  static const List<LeagueTier> tiers = [
    LeagueTier(
      name: 'Bronze League',
      minXp: 0,
      maxXp: 499,
      primaryColor: Color(0xFFCD7F32),
      secondaryColor: Color(0xFF8D5524),
      icon: Icons.shield_rounded,
      description: 'Kickstart your streak & rise up!',
      tierLevel: 1,
    ),
    LeagueTier(
      name: 'Silver League',
      minXp: 500,
      maxXp: 1499,
      primaryColor: Color(0xFFCBD5E1),
      secondaryColor: Color(0xFF64748B),
      icon: Icons.shield_rounded,
      description: 'Rising through the contender ranks!',
      tierLevel: 2,
    ),
    LeagueTier(
      name: 'Gold League',
      minXp: 1500,
      maxXp: 2999,
      primaryColor: Color(0xFFFFB800),
      secondaryColor: Color(0xFFD97706),
      icon: Icons.workspace_premium_rounded,
      description: 'Elite contenders battling for glory!',
      tierLevel: 3,
    ),
    LeagueTier(
      name: 'Platinum League',
      minXp: 3000,
      maxXp: 4999,
      primaryColor: Color(0xFF06B6D4),
      secondaryColor: Color(0xFF0891B2),
      icon: Icons.military_tech_rounded,
      description: 'Master learners proving excellence!',
      tierLevel: 4,
    ),
    LeagueTier(
      name: 'Diamond League',
      minXp: 5000,
      maxXp: 9999,
      primaryColor: Color(0xFFA855F7),
      secondaryColor: Color(0xFF7E22CE),
      icon: Icons.diamond_rounded,
      description: 'Apex champions of the leaderboard!',
      tierLevel: 5,
    ),
    LeagueTier(
      name: 'Champion League',
      minXp: 10000,
      maxXp: null,
      primaryColor: Color(0xFFFF3366),
      secondaryColor: Color(0xFFDC2626),
      icon: Icons.local_fire_department_rounded,
      description: 'Legendary Hall of Fame status!',
      tierLevel: 6,
    ),
  ];

  /// Get the appropriate league tier for a given XP.
  static LeagueTier fromXp(int xp) {
    for (int i = tiers.length - 1; i >= 0; i--) {
      if (xp >= tiers[i].minXp) {
        return tiers[i];
      }
    }
    return tiers.first;
  }

  /// Next tier in sequence, or null if already at max tier.
  LeagueTier? get nextTier {
    final idx = tiers.indexWhere((t) => t.tierLevel == tierLevel);
    if (idx >= 0 && idx < tiers.length - 1) {
      return tiers[idx + 1];
    }
    return null;
  }

  /// Returns progression from 0.0 to 1.0 within this tier towards the next.
  double progress(int currentXp) {
    if (maxXp == null) return 1.0;
    final range = (maxXp! - minXp) + 1;
    final earned = (currentXp - minXp).clamp(0, range);
    return (earned / range).clamp(0.0, 1.0);
  }

  /// XP needed to advance to next tier.
  int xpNeededForNext(int currentXp) {
    final next = nextTier;
    if (next == null) return 0;
    return (next.minXp - currentXp).clamp(0, 999999);
  }
}
