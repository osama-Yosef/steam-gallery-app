import 'package:flutter/material.dart';

/// Mokoji light palette — the brand's paper background with navy text, teal
/// actions and gold accents, matching the identity artwork. Surfaces are
/// "glass" in the light sense: mostly-opaque white over a soft gradient, with
/// a faint navy hairline (see GlassBackground/GlassPanel). Single light theme
/// for every role, see AppTheme.
///
/// Brand colours were sampled from the logo artwork:
///   navy #244A61 (outline + wordmark), teal #67A9B2 (iron body),
///   gold #E4B83F (wrench + gear), paper #F4F9FA (background).
abstract final class AppColors {
  // Exact brand colours — for brand surfaces (logo, splash, icons,
  // decorative accents), not for small text.
  static const brandNavy = Color(0xFF244A61);
  static const brandTeal = Color(0xFF67A9B2);
  static const brandGold = Color(0xFFE4B83F);
  static const brandPaper = Color(0xFFF4F9FA);

  // Teal, deepened for text/icons on white (~5:1 contrast).
  static const primary = Color(0xFF2F7784);
  // Deeper still for filled buttons carrying white labels (~6.5:1).
  static const primaryDark = Color(0xFF235F6A);
  static const accent = brandGold;
  static const accentSoft = Color(0xFFD9ECEF);

  // Darker than their dark-theme counterparts so they read on white.
  static const success = Color(0xFF047857);
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFB45309);
  static const info = primary;

  // Base gradient behind every screen (paper → faint teal).
  static const bgTop = brandPaper;
  static const bgBottom = Color(0xFFE3EFF1);
  static const background = bgTop;

  // Floating gradient "blobs" blurred behind the surfaces.
  static const blobTeal = brandTeal;
  static const blobGold = brandGold;
  static const blobSky = Color(0xFF9CCBD2);

  // Light "glass": near-opaque white fills + a faint navy hairline.
  static const glassFill = Color(0xC7FFFFFF); // ~78% white
  static const glassFillStrong = Color(0xEBFFFFFF); // ~92% white
  static const glassBorder = Color(0x1F244A61); // ~12% navy
  static const glassHighlight = Color(0xF2FFFFFF);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFFFFFFF);
  static const border = Color(0x1F244A61);
  static const textPrimary = Color(0xFF16323F);
  static const textSecondary = Color(0xFF5B7280);

  /// Soft shadow for raised surfaces on the light background.
  static const shadow = Color(0x1A16323F);

  static const lightBackground = brandPaper;
  static const lightSurface = surface;
}
