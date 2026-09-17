import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:steam_gallery_app/core/maps/geo_point.dart';
import 'package:steam_gallery_app/core/maps/geocoding_service.dart';
import 'package:steam_gallery_app/core/maps/map_widget_factory.dart';
import 'package:steam_gallery_app/core/maps/maps_providers.dart';
import 'package:steam_gallery_app/features/locations/data/models/location_models.dart';
import 'package:steam_gallery_app/features/locations/data/repositories/locations_repository.dart';
import 'package:steam_gallery_app/features/locations/presentation/providers/locations_providers.dart';
import 'package:steam_gallery_app/features/locations/presentation/screens/customer/address_form_screen.dart';
import 'package:steam_gallery_app/features/locations/presentation/screens/customer/my_addresses_screen.dart';

const _cairoCenter = GeoPoint(30.0444, 31.2357);
const _nasrCity = GeoPoint(30.0561, 31.3301);
const _maadi = GeoPoint(29.9602, 31.2569);

const _cairo = City(
  id: 'cairo',
  countryId: 'eg',
  nameAr: 'القاهرة',
  center: _cairoCenter,
  isActive: true,
  sortOrder: 1,
);

/// In-memory stand-in for the server: coverage is decided by a lookup the
/// test controls, exactly as the real screens only ever ask the server.
class _FakeLocationsRepository implements LocationsRepository {
  final covered = <GeoPoint, String>{_nasrCity: 'مدينة نصر'};
  final addresses = <CustomerAddress>[];
  AddressInput? lastSaved;
  final checks = <GeoPoint>[];

  ServiceAvailability _availability(GeoPoint p) => ServiceAvailability(
    available: covered.containsKey(p),
    serviceAreaId: covered.containsKey(p) ? 'area' : null,
    serviceAreaName: covered[p],
  );

  @override
  Future<List<City>> getCities({bool activeOnly = true}) async => [_cairo];

  @override
  Future<List<ServiceArea>> getServiceAreas(
    String cityId, {
    bool activeOnly = true,
  }) async => const [];

  @override
  Future<String?> getMyCityId() async => 'cairo';

  @override
  Future<List<CustomerAddress>> getMyAddresses() async => List.of(addresses);

  @override
  Future<ServiceAvailability> checkAvailability(
    String cityId,
    GeoPoint point,
  ) async {
    checks.add(point);
    return _availability(point);
  }

