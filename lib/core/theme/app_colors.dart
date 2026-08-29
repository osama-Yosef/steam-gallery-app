import 'package:flutter/material.dart';

/// Brand palette for معرض أجهزة البخار. Kept as plain static constants
/// (not a theme extension) so any widget can reach for a semantic color
/// without threading BuildContext lookups everywhere.
abstract final class AppColors {
  static const primary = Color(0xFF0F766E); // teal — steam/vapor association
  static const primaryDark = Color(0xFF115E59);
  static const accent = Color(0xFFF59E0B);

  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);
  static const info = Color(0xFF2563EB);

  static const lightBackground = Color(0xFFF7F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkBackground = Color(0xFF0E1414);
  static const darkSurface = Color(0xFF17201F);
}
