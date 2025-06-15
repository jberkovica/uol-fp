import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Theme configuration for Mira Storyteller - COMPLETELY FLAT DESIGN with Manrope Font
class AppTheme {
  /// Get the main theme for the app - ZERO shadows, Manrope font, your exact colors
  static ThemeData get theme {
    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: GoogleFonts.manrope().fontFamily,
      textTheme: _textTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,

      // FORCE REMOVE ALL SHADOWS GLOBALLY
      shadowColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,

      // Material theme overrides to force flat design
      useMaterial3: true,
    );
  }

  // MANROPE TEXT HIERARCHY - Clean and readable
  static TextTheme get _textTheme {
    return TextTheme(
      // Large display text - for main titles
      displayLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        height: 1.2,
      ),
      // Medium display text - for section headers
      displayMedium: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.2,
      ),
      // Headlines
      headlineLarge: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.3,
      ),
      // Body text
      bodyLarge: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: AppColors.textDark,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textDark,
        height: 1.5,
      ),
      // Labels and buttons
      labelLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  // BUTTON THEME - COMPLETELY FLAT
  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textDark,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0, // ZERO elevation
        shadowColor: Colors.transparent, // NO shadow
        surfaceTintColor: Colors.transparent, // No Material 3 tint
        textStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: const Size(140, 56),
      ),
    );
  }

  // APP BAR THEME - FLAT
  static AppBarTheme get _appBarTheme {
    return AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0, // ZERO shadow
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent, // No Material 3 tint
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textLight,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textLight,
      ),
    );
  }

  // CARD THEME - COMPLETELY FLAT
  static CardTheme get _cardTheme {
    return CardTheme(
      elevation: 0, // ZERO shadow
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent, // No Material 3 tint
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(0), // Remove default margin
    );
  }

  // CONTAINER DECORATIONS - GUARANTEED FLAT
  static BoxDecoration get flatCardDecoration {
    return const BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.all(Radius.circular(16)),
      // Explicitly NO shadows, NO border, completely flat
    );
  }

  static BoxDecoration flatContainer({required Color color}) {
    return BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      // Explicitly NO shadows, NO border, completely flat
    );
  }

  // BUTTON STYLES - INDIVIDUAL VARIANTS
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        textStyle:
            GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w600),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textDark,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        textStyle:
            GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w600),
      );

  static ButtonStyle get whiteButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        textStyle:
            GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w600),
      );

  // Light theme configuration - COMPLETELY FLAT
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.white,
    fontFamily: GoogleFonts.manrope().fontFamily,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.white,
      brightness: Brightness.light,
    ),
    textTheme: _textTheme,
    appBarTheme: _appBarTheme,
    elevatedButtonTheme: _elevatedButtonTheme,
    cardTheme: _cardTheme,

    // FORCE REMOVE ALL SHADOWS AND EFFECTS
    shadowColor: Colors.transparent,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,

    // Material 3 overrides
    useMaterial3: true,
  );
}