  @override
  Future<SavedAddressResult> saveMyAddress(AddressInput input) async {
    lastSaved = input;
    return SavedAddressResult(
      id: 'new-id',
      availability: _availability(input.location),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected');
}

/// A "map" made of buttons: each one moves the pin to a known point and lets
/// it settle, the same callbacks a real map fires.
class _FakeMapFactory implements MapWidgetFactory {
  @override
  Widget locationPicker({
    Key? key,
    required GeoPoint initialCenter,
    double initialZoom = MapZoom.street,
    required ValueChanged<GeoPoint> onCenterChanged,
    ValueChanged<GeoPoint>? onCenterSettled,
    List<MapCircle> circles = const [],
    ValueChanged<MapPickerController>? onControllerReady,
  }) {
    void moveTo(GeoPoint p) {
      onCenterChanged(p);
      onCenterSettled?.call(p);
    }

    return ListView(
      key: key,
      children: [
        TextButton(
          key: const Key('fake-map-nasr'),
          onPressed: () => moveTo(_nasrCity),
          child: const Text('nasr'),
        ),
        TextButton(
          key: const Key('fake-map-maadi'),
          onPressed: () => moveTo(_maadi),
          child: const Text('maadi'),
        ),
      ],
    );
  }

  @override
  Widget preview({
    Key? key,
    required GeoPoint center,
    double zoom = MapZoom.street,
    GeoPoint? marker,
    List<MapCircle> circles = const [],
  }) => SizedBox(key: key);
}

class _FakeGeocoder implements GeocodingService {
  @override
  Future<String?> reverseGeocode(GeoPoint point) async =>
      'شارع مكرم عبيد، مدينة نصر';
}

Future<_FakeLocationsRepository> _pump(
  WidgetTester tester,
  Widget screen, {
  _FakeLocationsRepository? repo,
}) async {
  final fake = repo ?? _FakeLocationsRepository();
  await tester.binding.setSurfaceSize(const Size(420, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        locationsRepositoryProvider.overrideWithValue(fake),
        mapWidgetFactoryProvider.overrideWithValue(_FakeMapFactory()),
        geocodingServiceProvider.overrideWithValue(_FakeGeocoder()),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open'),
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => screen)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  group('formatNominatimAddress', () {
    test('street with number and neighbourhood', () {
      expect(
        formatNominatimAddress({
          'address': {
            'road': 'شارع مكرم عبيد',
            'house_number': '12',
            'suburb': 'مدينة نصر',
            'country': 'مصر',
          },
        }),
        'شارع مكرم عبيد 12، مدينة نصر',
      );
    });

    test('falls back across keys and skips empties', () {
      expect(
        formatNominatimAddress({
          'address': {'road': ' ', 'pedestrian': 'ممشى', 'quarter': 'الحي'},
        }),
        'ممشى، الحي',
      );
    });

    test('nothing usable gives null, never a country-only line', () {
      expect(
        formatNominatimAddress({
          'address': {'country': 'مصر'},
        }),
        isNull,
      );
      expect(formatNominatimAddress({'error': 'Unable to geocode'}), isNull);
    });
  });

  group('CustomerAddress.fromRow', () {
    final row = {
      'id': 'a1',
      'city_id': 'cairo',
      'cities': {'name_ar': 'القاهرة'},
      'service_area_id': 'area',
      'service_areas': {'name_ar': 'مدينة نصر'},
      'label': 'المنزل',
      'address_line': 'شارع عباس العقاد',
      'building': '12',
      'floor': null,
      'apartment': '7',
      'latitude': 30.0561,
      'longitude': 31.3301,
      'is_default': true,
    };

    test('maps embedded names, coverage and details', () {
      final a = CustomerAddress.fromRow(row);
      expect(a.cityName, 'القاهرة');
      expect(a.serviceAreaName, 'مدينة نصر');
      expect(a.isServiceable, isTrue);
      expect(a.detailsLine, 'عمارة 12، شقة 7');
      expect(a.location, _nasrCity);
    });

    test('no area means not serviceable', () {
      final a = CustomerAddress.fromRow({
        ...row,
        'service_area_id': null,
        'service_areas': null,
      });
      expect(a.isServiceable, isFalse);
    });
  });

  group('MyAddressesScreen', () {
    testWidgets('empty state offers to add an address', (tester) async {
      await _pump(tester, const MyAddressesScreen());
      expect(find.textContaining('لسه مفيش عناوين'), findsOneWidget);
      expect(find.text('إضافة عنوان'), findsWidgets);
    });

    testWidgets('shows the default and the server coverage per address', (
      tester,
    ) async {
      final repo = _FakeLocationsRepository();
      repo.addresses.addAll([
        const CustomerAddress(
          id: '1',
          cityId: 'cairo',
          cityName: 'القاهرة',
          serviceAreaId: 'area',
          serviceAreaName: 'مدينة نصر',
          label: 'المنزل',
          addressLine: 'شارع عباس العقاد',
          location: _nasrCity,
          isDefault: true,
        ),
        const CustomerAddress(
          id: '2',
          cityId: 'cairo',
          label: 'العمل',
          addressLine: 'كورنيش المعادي',
          location: _maadi,
          isDefault: false,
        ),
      ]);
      await _pump(tester, const MyAddressesScreen(), repo: repo);

      expect(find.text('الافتراضي'), findsOneWidget);
      expect(find.text('الخدمة متاحة — مدينة نصر'), findsOneWidget);
      expect(find.text('المنطقة غير مغطاة حاليًا'), findsOneWidget);
    });
  });

  group('AddressFormScreen (new)', () {
    testWidgets('coverage comes from the server as the pin settles', (
      tester,
    ) async {
      final repo = await _pump(tester, const AddressFormScreen());

      await tester.tap(find.byKey(const Key('fake-map-maadi')));
      await tester.pumpAndSettle();
      expect(repo.checks.last, _maadi);
      expect(find.text('المنطقة غير مغطاة حاليًا'), findsOneWidget);

      await tester.tap(find.byKey(const Key('fake-map-nasr')));
      await tester.pumpAndSettle();
      expect(repo.checks.last, _nasrCity);
      expect(find.text('الخدمة متاحة — مدينة نصر'), findsOneWidget);
    });

    testWidgets('confirm pin → suggested line → saved with the pin and label', (
      tester,
    ) async {
      final repo = await _pump(tester, const AddressFormScreen());

      await tester.tap(find.byKey(const Key('fake-map-nasr')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('address-confirm-pin')));
      await tester.pumpAndSettle();

      // Reverse geocoding filled the empty line.
      expect(find.text('شارع مكرم عبيد، مدينة نصر'), findsOneWidget);

      await tester.tap(find.text('العمل'));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('address-save')));
      await tester.tap(find.byKey(const Key('address-save')));
      await tester.pumpAndSettle();

      final saved = repo.lastSaved!;
      expect(saved.id, isNull);
      expect(saved.cityId, 'cairo');
      expect(saved.location, _nasrCity);
      expect(saved.label, 'العمل');
      expect(saved.addressLine, 'شارع مكرم عبيد، مدينة نصر');
      // Back on the previous page, with the server's verdict.
      expect(find.byKey(const Key('open')), findsOneWidget);
      expect(find.textContaining('الخدمة متاحة في مدينة نصر'), findsOneWidget);
    });

    testWidgets('a custom label is required when "أخرى" is chosen', (
      tester,
    ) async {
      final repo = await _pump(tester, const AddressFormScreen());
      await tester.tap(find.byKey(const Key('address-confirm-pin')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('أخرى'));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('address-save')));
      await tester.tap(find.byKey(const Key('address-save')));
      await tester.pump();

      expect(repo.lastSaved, isNull);
      expect(find.text('اكتب اسمًا للعنوان'), findsOneWidget);
    });
  });
}
