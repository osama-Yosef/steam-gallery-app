// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
const authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  const AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'157dd73bdf6ec0879936e7c10d1b03f5bf9bed55';

/// Re-fetches the profile row whenever the Supabase auth session changes
/// (sign in / sign out / token refresh). The router watches this to decide
/// which shell (admin/technician/customer/login) to show.

@ProviderFor(currentUserProfile)
const currentUserProfileProvider = CurrentUserProfileProvider._();

/// Re-fetches the profile row whenever the Supabase auth session changes
/// (sign in / sign out / token refresh). The router watches this to decide
/// which shell (admin/technician/customer/login) to show.

final class CurrentUserProfileProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, FutureOr<AppUser?>>
    with $FutureModifier<AppUser?>, $FutureProvider<AppUser?> {
  /// Re-fetches the profile row whenever the Supabase auth session changes
  /// (sign in / sign out / token refresh). The router watches this to decide
  /// which shell (admin/technician/customer/login) to show.
  const CurrentUserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserProfileHash();

  @$internal
  @override
  $FutureProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AppUser?> create(Ref ref) {
    return currentUserProfile(ref);
  }
}

String _$currentUserProfileHash() =>
    r'ff0ca977312dce0e14a55ddedcbb65a9b92ee53c';

/// Server auth switches, refreshed on every auth event. Falls back to
/// [AuthSettings.unknown] rather than failing: the database enforces the real
/// rule either way, this only picks the screen.

@ProviderFor(authSettings)
const authSettingsProvider = AuthSettingsProvider._();

/// Server auth switches, refreshed on every auth event. Falls back to
/// [AuthSettings.unknown] rather than failing: the database enforces the real
/// rule either way, this only picks the screen.

final class AuthSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthSettings>,
          AuthSettings,
          FutureOr<AuthSettings>
        >
    with $FutureModifier<AuthSettings>, $FutureProvider<AuthSettings> {
  /// Server auth switches, refreshed on every auth event. Falls back to
  /// [AuthSettings.unknown] rather than failing: the database enforces the real
  /// rule either way, this only picks the screen.
  const AuthSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSettingsHash();

  @$internal
  @override
  $FutureProviderElement<AuthSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AuthSettings> create(Ref ref) {
    return authSettings(ref);
  }
}

String _$authSettingsHash() => r'db134ea28895c48bacdafb0fdc4a030b03d74768';

@ProviderFor(userProfileById)
const userProfileByIdProvider = UserProfileByIdFamily._();

final class UserProfileByIdProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, FutureOr<AppUser?>>
    with $FutureModifier<AppUser?>, $FutureProvider<AppUser?> {
  const UserProfileByIdProvider._({
    required UserProfileByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userProfileByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userProfileByIdHash();

  @override
  String toString() {
    return r'userProfileByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AppUser?> create(Ref ref) {
    final argument = this.argument as String;
    return userProfileById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfileByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userProfileByIdHash() => r'7f7d347982e6a720b99b5d7061d14e659b685dbb';

final class UserProfileByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AppUser?>, String> {
  const UserProfileByIdFamily._()
    : super(
        retry: null,
        name: r'userProfileByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserProfileByIdProvider call(String userId) =>
      UserProfileByIdProvider._(argument: userId, from: this);

  @override
  String toString() => r'userProfileByIdProvider';
}

@ProviderFor(PendingOtp)
const pendingOtpProvider = PendingOtpProvider._();

final class PendingOtpProvider
    extends $NotifierProvider<PendingOtp, OtpRequest?> {
  const PendingOtpProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingOtpProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingOtpHash();

  @$internal
  @override
  PendingOtp create() => PendingOtp();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OtpRequest? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OtpRequest?>(value),
    );
  }
}

String _$pendingOtpHash() => r'c1834ae1b7681398bea2966f6a050423e62b8fd3';

abstract class _$PendingOtp extends $Notifier<OtpRequest?> {
  OtpRequest? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<OtpRequest?, OtpRequest?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OtpRequest?, OtpRequest?>,
              OtpRequest?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// True from the moment a password-recovery code is submitted until the new
/// password is saved (or the user backs out). Verifying the code signs the
/// user in, and without this the router would send them straight home,
/// skipping the new-password screen.

@ProviderFor(PasswordRecovery)
const passwordRecoveryProvider = PasswordRecoveryProvider._();

/// True from the moment a password-recovery code is submitted until the new
/// password is saved (or the user backs out). Verifying the code signs the
/// user in, and without this the router would send them straight home,
/// skipping the new-password screen.
final class PasswordRecoveryProvider
    extends $NotifierProvider<PasswordRecovery, bool> {
  /// True from the moment a password-recovery code is submitted until the new
  /// password is saved (or the user backs out). Verifying the code signs the
  /// user in, and without this the router would send them straight home,
  /// skipping the new-password screen.
  const PasswordRecoveryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordRecoveryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordRecoveryHash();

  @$internal
  @override
  PasswordRecovery create() => PasswordRecovery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$passwordRecoveryHash() => r'a8539e88c3627533f255d48da63e6a613e344ffb';

/// True from the moment a password-recovery code is submitted until the new
/// password is saved (or the user backs out). Verifying the code signs the
/// user in, and without this the router would send them straight home,
/// skipping the new-password screen.

abstract class _$PasswordRecovery extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
