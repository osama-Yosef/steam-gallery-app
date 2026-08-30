import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../models/app_user.dart';

abstract class AuthRepository {
  Session? get currentSession;

  Future<void> signInWithPhone({required String localPhone, required String password});

  /// role is always 'customer' here — technician/admin accounts are only
  /// ever created by an existing admin via the create-user Edge Function
  /// (see docs/04-security-architecture.md §1). This app never lets anyone
  /// self-register as technician or admin.
  Future<void> signUpCustomer({
    required String localPhone,
    required String password,
    required String fullName,
  });

  Future<void> signOut();

  Future<AppUser?> getMyProfile();

  /// Admin/technician lookup of another user's profile — e.g. showing a
  /// customer's name on an order or maintenance ticket. RLS still governs
  /// what's actually visible: an admin sees anyone, a technician only
  /// customers tied to work assigned to them (see 0011_rls_policies.sql).
  Future<AppUser?> getProfileById(String userId);
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  SupabaseAuthRepository(this._client);

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Future<void> signInWithPhone({required String localPhone, required String password}) async {
    try {
      await _client.auth.signInWithPassword(
        phone: Validators.toE164Egypt(localPhone),
        password: password,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> signUpCustomer({
    required String localPhone,
    required String password,
    required String fullName,
  }) async {
    try {
      await _client.auth.signUp(
        phone: Validators.toE164Egypt(localPhone),
        password: password,
        data: {'full_name': fullName},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<AppUser?> getMyProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client.from('users').select().eq('id', uid).maybeSingle();
      if (row == null) return null;
      return AppUser.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<AppUser?> getProfileById(String userId) async {
    try {
      final row = await _client.from('users').select().eq('id', userId).maybeSingle();
      return row == null ? null : AppUser.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
