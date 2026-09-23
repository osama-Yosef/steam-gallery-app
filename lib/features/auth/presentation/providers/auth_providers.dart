import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/firebase/firebase_phone_auth_service.dart';
import '../../../../core/firebase/push_notification_service.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/app_user.dart';
import '../../data/models/auth_settings.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
}

/// One instance per app run: it only holds the in-flight verification ID
/// between "send code" and "confirm code", which is meaningless to keep
/// beyond a single verification attempt anyway.
@Riverpod(keepAlive: true)
PhoneAuthService firebasePhoneAuthService(Ref ref) {
  return FirebasePhoneAuthService();
}

@Riverpod(keepAlive: true)
PushNotificationService pushNotificationService(Ref ref) {
  return PushNotificationService();
}

/// Keeps this device's push token registered against whichever account is
/// signed in. Watched once, for its whole lifetime, from appRouterProvider
/// (see core/router/app_router.dart) — registering is fire-and-forget, a
/// failure here must never block navigation or sign-in.
@Riverpod(keepAlive: true)
class PushTokenSync extends _$PushTokenSync {
  @override
  void build() {
    // Firebase Messaging has no web/desktop wiring in this app (see
    // main.dart) — touching FirebaseMessaging.instance there throws.
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    final service = ref.watch(pushNotificationServiceProvider);
    final repo = ref.watch(authRepositoryProvider);

    ref.listen(currentUserProfileProvider, (_, next) {
      if (next.value != null) _register(service, repo);
    }, fireImmediately: true);

    final sub = service.onTokenRefresh.listen((_) => _register(service, repo));
    ref.onDispose(sub.cancel);
  }

  Future<void> _register(
    PushNotificationService service,
    AuthRepository repo,
  ) async {
    if (repo.currentSession == null) return;
    try {
      final token = await service.getToken();
      if (token != null) await repo.updateFcmToken(token);
    } catch (_) {}
  }
}

/// Re-fetches the profile row whenever the Supabase auth session changes
/// (sign in / sign out / token refresh). The router watches this to decide
/// which shell (admin/technician/customer/login) to show.
@Riverpod(keepAlive: true)
Future<AppUser?> currentUserProfile(Ref ref) async {
  ref.watch(authStateChangesProvider); // re-run on every auth event
  final repo = ref.watch(authRepositoryProvider);
  return repo.getMyProfile();
}

/// Server auth switches, refreshed on every auth event. Falls back to
/// [AuthSettings.unknown] rather than failing: the database enforces the real
/// rule either way, this only picks the screen.
@Riverpod(keepAlive: true)
Future<AuthSettings> authSettings(Ref ref) async {
  ref.watch(authStateChangesProvider);
  final repo = ref.watch(authRepositoryProvider);
  if (repo.currentSession == null) return AuthSettings.unknown;
  try {
    return await repo.getAuthSettings();
  } catch (_) {
    return AuthSettings.unknown;
  }
}

@riverpod
Future<AppUser?> userProfileById(Ref ref, String userId) {
  return ref.watch(authRepositoryProvider).getProfileById(userId);
}

enum OtpPurpose {
  /// Confirming the phone of an account created before 0070 (legacy —
  /// see AuthRepository's class doc). New sign-ups use [emailSignup].
  signup,

  /// Signing in by an emailed code to set a new password (0070 — Supabase's
  /// own free email recovery, replacing the Firebase-phone version that
  /// turned out to need Firebase's paid Blaze plan for real numbers).
  passwordRecovery,

  /// Confirming the email of an account that was just created (0070).
  emailSignup,

  /// An existing (pre-0070, phone-only) account adding and confirming the
  /// email it never had.
  emailChange,
}

/// What the OTP screen is verifying. Held in memory — never in the URL,
/// which would put the phone/email in browser history and server logs.
class OtpRequest {
  /// A phone number (E.164) or an email address, matching [purpose].
  final String destination;
  final OtpPurpose purpose;

  /// Photo picked at sign-up; uploaded once the verified session exists.
  final Uint8List? avatarBytes;
  final String? avatarExt;

  const OtpRequest({
    required this.destination,
    required this.purpose,
    this.avatarBytes,
    this.avatarExt,
  });
}

@Riverpod(keepAlive: true)
class PendingOtp extends _$PendingOtp {
  @override
  OtpRequest? build() => null;

  void start(OtpRequest request) => state = request;

  void clear() => state = null;
}

/// True from the moment a password-recovery code is submitted until the new
/// password is saved (or the user backs out). Verifying the code signs the
/// user in, and without this the router would send them straight home,
/// skipping the new-password screen.
@Riverpod(keepAlive: true)
class PasswordRecovery extends _$PasswordRecovery {
  @override
  bool build() => false;

  void begin() => state = true;

  void end() => state = false;
}
