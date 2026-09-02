// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'users_admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(usersAdminRepository)
const usersAdminRepositoryProvider = UsersAdminRepositoryProvider._();

final class UsersAdminRepositoryProvider
    extends
        $FunctionalProvider<
          UsersAdminRepository,
          UsersAdminRepository,
          UsersAdminRepository
        >
    with $Provider<UsersAdminRepository> {
  const UsersAdminRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usersAdminRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usersAdminRepositoryHash();

  @$internal
  @override
  $ProviderElement<UsersAdminRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UsersAdminRepository create(Ref ref) {
    return usersAdminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UsersAdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UsersAdminRepository>(value),
    );
  }
}

String _$usersAdminRepositoryHash() =>
    r'19d3071be73aa539a696c90757a441d2870965c7';

@ProviderFor(adminUsersList)
const adminUsersListProvider = AdminUsersListFamily._();

final class AdminUsersListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppUser>>,
          List<AppUser>,
          FutureOr<List<AppUser>>
        >
    with $FutureModifier<List<AppUser>>, $FutureProvider<List<AppUser>> {
  const AdminUsersListProvider._({
    required AdminUsersListFamily super.from,
    required ({String? search, AppRole? roleFilter}) super.argument,
  }) : super(
         retry: null,
         name: r'adminUsersListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminUsersListHash();

  @override
  String toString() {
    return r'adminUsersListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<AppUser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AppUser>> create(Ref ref) {
    final argument = this.argument as ({String? search, AppRole? roleFilter});
    return adminUsersList(
      ref,
      search: argument.search,
      roleFilter: argument.roleFilter,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminUsersListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminUsersListHash() => r'fc94feebddfe4a38c2e52191aaeaeb1b644ef3ec';

final class AdminUsersListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<AppUser>>,
          ({String? search, AppRole? roleFilter})
        > {
  const AdminUsersListFamily._()
    : super(
        retry: null,
        name: r'adminUsersListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AdminUsersListProvider call({String? search, AppRole? roleFilter}) =>
      AdminUsersListProvider._(
        argument: (search: search, roleFilter: roleFilter),
        from: this,
      );

  @override
  String toString() => r'adminUsersListProvider';
}
