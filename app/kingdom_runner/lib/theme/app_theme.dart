import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Light Theme Colors
  static const Color background = Color(0xFFffffff);
  static const Color foreground = Color(0xFF1e4002);
  static const Color card = Color(0xFFffffff);
  static const Color cardForeground = Color(0xFF0c1f00);
  static const Color popover = Color(0xFFffffff);
  static const Color popoverForeground = Color(0xFF312e81);
  static const Color primary = Color(0xFF96cc00);
  static const Color primaryForeground = Color(0xFFffffff);
  static const Color secondary = Color(0xFFf4ffe0);
  static const Color secondaryForeground = Color(0xFF78a300);
  static const Color muted = Color(0xFFf5f3ff);
  static const Color mutedForeground = Color(0xFF1f3f0e);
  static const Color accent = Color(0xFFdbeafe);
  static const Color accentForeground = Color(0xFF113b02);
  static const Color destructive = Color(0xFFef4444);
  static const Color destructiveForeground = Color(0xFFffffff);
  static const Color border = Color(0xFFe0e7ff);
  static const Color input = Color(0xFFe0e7ff);
  static const Color ring = Color(0xFF1f7500);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0f172a);
  static const Color darkForeground = Color(0xFFe0e7ff);
  static const Color darkCard = Color(0xFF1e1b4b);
  static const Color darkCardForeground = Color(0xFFe0e7ff);
  static const Color darkPopover = Color(0xFF1e1b4b);
  static const Color darkPopoverForeground = Color(0xFFe0e7ff);
  static const Color darkPrimary = Color(0xFF8b5cf6);
  static const Color darkPrimaryForeground = Color(0xFFffffff);
  static const Color darkSecondary = Color(0xFF1e1b4b);
  static const Color darkSecondaryForeground = Color(0xFFe0e7ff);
  static const Color darkMuted = Color(0xFF171447);
  static const Color darkMutedForeground = Color(0xFFc4b5fd);
  static const Color darkAccent = Color(0xFF4338ca);
  static const Color darkAccentForeground = Color(0xFFe0e7ff);
  static const Color darkDestructive = Color(0xFFef4444);
  static const Color darkDestructiveForeground = Color(0xFFffffff);
  static const Color darkBorder = Color(0xFF2e1065);
  static const Color darkInput = Color(0xFF2e1065);
  static const Color darkRing = Color(0xFF8b5cf6);
}

class AppTheme {
  static TextTheme _buildTextTheme(TextTheme base, Color baseColor, Color mutedColor) {
    return GoogleFonts.lexendTextTheme(base).copyWith(
      displayLarge: GoogleFonts.playfairDisplay(textStyle: base.displayLarge?.copyWith(letterSpacing: 0, color: baseColor)),
      displayMedium: GoogleFonts.playfairDisplay(textStyle: base.displayMedium?.copyWith(letterSpacing: 0, color: baseColor)),
      displaySmall: GoogleFonts.playfairDisplay(textStyle: base.displaySmall?.copyWith(letterSpacing: 0, color: baseColor)),
      headlineLarge: GoogleFonts.playfairDisplay(textStyle: base.headlineLarge?.copyWith(letterSpacing: 0, color: baseColor)),
      headlineMedium: GoogleFonts.playfairDisplay(textStyle: base.headlineMedium?.copyWith(letterSpacing: 0, color: baseColor)),
      headlineSmall: GoogleFonts.playfairDisplay(textStyle: base.headlineSmall?.copyWith(letterSpacing: 0, color: baseColor)),
      titleLarge: GoogleFonts.lexend(textStyle: base.titleLarge?.copyWith(letterSpacing: 0, color: baseColor)),
      titleMedium: GoogleFonts.lexend(textStyle: base.titleMedium?.copyWith(letterSpacing: 0, color: baseColor)),
      titleSmall: GoogleFonts.lexend(textStyle: base.titleSmall?.copyWith(letterSpacing: 0, color: baseColor)),
      bodyLarge: GoogleFonts.lexend(textStyle: base.bodyLarge?.copyWith(letterSpacing: 0, color: baseColor)),
      bodyMedium: GoogleFonts.lexend(textStyle: base.bodyMedium?.copyWith(letterSpacing: 0, color: mutedColor)),
      bodySmall: GoogleFonts.lexend(textStyle: base.bodySmall?.copyWith(letterSpacing: 0, color: mutedColor)),
      labelLarge: GoogleFonts.firaCode(textStyle: base.labelLarge?.copyWith(letterSpacing: 0, color: baseColor)),
      labelMedium: GoogleFonts.firaCode(textStyle: base.labelMedium?.copyWith(letterSpacing: 0, color: baseColor)),
      labelSmall: GoogleFonts.firaCode(textStyle: base.labelSmall?.copyWith(letterSpacing: 0, color: mutedColor)),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        onSecondary: AppColors.secondaryForeground,
        surface: AppColors.card,
        onSurface: AppColors.foreground,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
      ),
      fontFamily: GoogleFonts.lexend().fontFamily,
      textTheme: _buildTextTheme(ThemeData.light().textTheme, AppColors.foreground, AppColors.mutedForeground),
      dividerColor: AppColors.border,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.input),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.ring, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
        prefixIconColor: AppColors.mutedForeground,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkPrimaryForeground,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkSecondaryForeground,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkForeground,
        error: AppColors.darkDestructive,
        onError: AppColors.darkDestructiveForeground,
      ),
      fontFamily: GoogleFonts.lexend().fontFamily,
      textTheme: _buildTextTheme(ThemeData.dark().textTheme, AppColors.darkForeground, AppColors.darkMutedForeground),
      dividerColor: AppColors.darkBorder,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkPrimaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkInput),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkRing, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.darkMutedForeground, fontSize: 14),
        prefixIconColor: AppColors.darkMutedForeground,
      ),
    );
  }
}
