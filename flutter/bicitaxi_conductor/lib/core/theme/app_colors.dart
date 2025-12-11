import 'package:flutter/material.dart';

/// Bici Taxi Conductor color palette.
/// Light theme with blue accents.
/// Accent blues: Electric blue (#4BB3FD), Steel blue (#3E6680),
/// Bright blue (#0496FF), Deep blue (#027BCE)
abstract final class AppColors {
  // Primary color (kept for reference/accents)
  static const Color primary = Color(0xFF0B0016);

  // Blue accent palette
  static const Color electricBlue = Color(0xFF4BB3FD);
  static const Color steelBlue = Color(0xFF3E6680);
  static const Color brightBlue = Color(0xFF0496FF);
  static const Color deepBlue = Color(0xFF027BCE);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Surface colors for glass effects (light theme - use semi-transparent dark/gray)
  static const Color surfaceLight = Color(0x0A000000);
  static const Color surfaceMedium = Color(0x14000000);
  static const Color surfaceDark = Color(0x1F000000);

  // Text colors (default - for light backgrounds)
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A4A5A);
  static const Color textTertiary = Color(0xFF7A7A8A);

  // Text colors (for dark backgrounds / colored buttons)
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xB3FFFFFF);
  static const Color textOnDarkTertiary = Color(0x80FFFFFF);

  // Legacy aliases for light/glass backgrounds (same as textPrimary/Secondary/Tertiary now)
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textDarkSecondary = Color(0xFF4A4A5A);
  static const Color textDarkTertiary = Color(0xFF7A7A8A);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);

  // Driver-specific accent color (slightly different shade for differentiation)
  static const Color driverAccent = Color(0xFF00BFA5);
}
