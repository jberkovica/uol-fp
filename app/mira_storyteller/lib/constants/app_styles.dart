import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// MIRA STORYTELLER DESIGN SYSTEM - UTILITIES & GUIDELINES
///
/// PURPOSE: Provides utilities, constants, and design guidelines
/// NOTE: For global theming, use AppTheme.theme in MaterialApp
///
/// DESIGN PRINCIPLES:
/// 1. FLAT DESIGN ONLY - NO shadows, gradients, elevation
/// 2. CONSISTENT SPACING using 8px grid system
/// 3. MANROPE FONT throughout (handled by AppTheme)
/// 4. EXACT BRAND COLORS: Purple #9F60FF, Yellow #FFD560
/// 5. CLEAN, MINIMAL, CHILD-FRIENDLY interface
///
class AppStyles {
  /// ========================================
  /// SPACING SYSTEM (8px grid)
  /// ========================================

  static const double spacingXS = 4.0; // 0.5 units
  static const double spacingS = 8.0; // 1 unit
  static const double spacingM = 16.0; // 2 units
  static const double spacingL = 24.0; // 3 units
  static const double spacingXL = 32.0; // 4 units
  static const double spacingXXL = 40.0; // 5 units
  static const double spacingHuge = 48.0; // 6 units

  /// ========================================
  /// BORDER RADIUS SYSTEM
  /// ========================================

  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;

  /// ========================================
  /// LAYOUT CONSTANTS
  /// ========================================

  static const EdgeInsets screenPadding = EdgeInsets.all(24.0);
  static const EdgeInsets screenPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(32.0);
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 32, vertical: 16);

  /// ========================================
  /// ANIMATION CONSTANTS
  /// ========================================

  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  /// ========================================
  /// CUSTOM INPUT DECORATION (when theme isn't enough)
  /// ========================================

  static InputDecoration customInputDecoration({
    required String label,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
    Color? borderColor,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(
          color: AppColors.textGrey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide:
              BorderSide(color: borderColor ?? AppColors.lightGrey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide:
              BorderSide(color: borderColor ?? AppColors.lightGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textGrey, size: 20)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor ?? AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  /// ========================================
  /// FLAT DESIGN ENFORCEMENT UTILITIES
  /// ========================================

  /// Use this to ensure any BoxDecoration is completely flat
  static BoxDecoration enforceFlat(BoxDecoration decoration) {
    return decoration.copyWith(
      boxShadow: null, // Remove any shadows
    );
  }

  /// Use this to ensure any ButtonStyle has no elevation
  static ButtonStyle enforceButtonFlat(ButtonStyle style) {
    return style.copyWith(
      elevation: WidgetStateProperty.all(0),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
    );
  }

  /// Use this to create a flat Material widget (when Card theme isn't suitable)
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

  /// Create custom flat containers when needed
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

  /// ========================================
  /// AVATAR SIZING CONSTANTS
  /// ========================================

  static const double avatarSmall = 40.0;
  static const double avatarMedium = 60.0;
  static const double avatarLarge = 80.0;
  static const double avatarXLarge = 120.0;

  /// ========================================
  /// ICON SIZING CONSTANTS
  /// ========================================

  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  /// ========================================
  /// MASCOT SIZING CONSTANTS
  /// ========================================

  static const double mascotMedium = 140.0; // For child home screen
  static const double mascotLarge = 160.0; // For processing screen
  static const double mascotXLarge = 200.0; // For special screens
}

/// ========================================
/// DESIGN GUIDELINES FOR DEVELOPERS
/// ========================================
/// 
/// USAGE INSTRUCTIONS:
/// 
/// 1. GLOBAL THEMING:
///    Use AppTheme.theme in MaterialApp for automatic styling
///    Most Flutter widgets will inherit correct styles
/// 
/// 2. CUSTOM STYLING:
///    Use AppStyles utilities when you need specific control
///    Only when the global theme isn't sufficient
/// 
/// 3. SPACING:
///    Always use AppStyles.spacing* constants
///    Follow the 8px grid system
/// 
/// 4. COLORS:
///    Always use AppColors - never hardcode colors
///    Stick to the established brand palette
/// 
/// MANDATORY RULES:
/// 1. NEVER use BoxShadow, elevation, or gradients
/// 2. ALWAYS use AppColors for consistency
/// 3. ALWAYS use the global theme first, custom styles second
/// 4. ALWAYS use AppStyles spacing constants
/// 5. ALWAYS test on multiple screen sizes
/// 
/// WHEN TO USE WHAT:
/// - Flutter widgets (Button, Card, Text): Rely on AppTheme
/// - Custom containers: Use AppStyles.flatContainer()
/// - Custom spacing: Use AppStyles.spacing* constants
/// - Special inputs: Use AppStyles.customInputDecoration()
/// - Enforcement: Use AppStyles.enforceFlat() utilities
///
