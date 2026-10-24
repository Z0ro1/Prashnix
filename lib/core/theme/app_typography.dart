import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  // Official Duolingo Font Families extracted from APK
  static const String duolingoSans = 'DuolingoSans';
  static const String dinNext = 'DINNext';

  static TextStyle get displayHero => const TextStyle(
        fontFamily: duolingoSans,
        fontSize: 40,
        height: 48 / 40,
        fontWeight: FontWeight.w900,
      );

  static TextStyle get headlineLarge => const TextStyle(
        fontFamily: duolingoSans,
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w900,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: duolingoSans,
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: dinNext,
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: dinNext,
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: dinNext,
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: dinNext,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get labelLarge => const TextStyle(
        fontFamily: dinNext,
        fontSize: 16,
        height: 20 / 16,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontFamily: dinNext,
        fontSize: 14,
        height: 18 / 14,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: dinNext,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w700,
      );

  // Legacy aliases for backward compatibility
  static TextStyle get displayBold => displayHero;
  static TextStyle get titleSemiBold => headlineMedium;
  static TextStyle get subtextCaption => labelMedium;
  static TextStyle get button => labelLarge;
}
