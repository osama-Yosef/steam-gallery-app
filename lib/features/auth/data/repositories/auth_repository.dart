import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../models/app_user.dart';
import '../models/auth_settings.dart';

/// Every OTP here is generated, delivered (through the SMS provider configured
/// in Supabase Auth), expired, rate-limited and checked by Supabase Auth
/// itself — this app never sees or stores a code beyond passing the user's
/// input straight to verifyOTP. See docs/09-phase-2-authentication.md.
abstract class AuthRepository {
  Session? get currentSession;

  Future<void> signInWithPhone({
    required String localPhone,
    required String password,
  });

  /// role is always 'customer' here — technician/admin accounts are only
  /// ever created by an existing admin via the create-user Edge Function
  /// (see docs/04-security-architecture.md §1). This app never lets anyone
  /// self-register as technician or admin.
  ///
  /// Returns true when the phone still has to be verified by OTP ("Confirm
  /// phone" enabled — no session yet); false when Auth signed the user in
  /// straight away, in which case [avatarBytes] is uploaded immediately.
  Future<bool> signUpCustomer({
    required String localPhone,
    required String password,
    required String fullName,
    Uint8List? avatarBytes,
    String? avatarExt,
  });

  /// Re-sends the sign-up code for an account whose phone isn't confirmed.
  Future<void> resendSignupOtp(String phoneE164);

  /// Confirms a new account's phone and signs it in. [avatarBytes] (picked at
  /// sign-up, before any session existed to upload with) is uploaded after.
  Future<void> verifySignupOtp({
    required String phoneE164,
    required String code,
    Uint8List? avatarBytes,
    String? avatarExt,
  });

  /// Sends a one-time sign-in code to an EXISTING account (never creates
  /// one). Used by forgot-password and by existing accounts proving their
  /// number. Deliberately silent when the number isn't registered, so the
  /// screen can't be used to discover which numbers have accounts.
  Future<void> sendSignInOtp(String phoneE164);

  /// Signs in with a code from [sendSignInOtp] and records the phone as
  /// verified.
  Future<void> verifySignInOtp({
    required String phoneE164,
    required String code,
  });

  /// Sets a new password for the signed-in user and ends every other session
  /// (a reset usually means someone else might know the old one).
  Future<void> updatePassword(String newPassword);

  Future<AuthSettings> getAuthSettings();

  Future<void> signOut();

  Future<AppUser?> getMyProfile();

  /// Admin/technician lookup of another user's profile — e.g. showing a
  /// customer's name on an order or maintenance ticket. RLS still governs
  /// what's actually visible: an admin sees anyone, a technician only
  /// customers tied to work assigned to them (see 0011_rls_policies.sql).
  Future<AppUser?> getProfileById(String userId);

  /// Self profile edit — name and/or photo, either may be omitted. The
  /// column grant (0029) restricts client updates to exactly these two
  /// columns on the caller's own row.
  Future<void> updateMyProfile({
    String? fullName,
    Uint8List? avatarBytes,
    String? avatarExt,
  });
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  SupabaseAuthRepository(this._client);

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Future<void> signInWithPhone({
    required String localPhone,
    required String password,
  }) async {
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
  Future<bool> signUpCustomer({
    required String localPhone,
    required String password,
    required String fullName,
    Uint8List? avatarBytes,
    String? avatarExt,
  }) async {
    try {
      final res = await _client.auth.signUp(
        phone: Validators.toE164Egypt(localPhone),
        password: password,
        data: {'full_name': fullName},
      );
      if (res.session == null) return true;
      await _uploadAvatarIfAny(avatarBytes, avatarExt);
      return false;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> resendSignupOtp(String phoneE164) async {
    try {
      await _client.auth.resend(type: OtpType.sms, phone: phoneE164);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> verifySignupOtp({
    required String phoneE164,
    required String code,
    Uint8List? avatarBytes,
    String? avatarExt,
  }) async {
    try {
      await _client.auth.verifyOTP(
        phone: phoneE164,
        token: code,
        type: OtpType.sms,
      );
    } catch (e) {
      throw AppException.from(e);
    }
    await _markPhoneVerified();
    // The account exists and is signed in at this point; a failed photo
    // upload must not turn a successful sign-up into an error.
    try {
      await _uploadAvatarIfAny(avatarBytes, avatarExt);
    } catch (_) {}
  }

  @override
  Future<void> sendSignInOtp(String phoneE164) async {
    try {
      await _client.auth.signInWithOtp(
        phone: phoneE164,
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      // Rate limits and delivery failures are real and must be shown. "No
      // such user" must look exactly like success.
      if (_isUnknownAccount(e)) return;
      throw AppException.from(e);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> verifySignInOtp({
    required String phoneE164,
    required String code,
  }) async {
    try {
      await _client.auth.verifyOTP(
        phone: phoneE164,
        token: code,
        type: OtpType.sms,
      );
    } catch (e) {
      throw AppException.from(e);
    }
    await _markPhoneVerified();
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw AppException.from(e);
    }
    // The password is already changed; failing to end other sessions is not
    // a reason to tell the user the reset failed.
    try {
      await _client.auth.signOut(scope: SignOutScope.others);
    } catch (_) {}
  }

  @override
  Future<AuthSettings> getAuthSettings() async {
    try {
      final res = await _client.rpc('rpc_get_auth_settings');
      return AuthSettings.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Best effort: the server also marks the phone verified when Auth confirms
  /// it (while verification is required), and an account that still shows as
  /// unverified is simply asked to verify again — never locked out.
  Future<void> _markPhoneVerified() async {
    try {
      await _client.rpc('rpc_mark_phone_verified');
    } catch (_) {}
  }

  static bool _isUnknownAccount(AuthException e) {
    final code = e.code;
    if (code == 'user_not_found' || code == 'otp_disabled') return true;
    final m = e.message.toLowerCase();
    return m.contains('signups not allowed') || m.contains('user not found');
  }

  Future<void> _uploadAvatarIfAny(Uint8List? bytes, String? ext) async {
    if (bytes == null || ext == null) return;
    final url = await _uploadAvatar(bytes, ext);
    await _client
        .from('users')
        .update({'avatar_url': url})
        .eq('id', _client.auth.currentUser!.id);
  }

  Future<String> _uploadAvatar(Uint8List bytes, String ext) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/avatar.$ext';
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  @override
  Future<void> updateMyProfile({
    String? fullName,
    Uint8List? avatarBytes,
    String? avatarExt,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null && fullName.trim().isNotEmpty) {
        updates['full_name'] = fullName.trim();
      }
      if (avatarBytes != null && avatarExt != null) {
        updates['avatar_url'] = await _uploadAvatar(avatarBytes, avatarExt);
      }
      if (updates.isEmpty) return;
      await _client
          .from('users')
          .update(updates)
          .eq('id', _client.auth.currentUser!.id);
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
      final row = await _client
          .from('users')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return null;
      return AppUser.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<AppUser?> getProfileById(String userId) async {
    try {
      final row = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return row == null ? null : AppUser.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
