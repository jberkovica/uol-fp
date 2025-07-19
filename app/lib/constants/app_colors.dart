import 'package:flutter/material.dart';

/// Color constants for Mira Storyteller app - Flat Design Only
/// Based on your exact Figma UI design colors
class AppColors {
  // PRIMARY BRAND COLORS - EXACT MATCH to your Figma
  static const Color primary = Color(0xFF9F60FF); // Your purple: #9F60FF
  static const Color secondary = Color(0xFFFFDC7B); // Your yellow: #FFDC7B

  // SOFT VARIANTS for better hierarchy
  static const Color purpleLight = Color(0xFFB584FF); // Lighter purple
  static const Color purpleSoft =
      Color(0xFFE8D5FF); // Very light purple for subtle elements
  static const Color yellowLight = Color(0xFFFEE49A); // Lighter yellow
  static const Color yellowSoft =
      Color(0xFFFFF9E6); // Very light yellow for backgrounds

  // BACKGROUND COLORS - solid, no gradients
  static const Color backgroundYellow =
      Color(0xFFFFDC7B); // Main yellow background
  static const Color backgroundPurple = Color(0xFF9F60FF); // Purple sections
  static const Color backgroundWhite = Colors.white; // White cards/containers

  // TEXT COLORS - improved contrast
  static const Color textDark = Color(0xFF2D2D2D); // Softer dark text
  static const Color textLight = Colors.white; // White text on dark backgrounds
  static const Color textGrey = Color(0xFF8E8E8E); // Subtle grey text
  static const Color textPurple = Color(0xFF9F60FF); // Purple text accents

  // INTERACTIVE COLORS - flat only
  static const Color buttonPrimary = Color(0xFF9F60FF); // Purple buttons
  static const Color buttonSecondary = Color(0xFFFFDC7B); // Yellow buttons
  static const Color buttonWhite = Colors.white; // White buttons

  // AVATAR/CHARACTER COLORS - for widget compatibility
  static const Color avatarPurple = Color(0xFF9F60FF);
  static const Color avatarBackground = Colors.white;
  static const Color characterPurple =
      Color(0xFF9F60FF); // For character_avatar.dart
  static const Color characterCloud =
      Color(0xFFE5E7EB); // For character_avatar.dart

  // STATUS COLORS - softer versions
  static const Color success = Color(0xFF4AE54A);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFB84D);

  // NEUTRAL COLORS - softer palette
  static const Color grey = Color(0xFFB8B8B8);
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
