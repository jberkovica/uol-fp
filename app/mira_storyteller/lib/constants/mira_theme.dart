import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Comprehensive theme system for Mira Storyteller
/// - Uses Manrope font throughout
/// - Flat design only - NO gradients, NO shadows
/// - Consistent styling across all components
class MiraTheme {
  // COLORS - Based on UI design
  static const Color purple = Color(0xFF8B5CF6);
  static const Color yellow = Color(0xFFFBBF24);
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Colors.white;
  static const Color grey = Color(0xFF9CA3AF);
  static const Color lightGrey = Color(0xFFF3F4F6);

  // FONT SYSTEM - Manrope throughout
  static TextStyle get _baseTextStyle => GoogleFonts.manrope();

  // TEXT STYLES - All using Manrope
  static TextStyle get displayLarge => _baseTextStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textDark,
        height: 1.2,
      );

  static TextStyle get displayMedium => _baseTextStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textDark,
        height: 1.2,
      );

  static TextStyle get headlineLarge => _baseTextStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textDark,
        height: 1.3,
      );

  static TextStyle get headlineMedium => _baseTextStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
        height: 1.3,
      );

  static TextStyle get bodyLarge => _baseTextStyle.copyWith(
        fontSize: 18,
        color: textDark,
        height: 1.4,
      );

  static TextStyle get bodyMedium => _baseTextStyle.copyWith(
        fontSize: 16,
        color: textDark,
        height: 1.4,
      );

  static TextStyle get buttonText => _baseTextStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      );

  // DECORATION SYSTEM - Flat design only
  static BoxDecoration get flatWhiteCard => const BoxDecoration(
        color: white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        // NO shadows, NO elevation
      );

  static BoxDecoration get flatPurpleContainer => const BoxDecoration(
        color: purple,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        // NO shadows, NO elevation
      );

  static BoxDecoration get flatYellowContainer => const BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        // NO shadows, NO elevation
      );

  // BUTTON STYLES - Flat design
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: purple,
        foregroundColor: textLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0, // NO elevation
        shadowColor: Colors.transparent, // NO shadow
        textStyle: buttonText.copyWith(color: textLight),
        minimumSize: const Size(120, 56),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: yellow,
        foregroundColor: textDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0, // NO elevation
        shadowColor: Colors.transparent, // NO shadow
        textStyle: buttonText,
        minimumSize: const Size(120, 56),
      );

  static ButtonStyle get whiteButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: white,
        foregroundColor: textDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0, // NO elevation
        shadowColor: Colors.transparent, // NO shadow
        textStyle: buttonText,
        minimumSize: const Size(120, 56),
      );

  // MAIN THEME DATA
  static ThemeData get theme {
    return ThemeData(
      primaryColor: purple,
      scaffoldBackgroundColor: white,
      fontFamily: GoogleFonts.manrope().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        primary: purple,
        secondary: yellow,
        surface: white,
        brightness: Brightness.light,
      ),

      // TEXT THEME
      textTheme: TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
      ),

      // BUTTON THEMES
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),

      // CARD THEME - NO shadows
      cardTheme: CardTheme(
        elevation: 0, // NO shadow
        shadowColor: Colors.transparent,
        color: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(8),
      ),

      // APP BAR THEME - Flat
      appBarTheme: AppBarTheme(
        backgroundColor: purple,
        elevation: 0, // NO shadow
        shadowColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: headlineMedium.copyWith(color: textLight),
        iconTheme: const IconThemeData(color: textLight),
      ),

      // REMOVE ALL SHADOWS GLOBALLY
      shadowColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  // CONTAINER HELPERS
  static Widget flatContainer({
    required Widget child,
    required Color color,
    EdgeInsets? padding,
    double borderRadius = 16,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        // NO shadows
      ),
      child: child,
    );
  }

  // BUTTON HELPERS
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: primaryButtonStyle,
        child: Text(text),
      ),
    );
  }

  static Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: secondaryButtonStyle,
        child: Text(text),
      ),
    );
  }

  static Widget whiteButton({
    required String text,
    required VoidCallback onPressed,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: whiteButtonStyle,
        child: Text(text),
      ),
    );
  }

  // SCREEN BACKGROUND HELPERS
  static Color getScreenBackground(String screenType) {
    switch (screenType) {
      case 'yellow':
        return yellow;
      case 'purple':
        return purple;
      case 'white':
      default:
        return white;
    }
  }

  // AVATAR CONTAINER
  static Widget avatarContainer({
    required Widget child,
    double size = 80,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: white,
        shape: BoxShape.circle,
        // NO shadows
      ),
      child: child,
    );
  }
}
