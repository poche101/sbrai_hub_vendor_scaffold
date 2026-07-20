import 'package:flutter/material.dart';

/// Sbrai Hub brand palette — orange primary (buyer actions / brand),
/// navy secondary (vendor identity), matching the provided designs.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE85D2C); // Sbrai orange
  static const Color primaryDark = Color(0xFFC94A1E);
  static const Color primaryLight = Color(0xFFFCEFE9);

  static const Color navy = Color(0xFF1E2352); // Vendor accent
  static const Color navyDark = Color(0xFF14173B);

  static const Color success = Color(0xFF1C9E4A);
  static const Color warning = Color(0xFFD08A00);
  static const Color danger = Color(0xFFE03B3B);

  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE3E5EA);

  static const Color textPrimary = Color(0xFF17181C);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
}
