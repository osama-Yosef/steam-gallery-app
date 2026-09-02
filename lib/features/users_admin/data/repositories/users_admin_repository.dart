import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/data/models/app_user.dart';

abstract class UsersAdminRepository {
  /// Admin-only listing — RLS lets an admin read every row of `users`
  /// (see 0011_rls_policies.sql), everyone else only their own.
  Future<List<AppUser>> listUsers({String? search, AppRole? roleFilter});

  Future<void> setRole(String userId, AppRole role);

  Future<void> setActive(String userId, bool isActive);

  /// Calls the create-user Edge Function — the only place a
  /// technician/admin account is ever created (see
  /// supabase/functions/create-user). Never touches the service role key
  /// directly; the function itself verifies the caller is an admin.
  Future<String> createTechnicianOrAdmin({
    required String localPhone,
    required String password,
    required String fullName,
    required AppRole role,
    String? employeeCode,
  });
}

class SupabaseUsersAdminRepository implements UsersAdminRepository {
  final SupabaseClient _client;
  SupabaseUsersAdminRepository(this._client);

  @override
  Future<List<AppUser>> listUsers({String? search, AppRole? roleFilter}) async {
    try {
      var query = _client.from('users').select();
      if (roleFilter != null) query = query.eq('role', roleFilter.name);
      if (search != null && search.trim().isNotEmpty) {
        query = query.or('full_name.ilike.%${search.trim()}%,phone.ilike.%${search.trim()}%');
      }
      final rows = await query.order('created_at', ascending: false);
      return rows.map(AppUser.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> setRole(String userId, AppRole role) async {
    try {
      await _client.rpc('rpc_admin_set_role', params: {'p_user_id': userId, 'p_new_role': role.name});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> setActive(String userId, bool isActive) async {
    try {
      await _client.rpc('rpc_admin_set_active', params: {'p_user_id': userId, 'p_is_active': isActive});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<String> createTechnicianOrAdmin({
    required String localPhone,
    required String password,
    required String fullName,
    required AppRole role,
    String? employeeCode,
  }) async {
    try {
      final res = await _client.functions.invoke('create-user', body: {
        'phone': localPhone,
        'password': password,
        'full_name': fullName,
        'role': role.name,
        if (employeeCode != null && employeeCode.isNotEmpty) 'employee_code': employeeCode,
      });
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw AppException(data['error'].toString());
      }
      return (data as Map)['user_id'] as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
