import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.featherGreen,
        secondary: AppColors.skyBlue,
        surface: AppColors.surfaceLight,
        error: AppColors.targetPink,
        background: AppColors.backgroundLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: TextTheme(
        displayLarge: AppColors.textPrimaryLight.let((c) => AppTypography.displayBold.copyWith(color: c)),
        titleLarge: AppColors.textPrimaryLight.let((c) => AppTypography.titleSemiBold.copyWith(color: c)),
        bodyMedium: AppColors.textPrimaryLight.let((c) => AppTypography.bodyMedium.copyWith(color: c)),
        labelSmall: AppColors.textMutedLight.let((c) => AppTypography.subtextCaption.copyWith(color: c)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.featherGreen,
        secondary: AppColors.skyBlue,
        surface: AppColors.surfaceDark,
        error: AppColors.targetPink,
        background: AppColors.backgroundDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: TextTheme(
        displayLarge: AppColors.textPrimaryDark.let((c) => AppTypography.displayBold.copyWith(color: c)),
        titleLarge: AppColors.textPrimaryDark.let((c) => AppTypography.titleSemiBold.copyWith(color: c)),
        bodyMedium: AppColors.textPrimaryDark.let((c) => AppTypography.bodyMedium.copyWith(color: c)),
        labelSmall: AppColors.textMutedDark.let((c) => AppTypography.subtextCaption.copyWith(color: c)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
      ),
    );
  }
}

extension LetExtension<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
