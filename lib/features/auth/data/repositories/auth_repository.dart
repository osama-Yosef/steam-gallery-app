import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../models/app_user.dart';
import '../models/auth_settings.dart';

/// Customer sign-up/sign-in is by email+password (0070): Supabase's own
/// email OTP (confirmation + password recovery) is free and, unlike phone,
/// actually requires and checks a real code (mailer_autoconfirm is off).
/// Phone is still collected and required at sign-up but only as contact
/// info now — never an Auth identifier, never SMS-verified. Staff
/// (admin/technician/sales) are unaffected: created by an admin via the
/// create-user Edge Function, still phone+password. The older
/// phone-OTP-at-signup and Firebase-phone-recovery paths below are kept for
/// any account created before 0070 that's still mid-flow on them, but are
/// no longer how anyone signs up. See docs/09-phase-2-authentication.md.
abstract class AuthRepository {
  Session? get currentSession;

  Future<void> signInWithPhone({
    required String localPhone,
    required String password,
  });

  /// Marks the signed-in user's phone verified from a Firebase-issued
  /// verification (see core/firebase/firebase_phone_auth_service.dart),
  /// bypassing Supabase's own (paid) SMS delivery. Calls the
  /// verify-phone-firebase Edge Function, which checks the token's signature
  /// server-side before trusting it.
  Future<void> markPhoneVerifiedWithFirebaseToken(String firebaseIdToken);

  /// Resets the password of the account owning the phone [firebaseIdToken]
  /// just proved, with no Supabase session required — this IS the
  /// forgot-password flow once Firebase has replaced Supabase's SMS OTP for
  /// it. Throws if the token is invalid/expired or no account has that phone.
  Future<void> resetPasswordWithFirebaseToken({
    required String firebaseIdToken,
    required String newPassword,
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

  // --------------------------------------------------------------------
  // Email auth (0070) — the customer sign-up path from here on. Phone is
  // still collected and required, but only as contact/delivery info now:
  // never an Auth identifier, never SMS-verified (see 0067–0069, the paid
  // and non-functional dead end that was). Email confirmation and password
  // recovery are both native Supabase Auth features — free, and (unlike
  // sms_autoconfirm) a real code that's actually checked.
  // --------------------------------------------------------------------

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  /// Always requires verification — mailer_autoconfirm is off — so unlike
  /// [signUpCustomer] this has no session-created-immediately case.
  /// [localPhone] is stored as contact info only (see class doc).
  Future<void> signUpCustomerWithEmail({
    required String email,
    required String localPhone,
    required String password,
    required String fullName,
    Uint8List? avatarBytes,
    String? avatarExt,
  });

  Future<void> resendSignupEmailOtp(String email);

  Future<void> verifySignupEmailOtp({
    required String email,
    required String code,
    Uint8List? avatarBytes,
    String? avatarExt,
  });

  /// Existing phone-only account (created before 0070) adding the email it
  /// never had. Supabase mails a code to confirm; nothing changes until
  /// [verifyEmailChangeOtp] checks it.
  Future<void> addEmailToAccount(String email);

  Future<void> verifyEmailChangeOtp({
    required String email,
    required String code,
  });

  /// Sends a recovery code to an EXISTING account's email. Deliberately
  /// silent when the address isn't registered, so the screen can't be used
  /// to discover which addresses have accounts.
  Future<void> sendPasswordRecoveryEmail(String email);

  /// Signs in with a code from [sendPasswordRecoveryEmail].
  Future<void> verifyRecoveryEmailOtp({
    required String email,
    required String code,
  });

  /// Sets a new password for the signed-in user and ends every other session
  /// (a reset usually means someone else might know the old one).
  Future<void> updatePassword(String newPassword);

  /// Registers (or clears, with null) this device's push token against the
  /// signed-in user — see core/firebase/push_notification_service.dart. Best
  /// effort: a failure here must never block sign-in.
  Future<void> updateFcmToken(String? token);

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
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> signUpCustomerWithEmail({
    required String email,
    required String localPhone,
    required String password,
    required String fullName,
    Uint8List? avatarBytes,
    String? avatarExt,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': Validators.toE164Egypt(localPhone),
        },
      );
      // mailer_autoconfirm is off: this never returns a session — the
      // caller always continues to the email-OTP screen with avatarBytes.
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> resendSignupEmailOtp(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> verifySignupEmailOtp({
    required String email,
    required String code,
    Uint8List? avatarBytes,
    String? avatarExt,
  }) async {
    try {
      await _client.auth.verifyOTP(email: email, token: code, type: OtpType.signup);
    } catch (e) {
      throw AppException.from(e);
    }
    try {
      await _uploadAvatarIfAny(avatarBytes, avatarExt);
    } catch (_) {}
  }

  @override
  Future<void> addEmailToAccount(String email) async {
    try {
      await _client.auth.updateUser(UserAttributes(email: email));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> verifyEmailChangeOtp({
    required String email,
    required String code,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.emailChange,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> sendPasswordRecoveryEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      // "No such user" must look exactly like success — see class doc.
      if (_isUnknownAccount(e)) return;
      throw AppException.from(e);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> verifyRecoveryEmailOtp({
    required String email,
    required String code,
  }) async {
    try {
      await _client.auth.verifyOTP(email: email, token: code, type: OtpType.recovery);
    } catch (e) {
      throw AppException.from(e);
    }
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

  static bool _isUnknownAccount(AuthException e) {
    final code = e.code;
    if (code == 'user_not_found') return true;
    return e.message.toLowerCase().contains('user not found');
  }

  @override
  Future<void> markPhoneVerifiedWithFirebaseToken(String firebaseIdToken) async {
    try {
      await _client.functions.invoke(
        'verify-phone-firebase',
        body: {'firebase_id_token': firebaseIdToken, 'intent': 'mark_verified'},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> resetPasswordWithFirebaseToken({
    required String firebaseIdToken,
    required String newPassword,
  }) async {
    try {
      await _client.functions.invoke(
        'verify-phone-firebase',
        body: {
          'firebase_id_token': firebaseIdToken,
          'intent': 'reset_password',
          'new_password': newPassword,
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> updateFcmToken(String? token) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client.from('users').update({'fcm_token': token}).eq('id', uid);
    } catch (e) {
      throw AppException.from(e);
    }
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
    // Best-effort, and must happen before the session ends (RLS needs
    // auth.uid()) — otherwise this device keeps whoever signs in next on
    // this account's old push registration indefinitely.
    try {
      await updateFcmToken(null);
    } catch (_) {}
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
