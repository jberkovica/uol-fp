import 'package:flutter/material.dart';

/// Color constants for Mira Storyteller app - Flat Design Only
/// Based on your exact Figma UI design colors
class AppColors {
  // PRIMARY BRAND COLORS - New palette
  static const Color primary = Color(0xFFAB72FF); // Violet: #AB72FF - parent screens (brighter test color)
  static const Color secondary = Color(0xFFFFDD79); // Yellow: #FFDD79 - kids screens main yellow
  static const Color orange = Color(0xFFFFAC5B); // Orange: #FFAC5B
  static const Color pink = Color(0xFFFFB1BF); // Pink: #FFB1BF

  // SOFT VARIANTS for better hierarchy
  static const Color violetLight = Color(0xFFB584FF); // Lighter violet
  static const Color violetSoft = Color(0xFFE8D5FF); // Very light violet for subtle elements
  static const Color orangeLight = Color(0xFFFFCA8B); // Lighter orange
  static const Color pinkLight = Color(0xFFFFD1DC); // Lighter pink

  // BACKGROUND COLORS - solid, no gradients
  static const Color backgroundViolet = Color(0xFFA56AFF); // Parent background
  static const Color backgroundOrange = Color(0xFFFFAC5B); // Login background
  static const Color backgroundWhite = Colors.white; // White cards/containers

  // TEXT COLORS - improved contrast
  static const Color textDark = Color(0xFF1F1F1F); // Even darker text for better readability
  static const Color textLight = Colors.white; // White text on dark backgrounds
  static const Color textGrey = Color(0xFF4A4A4A); // Darker subtle grey text
  static const Color textViolet = Color(0xFFA56AFF); // Violet text accents

  // INTERACTIVE COLORS - flat only
  static const Color buttonPrimary = Color(0xFFA56AFF); // Violet buttons
  static const Color buttonSecondary = Color(0xFFFFDD79); // Yellow buttons
  static const Color buttonOrange = Color(0xFFFFAC5B); // Orange buttons
  static const Color buttonWhite = Colors.white; // White buttons
  static const Color buttonCancel = Color(0xFFF5F5F5); // Cancel buttons (light grey)

  // AVATAR/CHARACTER COLORS - for widget compatibility
  static const Color avatarViolet = Color(0xFFA56AFF);
  static const Color avatarBackground = Colors.white;
  static const Color characterViolet = Color(0xFFA56AFF); // For character_avatar.dart
  static const Color characterCloud = Color(0xFFE5E7EB); // For character_avatar.dart

  // STATUS COLORS - matching app theme (no green!)
  static const Color success = Color(0xFFAB72FF); // Use primary violet instead of green
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFB84D);

  // NEUTRAL COLORS - softer palette
  static const Color grey = Color(0xFFB8B8B8);
  static const Color mediumGrey = Color(0xFF7A7A7A); // Medium grey between textGrey and grey
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color white = Colors.white;
  static const Color black = Color(0xFF2D2D2D);
  
  /// Grey scale system (Material Design inspired)
  static const Color grey900 = Color(0xFF1F1F1F);     // Darkest grey
  static const Color grey800 = Color(0xFF2D2D2D);     // Very dark grey (same as black)
  static const Color grey700 = Color(0xFF4A4A4A);     // Dark grey (same as textGrey)
  static const Color grey600 = Color(0xFF7A7A7A);     // Medium-dark grey (same as mediumGrey)
  static const Color grey500 = Color(0xFF9CA3AF);     // Medium grey - perfect for icons
  static const Color grey400 = Color(0xFFB8B8B8);     // Medium-light grey (same as grey)
  static const Color grey300 = Color(0xFFD1D5DB);     // Light grey
  static const Color grey200 = Color(0xFFE5E7EB);     // Very light grey
  static const Color grey100 = Color(0xFFF5F5F5);     // Lightest grey (same as lightGrey)

  // CARD AND SURFACE COLORS
  static const Color cardBackground = Colors.white;
  static const Color surfaceLight = Color(0xFFF8FAFC);

  // TRANSPARENT - for removing shadows completely
  static const Color transparent = Colors.transparent;
  static const Color noShadow = Colors.transparent;
}
