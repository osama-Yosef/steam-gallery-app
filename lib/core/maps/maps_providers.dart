import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'device_location_service.dart';
import 'geocoding_service.dart';
import 'map_widget_factory.dart';
import 'osm/osm_map_widget_factory.dart';

part 'maps_providers.g.dart';

/// The single place that picks the map provider. Google Maps later = a new
/// MapWidgetFactory implementation returned here; no screen changes.
@Riverpod(keepAlive: true)
MapWidgetFactory mapWidgetFactory(Ref ref) => const OsmMapWidgetFactory();

/// Reverse geocoding sends the chosen pin to OpenStreetMap's Nominatim to
/// suggest an address line. Swap in [NoopGeocodingService] to keep
/// coordinates on-device entirely.
@Riverpod(keepAlive: true)
GeocodingService geocodingService(Ref ref) => NominatimGeocodingService();

@Riverpod(keepAlive: true)
DeviceLocationService deviceLocationService(Ref ref) =>
    const GeolocatorDeviceLocationService();
