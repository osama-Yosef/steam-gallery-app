import '../../features/auth/data/models/app_user.dart';
import 'route_names.dart';

/// Where the signed-in user's profile fetch stands.
enum ProfileStatus {
  /// Loaded and present.
  ready,

  /// Still loading, with nothing cached yet.
  loading,

  /// Loaded, but no row — the sign-up trigger may still be provisioning it.
  missing,

  /// Failed to load.
  error,
}

/// Screens reachable without a session.
const _publicRoutes = {
  Routes.login,
  Routes.register,
  Routes.forgotPassword,
  Routes.verifyOtp,
};

/// Screens that only exist to get a signed-in user somewhere else; once
/// nothing holds them there, they go home.
const _transitRoutes = {
  ..._publicRoutes,
  Routes.splash,
  Routes.resetPassword,
  Routes.verifyPhone,
  Routes.accountSuspended,
};

/// Every routing decision that depends on who is signed in, as a pure
/// function so each rule is testable (test/auth_redirect_test.dart).
///
/// This decides which SCREEN to show. It is not the security boundary: RLS
/// and the rpc_* checks refuse the same things server-side (an inactive
/// account, an unverified customer, a customer calling an admin function)
/// even if a route were reached some other way.
String? resolveAuthRedirect({
  required String location,
  required bool hasSession,
  required ProfileStatus profileStatus,
  AppUser? user,
  required bool requireVerifiedPhone,
  required bool passwordRecoveryInProgress,
}) {
  if (!hasSession) {
    return _publicRoutes.contains(location) ? null : Routes.login;
  }

  // Signed in by a recovery code: the only place to be is the new-password
  // screen, whatever the profile says.
  if (passwordRecoveryInProgress) {
    return location == Routes.resetPassword ? null : Routes.resetPassword;
  }

  if (user == null) {
    return switch (profileStatus) {
      ProfileStatus.error => Routes.login,
      _ => location == Routes.splash ? null : Routes.splash,
    };
  }

  if (!user.isActive) {
    return location == Routes.accountSuspended ? null : Routes.accountSuspended;
  }

  if (requireVerifiedPhone &&
      user.role == AppRole.customer &&
      !user.isPhoneVerified) {
    return location == Routes.verifyPhone ? null : Routes.verifyPhone;
  }

  final home = homeFor(user.role);
  if (_transitRoutes.contains(location)) return home;

  // A role only ever sees its own area. Hiding the navigation isn't enough:
  // on web a URL can be typed straight in.
  final areaRole = _areaRole(location);
  if (areaRole != null && areaRole != user.role) return home;

  return null;
}

String homeFor(AppRole role) => switch (role) {
  AppRole.admin => Routes.adminHome,
  AppRole.technician => Routes.technicianHome,
  AppRole.customer => Routes.customerHome,
};

AppRole? _areaRole(String location) {
  bool inArea(String root) => location == root || location.startsWith('$root/');
  if (inArea(Routes.adminHome)) return AppRole.admin;
  if (inArea(Routes.technicianHome)) return AppRole.technician;
  if (inArea(Routes.customerHome)) return AppRole.customer;
  return null;
}
