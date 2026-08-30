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
