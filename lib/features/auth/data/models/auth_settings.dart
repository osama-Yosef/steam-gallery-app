/// Server-side auth switches the app routes by (rpc_get_auth_settings, 0031).
/// The database enforces them regardless; the app only reads them to send the
/// user to the right screen instead of letting their actions fail.
class AuthSettings {
  /// When true, a customer must verify their phone by OTP before they can
  /// order or request maintenance.
  final bool requireVerifiedPhone;

  const AuthSettings({required this.requireVerifiedPhone});

  /// Used until the real settings load, and when they can't: the server still
  /// refuses unverified customers, so the worst case is a later error message.
  static const unknown = AuthSettings(requireVerifiedPhone: false);

  factory AuthSettings.fromJson(Map<String, dynamic> json) => AuthSettings(
    requireVerifiedPhone: json['require_verified_phone'] as bool? ?? false,
  );
}
