import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MIRA STORYTELLER COMPREHENSIVE DESIGN SYSTEM
/// ═══════════════════════════════════════════════════════════════════════════
///
/// ONE SINGLE SOURCE OF TRUTH for all styling in the app
///
/// DESIGN PRINCIPLES:
/// 1. FLAT DESIGN ONLY - NO shadows, gradients, elevation
/// 2. MANROPE FONT throughout
/// 3. EXACT BRAND COLORS: Purple #9F60FF, Yellow #FFD560
/// 4. 8px grid spacing system
/// 5. CHILD-FRIENDLY, clean interface
/// 6. CONSISTENT across all screens
///
/// USAGE:
/// - Apply AppTheme.theme to MaterialApp
/// - Use AppTheme utilities for custom components
/// - Follow spacing constants for consistency
///
class AppTheme {
  /// ═══════════════════════════════════════════════════════════════════════════
  /// CORE THEME DATA - Apply this to MaterialApp
  /// ═══════════════════════════════════════════════════════════════════════════

  static ThemeData get theme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: GoogleFonts.manrope().fontFamily,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.white,
        brightness: Brightness.light,
      ),

      // TYPOGRAPHY SYSTEM
      textTheme: _textTheme,

      // COMPONENT THEMES
      elevatedButtonTheme: _elevatedButtonTheme,
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      inputDecorationTheme: _inputDecorationTheme,

      // FORCE COMPLETELY FLAT DESIGN
      shadowColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      useMaterial3: true,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// TYPOGRAPHY SYSTEM - All Manrope
  /// ═══════════════════════════════════════════════════════════════════════════

  static TextTheme get _textTheme {
    return TextTheme(
      // DISPLAY TEXT - For main titles
      displayLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.2,
      ),

      // HEADLINES - For section headers
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

      // BODY TEXT - For paragraphs
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

      // LABELS - For buttons and small text
      labelLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// BUTTON THEME SYSTEM
  /// ═══════════════════════════════════════════════════════════════════════════

  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textDark,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0, // ZERO elevation
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        textStyle:
            GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w600),
        minimumSize: const Size(140, 56),
      ),
    );
  }

  // INDIVIDUAL BUTTON STYLES
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
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

  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
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

  static ButtonStyle get whiteButton => ElevatedButton.styleFrom(
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

  /// ═══════════════════════════════════════════════════════════════════════════
  /// COMPONENT THEMES
  /// ═══════════════════════════════════════════════════════════════════════════

  static AppBarTheme get _appBarTheme {
    return AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0, // ZERO shadow
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textLight,
      ),
      iconTheme: const IconThemeData(color: AppColors.textLight),
    );
  }

  static CardTheme get _cardTheme {
    return CardTheme(
      elevation: 0, // ZERO shadow
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(0),
    );
  }

  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      labelStyle: GoogleFonts.manrope(
        color: AppColors.textGrey,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.lightGrey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.lightGrey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// SPACING SYSTEM (8px grid)
  /// ═══════════════════════════════════════════════════════════════════════════

  static const double spacingXS = 4.0; // 0.5 units
  static const double spacingS = 8.0; // 1 unit
  static const double spacingM = 16.0; // 2 units
  static const double spacingL = 24.0; // 3 units
  static const double spacingXL = 32.0; // 4 units
  static const double spacingXXL = 40.0; // 5 units
  static const double spacingHuge = 48.0; // 6 units

  /// LAYOUT CONSTANTS
  static const EdgeInsets screenPadding = EdgeInsets.all(24.0);
  static const EdgeInsets screenPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(32.0);
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 32, vertical: 16);

  /// ═══════════════════════════════════════════════════════════════════════════
  /// BORDER RADIUS SYSTEM
  /// ═══════════════════════════════════════════════════════════════════════════

  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;

  /// ═══════════════════════════════════════════════════════════════════════════
  /// SIZING CONSTANTS
  /// ═══════════════════════════════════════════════════════════════════════════

  // AVATARS
  static const double avatarSmall = 40.0;
  static const double avatarMedium = 60.0;
  static const double avatarLarge = 80.0;
  static const double avatarXLarge = 120.0;

  // ICONS
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // MASCOT/ILLUSTRATIONS
  static const double mascotMedium = 140.0;
  static const double mascotLarge = 160.0;
  static const double mascotXLarge = 200.0;

  /// ═══════════════════════════════════════════════════════════════════════════
  /// ANIMATION CONSTANTS
  /// ═══════════════════════════════════════════════════════════════════════════

  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  /// ═══════════════════════════════════════════════════════════════════════════
  /// CONTAINER DECORATIONS - GUARANTEED FLAT
  /// ═══════════════════════════════════════════════════════════════════════════

  static BoxDecoration get flatWhiteCard => const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        // NO shadows, NO elevation
      );

  static BoxDecoration get flatPurpleContainer => const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      );

  static BoxDecoration get flatYellowContainer => const BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      );

  /// Create custom flat containers
  static BoxDecoration flatContainer({
    required Color color,
    double? radius,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius ?? radiusM),
      border: border,
      // NO shadows - completely flat
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// UTILITY WIDGETS
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Create a flat container widget
  static Widget flatBox({
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

  /// Create flat Material widget (when Card theme isn't suitable)
  static Widget flatMaterial({
    required Widget child,
    Color? color,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return Material(
      color: color ?? AppColors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(radiusM),
      elevation: 0, // NO shadows
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: padding != null ? Padding(padding: padding, child: child) : child,
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// FLAT DESIGN ENFORCEMENT UTILITIES
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Ensure any BoxDecoration is completely flat
  static BoxDecoration enforceFlat(BoxDecoration decoration) {
    return decoration.copyWith(boxShadow: null);
  }

  /// Ensure any ButtonStyle has no elevation
  static ButtonStyle enforceButtonFlat(ButtonStyle style) {
    return style.copyWith(
      elevation: WidgetStateProperty.all(0),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// DESIGN GUIDELINES FOR DEVELOPERS
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// USAGE INSTRUCTIONS:
/// 
/// 1. GLOBAL THEMING:
///    - Apply AppTheme.theme to MaterialApp
///    - Most Flutter widgets will inherit correct styles automatically
/// 
/// 2. CUSTOM STYLING:
///    - Use AppTheme utilities when you need specific control
///    - Use spacing constants: AppTheme.spacingM, etc.
///    - Use button styles: AppTheme.primaryButton, etc.
///    - Use container decorations: AppTheme.flatWhiteCard, etc.
/// 
/// 3. SPACING:
///    - Follow 8px grid: use spacingS (8), spacingM (16), spacingL (24), etc.
///    - Use screenPadding for consistent screen margins
/// 
/// 4. COLORS:
///    - Import app_colors.dart and use AppColors.primary, AppColors.secondary
///    - Never hardcode colors
/// 
/// 5. FLAT DESIGN ENFORCEMENT:
///    - If you ever see shadows/elevation, use enforceFlat() utilities
///    - All components should be completely flat
/// 
/// 6. CONSISTENCY:
///    - Use radiusM (16) for most rounded corners
///    - Use buttonPadding for button spacing
///    - Use cardPadding for card content
/// 
/// ═══════════════════════════════════════════════════════════════════════════
