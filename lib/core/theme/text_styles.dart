import 'package:flutter/material.dart';
import 'app_typography.dart';
import 'app_colors.dart';

/// Official Prashnix typography styling & App Text Styles
class AppTextStyles {
  AppTextStyles._();

  // Extracted Font Families
  static const String prashnixSans = 'PrashnixSans';
  static const String dinNext = 'DINNext';

  // -----------------------------------------------------
  // Official Prashnix Styles
  // -----------------------------------------------------
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

  // -----------------------------------------------------
  // Legacy & General App Typography Scale
  // -----------------------------------------------------
  static TextStyle get h1 => AppTypography.headlineLarge.copyWith(color: AppColors.textPrimary);
  static TextStyle get h2 => AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary);
  static TextStyle get h3 => AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary);
  
  static TextStyle get body => AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary);
  static TextStyle get bodySmall => AppTypography.bodySmall.copyWith(color: AppColors.textPrimary);
  
  static TextStyle get label => AppTypography.labelMedium.copyWith(color: AppColors.textPrimary);
  static TextStyle get caption => AppTypography.labelSmall.copyWith(color: AppColors.textSecondary);
  static TextStyle get button => AppTypography.labelLarge.copyWith(color: Colors.white, letterSpacing: 0.8);
  
  // Scales used in skill tree and across screens
  static TextStyle get labelSmall => AppTypography.labelSmall.copyWith(color: AppColors.textPrimary);
  static TextStyle get labelMedium => AppTypography.labelMedium.copyWith(color: AppColors.textPrimary);
  static TextStyle get labelLarge => AppTypography.labelLarge.copyWith(color: AppColors.textPrimary);
  static TextStyle get headlineSmall => AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary);
  static TextStyle get headlineMedium => AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary);
}
