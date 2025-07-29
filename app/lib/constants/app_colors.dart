import 'package:flutter/material.dart';

/// Color constants for Mira Storyteller app - Flat Design Only
/// Based on your exact Figma UI design colors
class AppColors {
  // PRIMARY BRAND COLORS - New palette
  static const Color primary = Color(0xFFAB72FF); // Violet: #AB72FF - parent screens (brighter test color)
  static const Color secondary = Color(0xFFFFDB70); // Yellow: #FFDB70 - kids screens (warmer test color)
  static const Color orange = Color(0xFFFFAC5B); // Orange: #FFAC5B
  static const Color pink = Color(0xFFFFB1BF); // Pink: #FFB1BF

  // SOFT VARIANTS for better hierarchy
  static const Color violetLight = Color(0xFFB584FF); // Lighter violet
  static const Color violetSoft = Color(0xFFE8D5FF); // Very light violet for subtle elements
  static const Color yellowLight = Color(0xFFFEE49A); // Lighter yellow
  static const Color yellowSoft = Color(0xFFFFF9E6); // Very light yellow for backgrounds
  static const Color orangeLight = Color(0xFFFFCA8B); // Lighter orange
  static const Color pinkLight = Color(0xFFFFD1DC); // Lighter pink

  // BACKGROUND COLORS - solid, no gradients
  static const Color backgroundYellow = Color(0xFFFFDC7B); // Kids background
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
  static const Color buttonSecondary = Color(0xFFFFDC7B); // Yellow buttons
  static const Color buttonOrange = Color(0xFFFFAC5B); // Orange buttons
  static const Color buttonWhite = Colors.white; // White buttons
  static const Color buttonCancel = Color(0xFFF5F5F5); // Cancel buttons (light grey)
  static const Color buttonYellow = Color(0xFFFFDC7B); // Alternative yellow buttons

  // AVATAR/CHARACTER COLORS - for widget compatibility
  static const Color avatarViolet = Color(0xFFA56AFF);
  static const Color avatarBackground = Colors.white;
  static const Color characterViolet = Color(0xFFA56AFF); // For character_avatar.dart
  static const Color characterCloud = Color(0xFFE5E7EB); // For character_avatar.dart

  // STATUS COLORS - softer versions
  static const Color success = Color(0xFF4AE54A);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFB84D);

  // NEUTRAL COLORS - softer palette
  static const Color grey = Color(0xFFB8B8B8);
  static const Color mediumGrey = Color(0xFF7A7A7A); // Medium grey between textGrey and grey
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color white = Colors.white;
  static const Color black = Color(0xFF2D2D2D);

  // CARD AND SURFACE COLORS
  static const Color cardBackground = Colors.white;
  static const Color surfaceLight = Color(0xFFF8FAFC);

  // TRANSPARENT - for removing shadows completely
  static const Color transparent = Colors.transparent;
  static const Color noShadow = Colors.transparent;
}
