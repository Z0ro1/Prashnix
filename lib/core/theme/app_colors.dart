import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Brand Colors
  static const Color featherGreen = Color(0xFF58CC02);
  static const Color featherGreenShadow = Color(0xFF46A302);
  
  static const Color skyBlue = Color(0xFF1CB0F6);
  static const Color skyBlueShadow = Color(0xFF1899D6);
  
  static const Color foxOrange = Color(0xFFFF9600);
  static const Color foxOrangeShadow = Color(0xFFCE7A00);
  
  static const Color canaryYellow = Color(0xFFFFC800);
  static const Color canaryYellowShadow = Color(0xFFCFA300);
  
  static const Color monsterPurple = Color(0xFFCE82FF);
  static const Color monsterPurpleShadow = Color(0xFFA568CC);
  
  static const Color targetPink = Color(0xFFFF4B4B);
  static const Color targetPinkShadow = Color(0xFFEA2B2B);

  // Neutral & Background Colors - Light Mode
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7F7F7);
  static const Color textPrimaryLight = Color(0xFF4B4B4B);
  static const Color textMutedLight = Color(0xFFAFAFAF);
  static const Color borderLight = Color(0xFFE5E5E5);

  // Neutral & Background Colors - Dark Mode
  static const Color backgroundDark = Color(0xFF131F24);
  static const Color surfaceDark = Color(0xFF202F36);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textMutedDark = Color(0xFF52656D);
  static const Color borderDark = Color(0xFF37464F);

  // Semantics
  static const Color success = featherGreen;
  static const Color error = targetPink;
  static const Color warning = canaryYellow;

  // Aliases for legacy compatibility
  static const Color primaryMint = featherGreen; 
  static const Color deepTealNavy = surfaceDark; 
  static const Color accentRed = targetPink;
  static const Color accentAmber = foxOrange;
  static const Color cardSurface = backgroundLight; 
  static const Color surfaceLighter = backgroundLight; // Added alias
  static const Color background = backgroundLight;
  static const Color primary = featherGreen;

  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textMutedLight;
  static const Color textInverse = backgroundLight;
  static const Color border = borderLight;
  
  // Shadows (Legacy)
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0F0F2232), // rgba(15, 34, 50, 0.06)
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
