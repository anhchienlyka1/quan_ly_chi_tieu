import 'package:flutter/material.dart';

/// Color palette designed for Vietnamese household expense app.
/// Warm teal + coral combo symbolizing harmony between husband & wife.
class AppColors {
  AppColors._();

  // Brand Colors — Warm & Inviting
  static const Color primary = Color(0xFF2EC4B6);       // Soft teal
  static const Color primaryLight = Color(0xFF5EDDD0);
  static const Color primaryDark = Color(0xFF1A9E92);
  static const Color accent = Color(0xFFFF6B6B);         // Warm coral
  static const Color accentLight = Color(0xFFFF9A9A);

  // Couple Colors
  static const Color husband = Color(0xFF4A90D9);        // Calm blue
  static const Color husbandLight = Color(0xFFE8F0FA);
  static const Color wife = Color(0xFFE88CA5);           // Soft pink
  static const Color wifeLight = Color(0xFFFCEDF1);

  // Semantic Colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFFFB946);
  static const Color error = Color(0xFFEE5A6A);
  static const Color info = Color(0xFF54A0FF);

  // Category Colors (Vietnamese household)
  static const Color categoryFood = Color(0xFFFF6B6B);       // Ăn uống
  static const Color categoryRent = Color(0xFF6C5CE7);        // Tiền nhà
  static const Color categoryUtilities = Color(0xFFFFB946);   // Điện nước
  static const Color categoryTransport = Color(0xFF54A0FF);   // Xăng xe
  static const Color categoryChildren = Color(0xFF2ECC71);    // Con cái
  static const Color categoryCeremony = Color(0xFFE88CA5);    // Hiếu hỉ
  static const Color categoryShopping = Color(0xFFFECA57);    // Mua sắm
  static const Color categoryHealth = Color(0xFF00D2D3);      // Sức khỏe
  static const Color categoryEducation = Color(0xFF5F27CD);   // Giáo dục
  static const Color categoryOther = Color(0xFF8395A7);       // Khác

  // Neutral Colors
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMedium = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFF0F0F5);

  // Surface Colors (Light)
  static const Color surfaceLight = Color(0xFFF7F8FC);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Surface Colors (Dark)
  static const Color surfaceDark = Color(0xFF121218);
  static const Color cardDark = Color(0xFF1E1E2C);
  static const Color backgroundDark = Color(0xFF16161E);

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2EC4B6), Color(0xFF26D0CE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient homeHeaderGradient = LinearGradient(
    colors: [Color(0xFF2EC4B6), Color(0xFF0ABAB5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A5A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coupleGradient = LinearGradient(
    colors: [Color(0xFF4A90D9), Color(0xFFE88CA5)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
