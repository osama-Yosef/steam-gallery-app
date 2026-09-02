import 'dart:typed_data';
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
  /// self-register as technician or admin. [avatarBytes] is optional — the
  /// photo picker at sign-up is never required.
  Future<void> signUpCustomer({
    required String localPhone,
    required String password,
    required String fullName,
    Uint8List? avatarBytes,
    String? avatarExt,
  });

  Future<void> signOut();

  Future<AppUser?> getMyProfile();

  /// Admin/technician lookup of another user's profile — e.g. showing a
  /// customer's name on an order or maintenance ticket. RLS still governs
  /// what's actually visible: an admin sees anyone, a technician only
  /// customers tied to work assigned to them (see 0011_rls_policies.sql).
  Future<AppUser?> getProfileById(String userId);

  /// Self profile edit — name and/or photo, either may be omitted. RLS
  /// (0011_rls_policies.sql) already restricts the update to exactly these
  /// two columns on the caller's own row.
  Future<void> updateMyProfile({String? fullName, Uint8List? avatarBytes, String? avatarExt});
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
    Uint8List? avatarBytes,
    String? avatarExt,
  }) async {
    try {
      await _client.auth.signUp(
        phone: Validators.toE164Egypt(localPhone),
        password: password,
        data: {'full_name': fullName},
      );
      // Storage RLS needs auth.uid(), which only exists once signUp has
      // actually created the session above — can't upload beforehand.
      if (avatarBytes != null && avatarExt != null) {
        final url = await _uploadAvatar(avatarBytes, avatarExt);
        await _client.from('users').update({'avatar_url': url}).eq('id', _client.auth.currentUser!.id);
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<String> _uploadAvatar(Uint8List bytes, String ext) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/avatar.$ext';
    await _client.storage.from('avatars').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  @override
  Future<void> updateMyProfile({String? fullName, Uint8List? avatarBytes, String? avatarExt}) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null && fullName.trim().isNotEmpty) updates['full_name'] = fullName.trim();
      if (avatarBytes != null && avatarExt != null) {
        updates['avatar_url'] = await _uploadAvatar(avatarBytes, avatarExt);
      }
      if (updates.isEmpty) return;
      await _client.from('users').update(updates).eq('id', _client.auth.currentUser!.id);
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
