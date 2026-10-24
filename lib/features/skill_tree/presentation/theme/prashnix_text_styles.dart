import 'package:flutter/material.dart';
import 'prashnix_colors.dart';

/// Prashnix typography styling.
class PrashnixTextStyles {
  // Font Families
  static const String prashnixSans = 'PrashnixSans';
  static const String dinNext = 'DINNext';

  // Headings
  static const TextStyle unitTitle = TextStyle(
    fontFamily: prashnixSans,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: -0.2,
    height: 1.2,
  );

  static const TextStyle unitSubtext = TextStyle(
    fontFamily: prashnixSans,
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
    color: PrashnixColors.orange,
  );

  static const TextStyle statGems = TextStyle(
    fontFamily: dinNext,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: PrashnixColors.blue,
  );

  static const TextStyle statHearts = TextStyle(
    fontFamily: dinNext,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: PrashnixColors.red,
  );

  // Path Tooltip
  static const TextStyle pathTooltip = TextStyle(
    fontFamily: dinNext,
    fontSize: 15,
    fontWeight: FontWeight.w900,
    color: PrashnixColors.green,
    letterSpacing: 0.5,
  );

  // Bottom Navigation
  static const TextStyle navItemActive = TextStyle(
    fontFamily: dinNext,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    color: PrashnixColors.green,
    letterSpacing: 0.8,
  );

  static const TextStyle navItemInactive = TextStyle(
    fontFamily: dinNext,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    color: PrashnixColors.textMuted,
    letterSpacing: 0.8,
  );
}
