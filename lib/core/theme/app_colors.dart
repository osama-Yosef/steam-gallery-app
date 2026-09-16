import 'package:flutter/material.dart';

/// Mokoji palette on the glassmorphic dark theme — a deep navy base (the
/// logo's navy, darkened) with translucent glass surfaces floating over a
/// gradient-blob background, see GlassBackground/GlassPanel. Single dark
/// theme only, see AppTheme.
///
/// Brand colours were sampled from the logo artwork:
///   navy #244A61 (outline + wordmark), teal #67A9B2 (iron body),
///   gold #E4B83F (wrench + gear), paper #F4F9FA (background).
abstract final class AppColors {
  // Exact brand colours — for brand surfaces (logo card, splash, icons), not
  // for general UI text on the dark background.
  static const brandNavy = Color(0xFF244A61);
  static const brandTeal = Color(0xFF67A9B2);
  static const brandGold = Color(0xFFE4B83F);
  static const brandPaper = Color(0xFFF4F9FA);

  // Teal, lifted for text/icons on the dark background (~8:1 contrast).
  static const primary = Color(0xFF7CC1C9);
  // Teal, deepened for filled buttons carrying white labels (~5:1 contrast).
  static const primaryDark = Color(0xFF2F7784);
  static const accent = brandGold;
  static const accentSoft = Color(0xFFA8D5DB);

  static const success = Color(0xFF34D399);
  static const danger = Color(0xFFF87171);
  static const warning = Color(0xFFFBBF24);
  static const info = primary;

  // Base gradient behind every screen (deep navy → brand navy).
  static const bgTop = Color(0xFF0B1F29);
  static const bgBottom = Color(0xFF12303F);
  static const background = bgTop;

  // Floating gradient "blobs" blurred behind the glass surfaces.
  static const blobTeal = Color(0xFF2F8A99);
  static const blobGold = brandGold;
  static const blobSky = brandTeal;

  // Glass surfaces: translucent white fills + light-stroke borders.
  static const glassFill = Color(0x14FFFFFF); // ~8% white
  static const glassFillStrong = Color(0x22FFFFFF); // ~13% white
  static const glassBorder = Color(0x33FFFFFF); // ~20% white
  static const glassHighlight = Color(0x59FFFFFF); // ~35% white, top-edge sheen

  static const surface = Color(0xFF12303E);
  static const surfaceHigh = Color(0xFF183A4A);
  static const border = Color(0x26FFFFFF);
  static const textPrimary = Color(0xFFF4F9FA);
  static const textSecondary = Color(0xFFA9BEC7);

  // Kept for any lingering references — the app no longer ships a light mode.
  static const lightBackground = brandPaper;
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkBackground = background;
  static const darkSurface = surface;
}
