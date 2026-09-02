import 'package:flutter/material.dart';

/// Glassmorphic dark palette — deep navy/violet base with translucent glass
/// surfaces (blur + low-opacity fill + light border) floating over a
/// gradient-blob background, see GlassBackground/GlassPanel. Single dark
/// theme only, see AppTheme.
abstract final class AppColors {
  static const primary = Color(0xFF6D8CFF);
  static const primaryDark = Color(0xFF3B5BFF);
  static const accent = Color(0xFFB07CFF);
  static const accentSoft = Color(0xFF7CE0FF);

  static const success = Color(0xFF34D399);
  static const danger = Color(0xFFF87171);
  static const warning = Color(0xFFFBBF24);
  static const info = Color(0xFF6D8CFF);

  // Base gradient behind every screen (deep space navy → violet).
  static const bgTop = Color(0xFF0B0E1F);
  static const bgBottom = Color(0xFF161334);
  static const background = bgTop;

  // Floating gradient "blobs" blurred behind the glass surfaces.
  static const blobBlue = Color(0xFF3B5BFF);
  static const blobViolet = Color(0xFFB07CFF);
  static const blobCyan = Color(0xFF7CE0FF);

  // Glass surfaces: translucent white fills + light-stroke borders.
  static const glassFill = Color(0x14FFFFFF); // ~8% white
  static const glassFillStrong = Color(0x22FFFFFF); // ~13% white
  static const glassBorder = Color(0x33FFFFFF); // ~20% white
  static const glassHighlight = Color(0x59FFFFFF); // ~35% white, top-edge sheen

  static const surface = Color(0xFF171A33);
  static const surfaceHigh = Color(0xFF1F2340);
  static const border = Color(0x26FFFFFF);
  static const textPrimary = Color(0xFFF5F6FC);
  static const textSecondary = Color(0xFFA3A7C2);

  // Kept for any lingering references — the app no longer ships a light mode.
  static const lightBackground = Color(0xFFF7F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkBackground = background;
  static const darkSurface = surface;
}
