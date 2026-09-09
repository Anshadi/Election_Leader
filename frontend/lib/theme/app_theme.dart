import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Deep Minimalist Matte Slate Palette
  static const Color background = Color(0xFF090A0D);
  static const Color surface = Color(0xFF111318);
  static const Color surfaceElevated = Color(0xFF181B22);
  static const Color border = Color(0xFF222631);
  static const Color borderHover = Color(0xFF323846);

  // Text
  static const Color textPrimary = Color(0xFFEDEDED);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF4B5363);

  // Precision Accents (Single surgical accent, zero neon overload)
  static const Color accent = Color(0xFFFF5500); // International Safety Orange
  static const Color accentSubtle = Color(0x1FFF5500);
  static const Color blue = Color(0xFF388BFD);
  static const Color green = Color(0xFF2EA043);
  static const Color amber = Color(0xFFD29922);
  static const Color red = Color(0xFFF85149);

  // Bit Field Structural Colors (Muted architectural tones)
  static const Color bitSign = Color(0xFF4B5363);
  static const Color bitTimestamp = Color(0xFF388BFD);
  static const Color bitNode = Color(0xFFA371F7);
  static const Color bitSequence = Color(0xFF2EA043);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,
      dividerColor: AppColors.border,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.surface,
      ),
    );
  }
}
