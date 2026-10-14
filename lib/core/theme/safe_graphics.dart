/// "Safe graphics" mode for PCs with old graphics cards (seen on an old AMD
/// Radeon running the Windows app): colours, gradients and the see-through
/// "glass" surfaces drew as nothing, leaving screens blank.
///
/// When it is on, the Windows runner turns Impeller off (the older Skia
/// renderer copes with those drivers) and the app draws flat: solid opaque
/// fills, no gradients, no translucency, no shadows.
///
/// Turned on by any of:
///  * a file named `safe_graphics` next to the .exe (what the "safe" build
///    ships with — the runner sees it and passes `--safe-graphics` on),
///  * running the .exe with `--safe-graphics`,
///  * building with `--dart-define=SAFE_GRAPHICS=true`.
abstract final class SafeGraphics {
  static const _fromBuild = bool.fromEnvironment('SAFE_GRAPHICS');

  static bool _enabled = _fromBuild;

  static bool get enabled => _enabled;

  static void init(List<String> args) {
    _enabled = _fromBuild || args.contains('--safe-graphics');
  }
}
