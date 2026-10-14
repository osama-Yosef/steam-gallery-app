import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'safe_graphics.dart';

/// Single light theme for every role (Mokoji identity: paper background,
/// navy text, teal actions). GlassBackground paints a soft gradient +
/// blurred color blobs behind the whole app (see app.dart), every Scaffold
/// here is transparent so that shows through, and cards/inputs/app bars use
/// a near-opaque white fill with a faint navy hairline. This is the
/// same one-place-cascades-everywhere trick as the earlier dark-navy theme:
/// no BackdropFilter blur on ordinary content cards (too expensive to apply
/// screen-wide), just color/opacity — genuine blur is reserved for the new
/// navigation chrome (GlassPanel: sidebar / bottom nav), see AdminShell /
/// CustomerShell / TechnicianShell.
///
/// Arabic-first typography: Cairo, bundled as assets (see pubspec.yaml)
/// rather than fetched over the network, applied once here via
/// `ThemeData.fontFamily` so every Text widget in the app inherits it.
abstract final class AppTheme {
  /// Component themes that set their own TextStyle (chips, hints, nav
  /// labels) name it too: such a style replaces the inherited one, font
  /// included.
  static const _font = 'Cairo';

  static ThemeData light() {
    // Old graphics cards (see SafeGraphics) draw see-through colours and
    // shadows as nothing: there every fill, border and backdrop is opaque.
    final safe = SafeGraphics.enabled;
    final fill = safe ? AppColors.surface : AppColors.glassFill;
    final fillStrong = safe ? AppColors.surface : AppColors.glassFillStrong;
    final hairline = safe ? AppColors.safeBorder : AppColors.glassBorder;
    final backdrop = safe ? AppColors.bgTop : Colors.transparent;
    final double raised = safe ? 0 : 2;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          error: AppColors.danger,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          outline: safe ? AppColors.safeBorder : AppColors.border,
          surfaceContainerHighest: AppColors.surfaceHigh,
        );

    // The font goes on the text theme itself: `ThemeData.fontFamily` below
    // only reaches Flutter's *default* text theme, and this one (whose
    // styles name Roboto) replaces it — without this every Text fell back
    // to Roboto/the system font and Cairo was never drawn.
    final textTheme = ThemeData(brightness: Brightness.light).textTheme.apply(
      fontFamily: _font,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _font,
      colorScheme: scheme,
      scaffoldBackgroundColor: backdrop,
      // NOT transparent: canvasColor backs popup/dropdown menus (Dropdown
      // menus, PopupMenuButton, etc.) — transparent here left dropdown
      // options with no surface behind them, overlapping the form beneath
      // and making the whole control look broken. Scaffold transparency
      // (for GlassBackground to show through) comes from
      // scaffoldBackgroundColor above, which doesn't have this problem.
      canvasColor: AppColors.surfaceHigh,
      // Body text one weight above Regular so it reads clearly.
      textTheme: textTheme.copyWith(
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: safe ? AppColors.safeBorder : AppColors.border,
        space: 1,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backdrop,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Dark status-bar icons over the light background.
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: fill,
        hintStyle: const TextStyle(
          fontFamily: _font,
          color: AppColors.textSecondary,
        ),
        labelStyle: const TextStyle(
          fontFamily: _font,
          color: AppColors.textPrimary,
        ),
      ),
      // Filled surfaces carrying white labels use the deepest teal for
      // contrast; `primary` is for text and icons.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: raised,
          shadowColor: AppColors.primaryDark.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: raised,
          shadowColor: AppColors.primaryDark.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: hairline),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      cardTheme: CardThemeData(
        color: fill,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: hairline, width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: fillStrong,
        labelStyle: const TextStyle(
          fontFamily: _font,
          color: AppColors.textPrimary,
        ),
        side: BorderSide(color: hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: hairline),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: safe
            ? AppColors.safeIndicator
            : AppColors.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: _font,
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: safe ? 0 : 3,
        highlightElevation: safe ? 0 : 6,
      ),
    );
  }
}
