// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locations_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(locationsRepository)
const locationsRepositoryProvider = LocationsRepositoryProvider._();

final class LocationsRepositoryProvider
    extends
        $FunctionalProvider<
          LocationsRepository,
          LocationsRepository,
          LocationsRepository
        >
    with $Provider<LocationsRepository> {
  const LocationsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationsRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocationsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocationsRepository create(Ref ref) {
    return locationsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationsRepository>(value),
    );
  }
}

String _$locationsRepositoryHash() =>
    r'ddfafc5a4ebb5ff23d9fc95406459754a5cdcad0';

@ProviderFor(cities)
const citiesProvider = CitiesFamily._();

final class CitiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<City>>,
          List<City>,
          FutureOr<List<City>>
        >
    with $FutureModifier<List<City>>, $FutureProvider<List<City>> {
  const CitiesProvider._({
    required CitiesFamily super.from,
    required bool super.argument,
  }) : super(
         retry: null,
         name: r'citiesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$citiesHash();

  @override
  String toString() {
    return r'citiesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<City>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<City>> create(Ref ref) {
    final argument = this.argument as bool;
    return cities(ref, activeOnly: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CitiesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$citiesHash() => r'6f3dddf4ac10e8f1cb9ddf1081ba4022b034f49b';

final class CitiesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<City>>, bool> {
  const CitiesFamily._()
    : super(
        retry: null,
        name: r'citiesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CitiesProvider call({bool activeOnly = true}) =>
      CitiesProvider._(argument: activeOnly, from: this);

  @override
  String toString() => r'citiesProvider';
}

@ProviderFor(serviceAreas)
const serviceAreasProvider = ServiceAreasFamily._();

final class ServiceAreasProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ServiceArea>>,
          List<ServiceArea>,
          FutureOr<List<ServiceArea>>
        >
    with
        $FutureModifier<List<ServiceArea>>,
        $FutureProvider<List<ServiceArea>> {
  const ServiceAreasProvider._({
    required ServiceAreasFamily super.from,
    required (String, {bool activeOnly}) super.argument,
  }) : super(
         retry: null,
         name: r'serviceAreasProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$serviceAreasHash();

  @override
  String toString() {
    return r'serviceAreasProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ServiceArea>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ServiceArea>> create(Ref ref) {
    final argument = this.argument as (String, {bool activeOnly});
    return serviceAreas(ref, argument.$1, activeOnly: argument.activeOnly);
  }

  @override
  bool operator ==(Object other) {
    return other is ServiceAreasProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$serviceAreasHash() => r'8fe234c6829b8a5c19093620b0c4d7edb27b5896';

final class ServiceAreasFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ServiceArea>>,
          (String, {bool activeOnly})
        > {
  const ServiceAreasFamily._()
    : super(
        retry: null,
        name: r'serviceAreasProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ServiceAreasProvider call(String cityId, {bool activeOnly = true}) =>
      ServiceAreasProvider._(
        argument: (cityId, activeOnly: activeOnly),
        from: this,
      );

  @override
  String toString() => r'serviceAreasProvider';
}

@ProviderFor(myAddresses)
const myAddressesProvider = MyAddressesProvider._();

final class MyAddressesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CustomerAddress>>,
          List<CustomerAddress>,
          FutureOr<List<CustomerAddress>>
        >
    with
        $FutureModifier<List<CustomerAddress>>,
        $FutureProvider<List<CustomerAddress>> {
  const MyAddressesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myAddressesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myAddressesHash();

  @$internal
  @override
  $FutureProviderElement<List<CustomerAddress>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CustomerAddress>> create(Ref ref) {
    return myAddresses(ref);
  }
}

String _$myAddressesHash() => r'27ba735f37d7c49967f745dd6391c4a6ecb7a942';

@ProviderFor(myCityId)
const myCityIdProvider = MyCityIdProvider._();

final class MyCityIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  const MyCityIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myCityIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myCityIdHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return myCityId(ref);
  }
}

String _$myCityIdHash() => r'ca40dc58e21b89ee0e9f342a3e49585478247805';

@ProviderFor(countries)
const countriesProvider = CountriesProvider._();

final class CountriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Country>>,
          List<Country>,
          FutureOr<List<Country>>
        >
    with $FutureModifier<List<Country>>, $FutureProvider<List<Country>> {
  const CountriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countriesHash();

  @$internal
  @override
  $FutureProviderElement<List<Country>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Country>> create(Ref ref) {
    return countries(ref);
  }
}

String _$countriesHash() => r'12008318162890da4f122d62da1e0bae854ba2ac';
