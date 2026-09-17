/// A WGS84 coordinate, owned by this app rather than any map package, so
/// models, repositories and screens never depend on flutter_map/latlong2 or a
/// future Google Maps type. Conversion happens only inside the provider
/// implementation (lib/core/maps/osm/).
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude)
    : assert(latitude >= -90 && latitude <= 90),
      assert(longitude >= -180 && longitude <= 180);

  /// Stored as numeric(10,7) server-side: 7 decimals ≈ 1 cm, more is noise.
  GeoPoint rounded() => GeoPoint(
    double.parse(latitude.toStringAsFixed(7)),
    double.parse(longitude.toStringAsFixed(7)),
  );

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

/// A circle to draw on a map — how service areas are displayed.
class MapCircle {
  final GeoPoint center;
  final double radiusKm;

  /// Drawn highlighted (e.g. the area being edited, or an active one).
  final bool emphasized;

  const MapCircle({
    required this.center,
    required this.radiusKm,
    this.emphasized = true,
  });
}
