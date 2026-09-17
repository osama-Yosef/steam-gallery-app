// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maps_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single place that picks the map provider. Google Maps later = a new
/// MapWidgetFactory implementation returned here; no screen changes.

@ProviderFor(mapWidgetFactory)
const mapWidgetFactoryProvider = MapWidgetFactoryProvider._();

/// The single place that picks the map provider. Google Maps later = a new
/// MapWidgetFactory implementation returned here; no screen changes.

final class MapWidgetFactoryProvider
    extends
        $FunctionalProvider<
          MapWidgetFactory,
          MapWidgetFactory,
          MapWidgetFactory
        >
    with $Provider<MapWidgetFactory> {
  /// The single place that picks the map provider. Google Maps later = a new
  /// MapWidgetFactory implementation returned here; no screen changes.
  const MapWidgetFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapWidgetFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapWidgetFactoryHash();

  @$internal
  @override
  $ProviderElement<MapWidgetFactory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MapWidgetFactory create(Ref ref) {
    return mapWidgetFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapWidgetFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapWidgetFactory>(value),
    );
  }
}

String _$mapWidgetFactoryHash() => r'1b019cc67a7d597dd59edb7b83f81e3a2b14946e';

/// Reverse geocoding sends the chosen pin to OpenStreetMap's Nominatim to
/// suggest an address line. Swap in [NoopGeocodingService] to keep
/// coordinates on-device entirely.

@ProviderFor(geocodingService)
const geocodingServiceProvider = GeocodingServiceProvider._();

/// Reverse geocoding sends the chosen pin to OpenStreetMap's Nominatim to
/// suggest an address line. Swap in [NoopGeocodingService] to keep
/// coordinates on-device entirely.

final class GeocodingServiceProvider
    extends
        $FunctionalProvider<
          GeocodingService,
          GeocodingService,
          GeocodingService
        >
    with $Provider<GeocodingService> {
  /// Reverse geocoding sends the chosen pin to OpenStreetMap's Nominatim to
  /// suggest an address line. Swap in [NoopGeocodingService] to keep
  /// coordinates on-device entirely.
  const GeocodingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geocodingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geocodingServiceHash();

  @$internal
  @override
  $ProviderElement<GeocodingService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GeocodingService create(Ref ref) {
    return geocodingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeocodingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeocodingService>(value),
    );
  }
}

String _$geocodingServiceHash() => r'ba3ff9cf0da379d96c0ae517b197102b37c24554';

@ProviderFor(deviceLocationService)
const deviceLocationServiceProvider = DeviceLocationServiceProvider._();

final class DeviceLocationServiceProvider
    extends
        $FunctionalProvider<
          DeviceLocationService,
          DeviceLocationService,
          DeviceLocationService
        >
    with $Provider<DeviceLocationService> {
  const DeviceLocationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceLocationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceLocationServiceHash();

  @$internal
  @override
  $ProviderElement<DeviceLocationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceLocationService create(Ref ref) {
    return deviceLocationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceLocationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceLocationService>(value),
    );
  }
}

String _$deviceLocationServiceHash() =>
    r'42086df98951a0a812fda423d1a2e9c3f74ecbc1';
