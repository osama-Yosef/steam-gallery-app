import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/maps/geo_point.dart';

part 'location_models.freezed.dart';

double _num(Object? v) => (v as num).toDouble();

@freezed
abstract class City with _$City {
  const factory City({
    required String id,
    required String countryId,
    required String nameAr,
    String? nameEn,
    required GeoPoint center,
    required bool isActive,
    required int sortOrder,
  }) = _City;

  factory City.fromRow(Map<String, dynamic> row) => City(
    id: row['id'] as String,
    countryId: row['country_id'] as String,
    nameAr: row['name_ar'] as String,
    nameEn: row['name_en'] as String?,
    center: GeoPoint(
      _num(row['center_latitude']),
      _num(row['center_longitude']),
    ),
    isActive: row['is_active'] as bool? ?? false,
    sortOrder: row['sort_order'] as int? ?? 0,
  );
}

/// A circle of coverage inside a city (0032).
@freezed
abstract class ServiceArea with _$ServiceArea {
  const ServiceArea._();

  const factory ServiceArea({
    required String id,
    required String cityId,
    required String nameAr,
    required GeoPoint center,
    required double radiusKm,
    required bool isActive,
    String? notes,
  }) = _ServiceArea;

  factory ServiceArea.fromRow(Map<String, dynamic> row) => ServiceArea(
    id: row['id'] as String,
    cityId: row['city_id'] as String,
    nameAr: row['name_ar'] as String,
    center: GeoPoint(
      _num(row['center_latitude']),
      _num(row['center_longitude']),
    ),
    radiusKm: _num(row['radius_km']),
    isActive: row['is_active'] as bool? ?? true,
    notes: row['notes'] as String?,
  );

  MapCircle toCircle({bool? emphasized}) => MapCircle(
    center: center,
    radiusKm: radiusKm,
    emphasized: emphasized ?? isActive,
  );
}

/// The server's answer to "is this point covered?" — from
/// rpc_check_service_availability or rpc_save_my_address. The app never
/// works this out itself.
@freezed
abstract class ServiceAvailability with _$ServiceAvailability {
  const factory ServiceAvailability({
    required bool available,
    String? serviceAreaId,
    String? serviceAreaName,
  }) = _ServiceAvailability;

  // Not `fromJson`: freezed would expect json_serializable codegen for it.
  factory ServiceAvailability.fromRpc(Map<String, dynamic> json) =>
      ServiceAvailability(
        available: json['available'] as bool? ?? false,
        serviceAreaId: json['service_area_id'] as String?,
        serviceAreaName: json['service_area_name'] as String?,
      );
}

@freezed
abstract class CustomerAddress with _$CustomerAddress {
  const CustomerAddress._();

  const factory CustomerAddress({
    required String id,
    required String cityId,
    String? cityName,
    String? serviceAreaId,
    String? serviceAreaName,
    required String label,
    String? recipientName,
    String? phone,
    required String addressLine,
    String? building,
    String? floor,
    String? apartment,
    String? landmark,
    required GeoPoint location,
    required bool isDefault,
  }) = _CustomerAddress;

  /// Row from customer_addresses with `cities(name_ar)` and
  /// `service_areas(name_ar)` embedded.
  factory CustomerAddress.fromRow(Map<String, dynamic> row) {
    final city = row['cities'];
    final area = row['service_areas'];
    return CustomerAddress(
      id: row['id'] as String,
      cityId: row['city_id'] as String,
      cityName: city is Map ? city['name_ar'] as String? : null,
      serviceAreaId: row['service_area_id'] as String?,
      serviceAreaName: area is Map ? area['name_ar'] as String? : null,
      label: row['label'] as String,
      recipientName: row['recipient_name'] as String?,
      phone: row['phone'] as String?,
      addressLine: row['address_line'] as String,
      building: row['building'] as String?,
      floor: row['floor'] as String?,
      apartment: row['apartment'] as String?,
      landmark: row['landmark'] as String?,
      location: GeoPoint(_num(row['latitude']), _num(row['longitude'])),
      isDefault: row['is_default'] as bool? ?? false,
    );
  }

  /// Covered by an active service area, as last resolved by the server.
  bool get isServiceable => serviceAreaId != null;

  /// "عمارة 12، الدور 3، شقة 7" — only the parts that were filled in.
  String get detailsLine => [
    if (building != null) 'عمارة $building',
    if (floor != null) 'الدور $floor',
    if (apartment != null) 'شقة $apartment',
  ].join('، ');
}

/// Everything the customer can set on an address. [id] null = new.
class AddressInput {
  final String? id;
  final String cityId;
  final String label;
  final String addressLine;
  final GeoPoint location;
  final String? building;
  final String? floor;
  final String? apartment;
  final String? landmark;
  final String? recipientName;
  final String? phone;
  final bool makeDefault;

  const AddressInput({
    this.id,
    required this.cityId,
    required this.label,
    required this.addressLine,
    required this.location,
    this.building,
    this.floor,
    this.apartment,
    this.landmark,
    this.recipientName,
    this.phone,
    this.makeDefault = false,
  });
}

class SavedAddressResult {
  final String id;
  final ServiceAvailability availability;
  const SavedAddressResult({required this.id, required this.availability});
}

@freezed
abstract class Country with _$Country {
  const factory Country({
    required String id,
    required String isoCode,
    required String nameAr,
    required bool isActive,
  }) = _Country;

  factory Country.fromRow(Map<String, dynamic> row) => Country(
    id: row['id'] as String,
    isoCode: row['iso_code'] as String,
    nameAr: row['name_ar'] as String,
    isActive: row['is_active'] as bool? ?? false,
  );
}
