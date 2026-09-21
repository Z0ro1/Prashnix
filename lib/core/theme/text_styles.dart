import 'package:flutter/material.dart';
import 'app_typography.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get h1 => AppTypography.displayBold.copyWith(color: AppColors.textPrimary);
  static TextStyle get h2 => AppTypography.titleSemiBold.copyWith(color: AppColors.textPrimary);
  static TextStyle get h3 => AppTypography.titleSemiBold.copyWith(color: AppColors.textPrimary);
  
  static TextStyle get body => AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary);
  static TextStyle get bodySmall => AppTypography.subtextCaption.copyWith(color: AppColors.textPrimary);
  
  static TextStyle get label => AppTypography.subtextCaption.copyWith(color: AppColors.textPrimary);
  static TextStyle get button => AppTypography.titleSemiBold.copyWith(color: Colors.white);
}
