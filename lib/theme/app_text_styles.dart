import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Predefined text styles for consistent typography.
/// Use these via `AppTextStyles.xxx` or via `Theme.of(context).textTheme`.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.0,
      );

  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineLarge => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleLarge => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyLarge => GoogleFonts.outfit(
        fontSize: 16,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
        fontSize: 14,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.outfit(
        fontSize: 12,
        height: 1.5,
      );

  static TextStyle get labelLarge => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get amount => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );
}
