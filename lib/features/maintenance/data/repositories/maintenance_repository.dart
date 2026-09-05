import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/maintenance_image.dart';
import '../models/maintenance_request.dart';
import '../models/queue_position.dart';
import '../models/technician_option.dart';

abstract class MaintenanceRepository {
  Future<String> createRequest({
    required String customerId,
    required String customerName,
    required String phone,
    String? address,
    double? latitude,
    double? longitude,
    String? deviceType,
    required String problemDescription,
    String? notes,
  });

  /// A customer's own requests (any status — history + active).
  Stream<List<MaintenanceRequest>> watchMyRequests(String customerId);

  Stream<MaintenanceRequest?> watchRequest(String requestId);

  /// Every row currently visible to the caller via RLS — for a customer
  /// that's only their own; for a technician it's waiting ones + their own
  /// assignments; for an admin it's everything. Callers filter/sort this
  /// client-side to build the active queue (see docs/03-business-logic.md §5).
  Stream<List<MaintenanceRequest>> watchVisibleRequests();

  /// Accurate global queue position for one request — bypasses the
  /// customer's own row-level RLS restriction server-side (SECURITY DEFINER)
  /// without ever exposing any other customer's data (see rpc_my_maintenance_position).
  Future<QueuePosition> myQueuePosition(String requestId);

  Future<List<MaintenanceImage>> getImages(String requestId);
  Future<MaintenanceImage> uploadImage(String requestId, String ownerCustomerId, Uint8List bytes, String ext);

  /// The `maintenance` bucket is private (a customer's photos must not be
  /// readable by anyone holding the URL — see 0012_storage_buckets_policies),
  /// so images can only be displayed through a short-lived signed URL.
  /// Accepts either a stored object path or a legacy public/signed URL.
  Future<String> signedImageUrl(String storedPathOrUrl);

  Future<void> assign(String requestId, String technicianId);
  /// Lets a technician take a waiting job themselves instead of waiting for
  /// an admin to assign it. Throws REQUEST_NOT_WAITING if someone else got
  /// there first.
  Future<void> claim(String requestId);

  Future<void> start(String requestId);
  Future<void> complete(String requestId, String? notes);
  Future<void> cancel(String requestId, String reason);

  Future<List<TechnicianOption>> listTechnicians();
}

class SupabaseMaintenanceRepository implements MaintenanceRepository {
  final SupabaseClient _client;
  SupabaseMaintenanceRepository(this._client);

  @override
  Future<String> createRequest({
    required String customerId,
    required String customerName,
    required String phone,
    String? address,
    double? latitude,
    double? longitude,
    String? deviceType,
    required String problemDescription,
    String? notes,
  }) async {
    try {
      final id = await _client.rpc('rpc_create_maintenance_request', params: {
        'p_customer_id': customerId,
        'p_customer_name': customerName,
        'p_phone': phone,
        'p_address': address,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_device_type': deviceType,
        'p_problem_description': problemDescription,
        'p_notes': notes,
      });
      return id as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Stream<List<MaintenanceRequest>> watchMyRequests(String customerId) {
    return _client
        .from('maintenance_requests')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(MaintenanceRequest.fromRow).toList());
  }

  @override
  Stream<MaintenanceRequest?> watchRequest(String requestId) {
    return _client
        .from('maintenance_requests')
        .stream(primaryKey: ['id'])
        .eq('id', requestId)
        .map((rows) => rows.isEmpty ? null : MaintenanceRequest.fromRow(rows.first));
  }

  @override
  Stream<List<MaintenanceRequest>> watchVisibleRequests() {
    return _client
        .from('maintenance_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((rows) => rows.map(MaintenanceRequest.fromRow).toList());
  }

  @override
  Future<QueuePosition> myQueuePosition(String requestId) async {
    try {
      final rows = await _client.rpc('rpc_my_maintenance_position', params: {'p_request_id': requestId});
      final row = (rows as List).first as Map<String, dynamic>;
      return QueuePosition.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<MaintenanceImage>> getImages(String requestId) async {
    try {
      final rows = await _client
          .from('maintenance_images')
          .select()
          .eq('maintenance_request_id', requestId)
          .order('uploaded_at');
      return rows.map(MaintenanceImage.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<MaintenanceImage> uploadImage(
    String requestId,
    String ownerCustomerId,
    Uint8List bytes,
    String ext,
  ) async {
    try {
      // Path convention enforced by storage RLS: {customer_id}/{request_id}/{file}
      final path = '$ownerCustomerId/$requestId/${const Uuid().v4()}.$ext';
      await _client.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      // Store the object PATH, not getPublicUrl(): this bucket is private, so
      // a public URL is permanently unloadable (it renders as a broken image).
      // Display goes through signedImageUrl() instead.
      final row = await _client
          .from('maintenance_images')
          .insert({'maintenance_request_id': requestId, 'image_url': path})
          .select()
          .single();
      return MaintenanceImage.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  static const _bucket = 'maintenance';

  /// Rows written before the fix hold a full public URL; newer ones hold a
  /// bare object path. Normalise both to the path the storage API wants.
  static String _objectPath(String stored) {
    for (final marker in const ['/object/public/$_bucket/', '/object/sign/$_bucket/']) {
      final i = stored.indexOf(marker);
      if (i != -1) return stored.substring(i + marker.length).split('?').first;
    }
    return stored;
  }

  @override
  Future<String> signedImageUrl(String storedPathOrUrl) async {
    try {
      return await _client.storage.from(_bucket).createSignedUrl(
            _objectPath(storedPathOrUrl),
            const Duration(hours: 1).inSeconds,
          );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> assign(String requestId, String technicianId) async {
    try {
      await _client.rpc('rpc_assign_maintenance', params: {
        'p_request_id': requestId,
        'p_technician_id': technicianId,
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> claim(String requestId) async {
    try {
      await _client.rpc('rpc_claim_maintenance', params: {'p_request_id': requestId});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> start(String requestId) async {
    try {
      await _client.rpc('rpc_start_maintenance', params: {'p_request_id': requestId});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> complete(String requestId, String? notes) async {
    try {
      await _client.rpc('rpc_complete_maintenance', params: {'p_request_id': requestId, 'p_notes': notes});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> cancel(String requestId, String reason) async {
    try {
      await _client.rpc('rpc_cancel_maintenance', params: {'p_request_id': requestId, 'p_reason': reason});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<TechnicianOption>> listTechnicians() async {
    try {
      final rows = await _client
          .from('technicians')
          .select('id, employee_code, users!technicians_id_fkey(full_name)')
          .eq('is_active', true);
      return rows.map(TechnicianOption.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
