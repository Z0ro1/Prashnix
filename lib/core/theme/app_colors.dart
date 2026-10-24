import 'package:flutter/material.dart';

/// Official App & Prashnix Design Colors.
class AppColors {
  AppColors._();

  // =====================================================
  // Official Prashnix Color Palette
  // =====================================================
  // Brand Greens
  static const Color green = Color(0xFF58CC02);
  static const Color greenShadow = Color(0xFF58A700);
  static const Color greenDarkBevel = Color(0xFF46A302);
  static const Color greenLight = Color(0xFFD7FFB8);
  static const Color greenPulse = Color(0x6658CC02);

  // Brand Yellows (Completed Nodes, Stars, Chests)
  static const Color yellow = Color(0xFFFFC800);
  static const Color yellowShadow = Color(0xFFE5A100);
  static const Color yellowLight = Color(0xFFFFF2B2);

  // Brand Blues (Gems, Diamonds)
  static const Color blue = Color(0xFF1CB0F6);
  static const Color blueShadow = Color(0xFF1899D6);
  static const Color blueLight = Color(0xFFDDF4FF);

  // Brand Reds (Hearts, Errors)
  static const Color red = Color(0xFFFF4B4B);
  static const Color redShadow = Color(0xFFEA2B2B);
  static const Color redLight = Color(0xFFFFDFE0);

  // Brand Oranges (Streaks, Flames)
  static const Color orange = Color(0xFFFF9600);
  static const Color orangeShadow = Color(0xFFE07A00);
  static const Color orangeLight = Color(0xFFFFE5BF);

  // Neutrals & Stepping Stones
  static const Color background = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E5E5);
  static const Color steppingDot = Color(0xFFD1D5DB);
  static const Color textPrimary = Color(0xFF4B4B4B);
  static const Color textSecondary = Color(0xFF777777);
  static const Color textMuted = Color(0xFFAFAFAF);
  static const Color cardShadowColor = Color(0x1A000000);

  // =====================================================
  // Primary Brand Colors (Aligned with Prashnix Palette)
  // =====================================================
  static const Color primaryGreen = green;
  static const Color primaryGreenDark = greenShadow;
  
  // Accents
  static const Color stepOrange = orange;
  static const Color waterBlue = blue;
  static const Color bpmRed = red;
  
  // Neutral & Background Colors - Light Mode
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDimLight = Color(0xFFF7F7F7); 
  
  // Text Colors
  static const Color textPrimaryLight = textPrimary;
  static const Color textMutedLight = textMuted;
  static const Color borderLight = border;

  // Neutral & Background Colors - Dark Mode
  static const Color backgroundDark = Color(0xFF131F24); // Prashnix dark navy
  static const Color surfaceDark = Color(0xFF1F2F38);    // Prashnix dark card surface
  static const Color surfaceDimDark = Color(0xFF283B46);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF8B9D9F);
  static const Color textMutedDark = Color(0xFF8B9D9F); 
  static const Color borderDark = Color(0xFF283B46);

  // Semantics
  static const Color success = green;
  static const Color error = red;
  static const Color warning = orange;

  // -----------------------------------------------------
  // Legacy mappings to prevent breaking compilation during refactor
  // -----------------------------------------------------
  static const Color featherGreen = green;
  static const Color featherGreenShadow = greenShadow;
  static const Color featherGreenContainer = greenLight;
  static const Color skyBlue = blue;
  static const Color skyBlueShadow = blueShadow;
  static const Color skyBlueContainer = blueLight;
  static const Color foxOrange = orange; 
  static const Color foxOrangeShadow = orangeShadow; 
  static const Color canaryYellow = yellow;
  static const Color canaryYellowShadow = yellowShadow;
  static const Color monsterPurple = Color(0xFFCE82FF);
  static const Color monsterPurpleShadow = Color(0xFFA568CC);
  static const Color targetPink = red;
  static const Color targetPinkShadow = redShadow;
  static const Color targetPinkContainer = redLight;

  static const Color primaryMint = green; 
  static const Color deepTealNavy = surfaceDark; 
  static const Color accentRed = red;
  static const Color accentAmber = orange;
  static const Color cardSurface = surfaceLight; 
  static const Color surfaceLighter = surfaceLight; 
  static const Color surface = surfaceLight;
  static const Color primary = green;

  static const Color textInverse = surfaceLight;
  
  // Soft Shadows
  static const List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> cardShadow = softCardShadow;
}
