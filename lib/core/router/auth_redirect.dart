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
  Routes.addEmail,
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
  String query = '',
}) {
  if (!hasSession) {
    return _publicRoutes.contains(location) ? null : Routes.login;
  }

  // Signed in by an email recovery code: the only place to be is the
  // new-password screen, whatever the profile says.
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

  // Every customer needs an email now (0070) — old phone-only accounts are
  // asked for one the first time they sign back in.
  if (user.role == AppRole.customer &&
      (user.email == null || user.email!.isEmpty)) {
    return location == Routes.addEmail ? null : Routes.addEmail;
  }

  final home = homeFor(user.role);
  if (_transitRoutes.contains(location)) return home;

  // A role only ever sees its own area. Hiding the navigation isn't enough:
  // on web a URL can be typed straight in.
  final areaRole = _areaRole(location);
  if (areaRole != null && areaRole != user.role) {
    // The admin screens sales shares link to admin paths: send each to its
    // /sales twin instead of bouncing home.
    if (user.role == AppRole.sales && areaRole == AppRole.admin) {
      final twin = salesPathFor(location, query: query);
      if (twin != null) return twin;
    }
    return home;
  }

  return null;
}

/// Admin path prefixes the sales role shares, and where they live under
/// /sales. Longest first, so `/admin/expenses/categories` is never taken
/// for `/admin/expenses`.
const _salesTwins = <(String, String?)>[
  // Expense categories are admin-only (RLS).
  ('/admin/expenses/categories', null),
  ('/admin/expenses', '/sales/sections/cashbox/expenses'),
  ('/admin/cashbox', '/sales/sections/cashbox'),
  ('/admin/warehouse', '/sales/sections/warehouse'),
  ('/admin/technicians', '/sales/sections/technicians'),
  ('/admin/products', '/sales/sections/products'),
  ('/admin/categories', '/sales/sections/categories'),
  ('/admin/employees', '/sales/sections/employees'),
  ('/admin/customers', '/sales/sections/customers'),
  ('/admin/wallets', '/sales/sections/wallets'),
  ('/admin/marketing', '/sales/sections/marketing'),
  ('/admin/instapay', '/sales/sections/instapay'),
  ('/admin/sales-returns', '/sales/sections/sales-returns'),
  ('/admin/orders', '/sales/orders'),
  ('/admin/sync', '/sales/sync'),
  ('/admin/month-sales', '/sales/month-sales'),
];

/// The /sales page showing what [adminPath] shows to admin, or null when
/// sales has no such page (users, reports, settings...).
String? salesPathFor(String adminPath, {String query = ''}) {
  String withQuery(String path) => query.isEmpty ? path : '$path?$query';

  if (adminPath == Routes.adminWalkInSale) {
    return Uri.splitQueryString(query)['tab'] == 'invoices'
        ? Routes.salesTodayInvoices
        : Routes.salesSale;
  }
  for (final (prefix, twin) in _salesTwins) {
    if (adminPath == prefix || adminPath.startsWith('$prefix/')) {
      if (twin == null) return null;
      return withQuery(twin + adminPath.substring(prefix.length));
    }
  }
  return null;
}

String homeFor(AppRole role) => switch (role) {
  AppRole.admin => Routes.adminHome,
  AppRole.technician => Routes.technicianHome,
  AppRole.customer => Routes.customerHome,
  AppRole.sales => Routes.salesHome,
};

AppRole? _areaRole(String location) {
  bool inArea(String root) => location == root || location.startsWith('$root/');
  if (inArea(Routes.adminHome)) return AppRole.admin;
  if (inArea(Routes.technicianHome)) return AppRole.technician;
  if (inArea(Routes.customerHome)) return AppRole.customer;
  if (inArea(Routes.salesHome)) return AppRole.sales;
  return null;
}
