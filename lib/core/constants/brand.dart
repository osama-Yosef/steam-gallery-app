/// The single source of truth for the product's identity inside the app.
/// Platform-level names (Android label, iOS display name, Windows resources,
/// web manifest) can't read Dart constants and repeat these values by hand —
/// test/brand_test.dart keeps them in step.
///
/// The Dart package, Android applicationId and iOS bundle id deliberately keep
/// their original `steam_gallery_app` names: changing them would publish a
/// different app to the stores and orphan existing installs.
abstract final class Brand {
  /// Shown everywhere a user sees the product's name.
  static const name = 'مكوجي';

  /// Latin spelling, for places that can't render Arabic (Windows file
  /// metadata, package file names).
  static const nameLatin = 'Mokoji';

  /// One line under the logo on the splash and login screens.
  static const tagline = 'مكاوي البخار — منتجات وصيانة';

  /// Full logo (mark + wordmark), transparent. Navy wordmark: always place it
  /// on a light surface — see BrandLogo.
  static const logoAsset = 'assets/brand/mokoji_logo.png';

  /// The iron-and-gear mark alone, transparent.
  static const markAsset = 'assets/brand/mokoji_mark.png';
}
