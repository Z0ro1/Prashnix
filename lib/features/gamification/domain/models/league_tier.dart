import 'package:flutter/material.dart';

/// League tiers progression ladder based on Total XP.
/// Bronze (0-799), Silver (800-2499), Gold (2500-5999),
/// Platinum (6000-12499), Diamond (12500-24999), Champion (25000+).
class LeagueTier {
  final String name;
  final int minXp;
  final int? maxXp; // null for highest tier
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String description;
  final int tierLevel; // 1 to 6
  final String badgeAsset;

  const LeagueTier({
    required this.name,
    required this.minXp,
    required this.maxXp,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.description,
    required this.tierLevel,
    this.badgeAsset = 'assets/leagues/bronze.png',
  });

  static const List<LeagueTier> tiers = [
    LeagueTier(
      name: 'Bronze League',
      minXp: 0,
      maxXp: 799,
      primaryColor: Color(0xFFCD7F32),
      secondaryColor: Color(0xFF8D5524),
      icon: Icons.shield_rounded,
      description: 'Kickstart your streak & rise up!',
      tierLevel: 1,
      badgeAsset: 'assets/leagues/bronze.png',
    ),
    LeagueTier(
      name: 'Silver League',
      minXp: 800,
      maxXp: 2499,
      primaryColor: Color(0xFFCBD5E1),
      secondaryColor: Color(0xFF64748B),
      icon: Icons.shield_rounded,
      description: 'Consistent learner building daily momentum!',
      tierLevel: 2,
      badgeAsset: 'assets/leagues/silver.png',
    ),
    LeagueTier(
      name: 'Gold League',
      minXp: 2500,
      maxXp: 5999,
      primaryColor: Color(0xFFFFB800),
      secondaryColor: Color(0xFFD97706),
      icon: Icons.workspace_premium_rounded,
      description: 'Dedicated contender climbing district ranks!',
      tierLevel: 3,
      badgeAsset: 'assets/leagues/gold.png',
    ),
    LeagueTier(
      name: 'Platinum League',
      minXp: 6000,
      maxXp: 12499,
      primaryColor: Color(0xFF06B6D4),
      secondaryColor: Color(0xFF0891B2),
      icon: Icons.military_tech_rounded,
      description: 'Elite competitive aspirant mastering syllabus!',
      tierLevel: 4,
      badgeAsset: 'assets/leagues/platinum.png',
    ),
    LeagueTier(
      name: 'Diamond League',
      minXp: 12500,
      maxXp: 24999,
      primaryColor: Color(0xFFA855F7),
      secondaryColor: Color(0xFF7E22CE),
      icon: Icons.diamond_rounded,
      description: 'Top-tier master of Maharashtra exam tracks!',
      tierLevel: 5,
      badgeAsset: 'assets/leagues/diamond.png',
    ),
    LeagueTier(
      name: 'Champion League',
      minXp: 25000,
      maxXp: null,
      primaryColor: Color(0xFFFF3366),
      secondaryColor: Color(0xFFDC2626),
      icon: Icons.local_fire_department_rounded,
      description: 'Legendary Hall of Fame topper!',
      tierLevel: 6,
      badgeAsset: 'assets/leagues/champion.png',
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
