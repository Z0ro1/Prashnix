import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static final String _fontFamily = GoogleFonts.nunito().fontFamily!;

  static TextStyle get displayBold => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get titleSemiBold => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get subtextCaption => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        height: 16 / 13,
        fontWeight: FontWeight.w600,
      );
      
  static TextStyle get button => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w800,
      );
}
