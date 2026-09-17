import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/maps/geo_point.dart';
import '../models/location_models.dart';

/// Coverage and addresses (0032). Customers write addresses only through the
/// rpc_* functions — the server validates, resolves the service area and
/// keeps exactly one default. Admins maintain cities and service areas with
/// plain table writes, which RLS restricts to admins.
abstract class LocationsRepository {
  /// Admins see every country (RLS); customers only active ones.
  Future<List<Country>> getCountries();

  Future<List<City>> getCities({bool activeOnly = true});

  Future<List<ServiceArea>> getServiceAreas(
    String cityId, {
    bool activeOnly = true,
  });

  Future<ServiceAvailability> checkAvailability(String cityId, GeoPoint point);

  Future<List<CustomerAddress>> getMyAddresses();

  Future<SavedAddressResult> saveMyAddress(AddressInput input);

  Future<void> setDefaultAddress(String addressId);

  Future<void> deleteMyAddress(String addressId);

  Future<String?> getMyCityId();

  Future<void> setMyCity(String? cityId);

  // Admin
  Future<void> createCity({
    required String countryId,
    required String nameAr,
    String? nameEn,
    required GeoPoint center,
  });

  Future<void> setCityActive(String cityId, bool isActive);

  Future<void> saveServiceArea({
    String? id,
    required String cityId,
    required String nameAr,
    required GeoPoint center,
    required double radiusKm,
    required bool isActive,
    String? notes,
  });
}

class SupabaseLocationsRepository implements LocationsRepository {
  final SupabaseClient _client;
  SupabaseLocationsRepository(this._client);

  @override
  Future<List<Country>> getCountries() async {
    try {
      final rows = await _client
          .from('countries')
          .select()
          .order('sort_order')
          .order('name_ar');
      return rows.map(Country.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<City>> getCities({bool activeOnly = true}) async {
    try {
      var query = _client.from('cities').select();
      if (activeOnly) query = query.eq('is_active', true);
      final rows = await query.order('sort_order').order('name_ar');
      return rows.map(City.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<ServiceArea>> getServiceAreas(
    String cityId, {
    bool activeOnly = true,
  }) async {
    try {
      var query = _client.from('service_areas').select().eq('city_id', cityId);
      if (activeOnly) query = query.eq('is_active', true);
      final rows = await query.order('name_ar');
      return rows.map(ServiceArea.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<ServiceAvailability> checkAvailability(
    String cityId,
    GeoPoint point,
  ) async {
    try {
      final p = point.rounded();
      final res = await _client.rpc(
        'rpc_check_service_availability',
        params: {
          'p_city_id': cityId,
          'p_latitude': p.latitude,
          'p_longitude': p.longitude,
        },
      );
      return ServiceAvailability.fromRpc(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<CustomerAddress>> getMyAddresses() async {
    try {
      // RLS returns only the caller's live addresses.
      final rows = await _client
          .from('customer_addresses')
          .select('*, cities(name_ar), service_areas(name_ar)')
          .eq('is_active', true)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      return rows.map(CustomerAddress.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<SavedAddressResult> saveMyAddress(AddressInput input) async {
    String? blank(String? v) => (v == null || v.trim().isEmpty) ? null : v;
    try {
      final p = input.location.rounded();
      final res = await _client.rpc(
        'rpc_save_my_address',
        params: {
          'p_address_id': input.id,
          'p_city_id': input.cityId,
          'p_label': input.label,
          'p_address_line': input.addressLine,
          'p_latitude': p.latitude,
          'p_longitude': p.longitude,
          'p_building': blank(input.building),
          'p_floor': blank(input.floor),
          'p_apartment': blank(input.apartment),
          'p_landmark': blank(input.landmark),
          'p_recipient_name': blank(input.recipientName),
          'p_phone': blank(input.phone),
          'p_make_default': input.makeDefault,
        },
      );
      final json = Map<String, dynamic>.from(res as Map);
      return SavedAddressResult(
        id: json['id'] as String,
        availability: ServiceAvailability.fromRpc(json),
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> setDefaultAddress(String addressId) async {
    try {
      await _client.rpc(
        'rpc_set_default_address',
        params: {'p_address_id': addressId},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> deleteMyAddress(String addressId) async {
    try {
      await _client.rpc(
        'rpc_delete_my_address',
        params: {'p_address_id': addressId},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<String?> getMyCityId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client
          .from('customers')
          .select('city_id')
          .eq('id', uid)
          .maybeSingle();
      return row?['city_id'] as String?;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> setMyCity(String? cityId) async {
    try {
      await _client.rpc('rpc_set_my_city', params: {'p_city_id': cityId});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> createCity({
    required String countryId,
    required String nameAr,
    String? nameEn,
    required GeoPoint center,
  }) async {
    try {
      final c = center.rounded();
      await _client.from('cities').insert({
        'country_id': countryId,
        'name_ar': nameAr.trim(),
        'name_en': (nameEn == null || nameEn.trim().isEmpty)
            ? null
            : nameEn.trim(),
        'center_latitude': c.latitude,
        'center_longitude': c.longitude,
        // New cities start off: an admin switches one on once it has areas.
        'is_active': false,
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> setCityActive(String cityId, bool isActive) async {
    try {
      await _client
          .from('cities')
          .update({'is_active': isActive})
          .eq('id', cityId);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> saveServiceArea({
    String? id,
    required String cityId,
    required String nameAr,
    required GeoPoint center,
    required double radiusKm,
    required bool isActive,
    String? notes,
  }) async {
    try {
      final c = center.rounded();
      final row = {
        'city_id': cityId,
        'name_ar': nameAr.trim(),
        'center_latitude': c.latitude,
        'center_longitude': c.longitude,
        'radius_km': double.parse(radiusKm.toStringAsFixed(2)),
        'is_active': isActive,
        'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      };
      if (id == null) {
        await _client.from('service_areas').insert(row);
      } else {
        await _client.from('service_areas').update(row).eq('id', id);
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
