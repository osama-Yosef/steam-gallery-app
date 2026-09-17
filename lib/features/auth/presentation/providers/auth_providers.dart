import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/app_user.dart';
import '../../data/models/auth_settings.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
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
  /// Confirming the phone of an account that was just created.
  signup,

  /// Signing in by code to set a new password.
  passwordRecovery,
}

/// What the OTP screen is verifying. Held in memory — never in the URL, which
/// would put the phone number in browser history and server logs.
class OtpRequest {
  final String phoneE164;
  final OtpPurpose purpose;

  /// Photo picked at sign-up; uploaded once the verified session exists.
  final Uint8List? avatarBytes;
  final String? avatarExt;

  const OtpRequest({
    required this.phoneE164,
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
