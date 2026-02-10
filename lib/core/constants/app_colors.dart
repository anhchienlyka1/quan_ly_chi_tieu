import 'package:flutter/material.dart';

/// Semantic color palette for the app.
/// Use these instead of hardcoded colors throughout the app.
class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42D4);

  // Semantic Colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFFF9F43);
  static const Color error = Color(0xFFEE5A6A);
  static const Color info = Color(0xFF54A0FF);

  // Category Colors (for expense categories)
  static const Color categoryFood = Color(0xFFFF6B6B);
  static const Color categoryTransport = Color(0xFF54A0FF);
  static const Color categoryShopping = Color(0xFFFECA57);
  static const Color categoryEntertainment = Color(0xFF5F27CD);
  static const Color categoryHealth = Color(0xFF2ECC71);
  static const Color categoryEducation = Color(0xFF00D2D3);
  static const Color categoryBills = Color(0xFFFF9F43);
  static const Color categoryOther = Color(0xFF8395A7);

  // Neutral Colors
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMedium = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);

  // Surface Colors (Light)
  static const Color surfaceLight = Color(0xFFF8F9FE);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Surface Colors (Dark)
  static const Color surfaceDark = Color(0xFF121218);
  static const Color cardDark = Color(0xFF252535);
  static const Color backgroundDark = Color(0xFF1E1E2C);

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFEE5A6A), Color(0xFFE74C3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
