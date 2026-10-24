import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Official Duolingo typography styling extracted from the APK.
class AppTextStyles {
  // Extracted Font Families
  static const String duolingoSans = 'DuolingoSans';
  static const String dinNext = 'DINNext';

  // Headings
  static const TextStyle unitTitle = TextStyle(
    fontFamily: duolingoSans,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: -0.2,
    height: 1.2,
  );

  static const TextStyle unitSubtext = TextStyle(
    fontFamily: duolingoSans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.35,
  );

  static const TextStyle unitTag = TextStyle(
    fontFamily: dinNext,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    color: Color(0xCCFFFFFF),
    letterSpacing: 1.2,
  );

  // Stats Bar Text
  static const TextStyle statStreak = TextStyle(
    fontFamily: dinNext,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: AppColors.orange,
  );

  static const TextStyle statGems = TextStyle(
    fontFamily: dinNext,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: AppColors.blue,
  );

  static const TextStyle statHearts = TextStyle(
    fontFamily: dinNext,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: AppColors.red,
  );

  // Path Tooltip
  static const TextStyle pathTooltip = TextStyle(
    fontFamily: dinNext,
    fontSize: 15,
    fontWeight: FontWeight.w900,
    color: AppColors.green,
    letterSpacing: 0.5,
  );

  // Bottom Navigation
  static const TextStyle navItemActive = TextStyle(
    fontFamily: dinNext,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    color: AppColors.green,
    letterSpacing: 0.8,
  );

  static const TextStyle navItemInactive = TextStyle(
    fontFamily: dinNext,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
  );
}
