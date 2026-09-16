import 'package:flutter/widgets.dart';
import 'geo_point.dart';

/// Lets a screen move a picker map programmatically (e.g. "use my location",
/// or recentering when the city changes) without knowing which map package
/// is behind it.
abstract class MapPickerController {
  void moveTo(GeoPoint center, {double? zoom});
}

/// Builds map widgets. Screens depend only on this (via
/// mapWidgetFactoryProvider), so moving from OpenStreetMap to Google Maps —
/// or showing a placeholder in widget tests — is a provider swap, not a
/// rewrite of every screen that shows a map.
abstract class MapWidgetFactory {
  /// A full interactive map with a fixed pin in the middle: the user drags
  /// the map under the pin. [onCenterChanged] fires as the map moves;
  /// [onCenterSettled] once it stops (debounce any network work on that).
  Widget locationPicker({
    Key? key,
    required GeoPoint initialCenter,
    double initialZoom,
    required ValueChanged<GeoPoint> onCenterChanged,
    ValueChanged<GeoPoint>? onCenterSettled,
    List<MapCircle> circles,
    ValueChanged<MapPickerController>? onControllerReady,
  });

  /// A small non-interactive map showing [marker] and/or [circles].
  Widget preview({
    Key? key,
    required GeoPoint center,
    double zoom,
    GeoPoint? marker,
    List<MapCircle> circles,
  });
}

/// Zoom levels shared by every implementation, so screens don't guess numbers
/// per provider.
abstract final class MapZoom {
  static const city = 11.0;
  static const neighbourhood = 14.0;
  static const street = 16.5;
}
