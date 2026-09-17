// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(walletRepository)
const walletRepositoryProvider = WalletRepositoryProvider._();

final class WalletRepositoryProvider
    extends
        $FunctionalProvider<
          WalletRepository,
          WalletRepository,
          WalletRepository
        >
    with $Provider<WalletRepository> {
  const WalletRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletRepositoryHash();

  @$internal
  @override
  $ProviderElement<WalletRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WalletRepository create(Ref ref) {
    return walletRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalletRepository>(value),
    );
  }
}

String _$walletRepositoryHash() => r'84c7526846525cbb99018dac5d3de741f1b19539';

@ProviderFor(MyWallet)
const myWalletProvider = MyWalletProvider._();

final class MyWalletProvider extends $AsyncNotifierProvider<MyWallet, Wallet> {
  const MyWalletProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myWalletProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myWalletHash();

  @$internal
  @override
  MyWallet create() => MyWallet();
}

String _$myWalletHash() => r'79b9d86c1630b8379e233f7d47fe98282874463e';

abstract class _$MyWallet extends $AsyncNotifier<Wallet> {
  FutureOr<Wallet> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<Wallet>, Wallet>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Wallet>, Wallet>,
              AsyncValue<Wallet>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(myWalletTransactions)
const myWalletTransactionsProvider = MyWalletTransactionsProvider._();

final class MyWalletTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WalletTransaction>>,
          List<WalletTransaction>,
          FutureOr<List<WalletTransaction>>
        >
    with
        $FutureModifier<List<WalletTransaction>>,
        $FutureProvider<List<WalletTransaction>> {
  const MyWalletTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myWalletTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myWalletTransactionsHash();

  @$internal
  @override
  $FutureProviderElement<List<WalletTransaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WalletTransaction>> create(Ref ref) {
    return myWalletTransactions(ref);
  }
}

String _$myWalletTransactionsHash() =>
    r'46b2ffc8a1b3dfb106cc1427b62f6f37c59ab689';

@ProviderFor(adminWallets)
const adminWalletsProvider = AdminWalletsFamily._();

final class AdminWalletsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WalletSummary>>,
          List<WalletSummary>,
          FutureOr<List<WalletSummary>>
        >
    with
        $FutureModifier<List<WalletSummary>>,
        $FutureProvider<List<WalletSummary>> {
  const AdminWalletsProvider._({
    required AdminWalletsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'adminWalletsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminWalletsHash();

  @override
  String toString() {
    return r'adminWalletsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<WalletSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WalletSummary>> create(Ref ref) {
    final argument = this.argument as String?;
    return adminWallets(ref, search: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminWalletsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminWalletsHash() => r'15ef35dd27cefaddd404f7b3292ccd6d6342616e';

final class AdminWalletsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<WalletSummary>>, String?> {
  const AdminWalletsFamily._()
    : super(
        retry: null,
        name: r'adminWalletsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AdminWalletsProvider call({String? search}) =>
      AdminWalletsProvider._(argument: search, from: this);

  @override
  String toString() => r'adminWalletsProvider';
}

@ProviderFor(walletLiability)
const walletLiabilityProvider = WalletLiabilityProvider._();

final class WalletLiabilityProvider
    extends
        $FunctionalProvider<
          AsyncValue<({double totalLiability, int walletCount})>,
          ({double totalLiability, int walletCount}),
          FutureOr<({double totalLiability, int walletCount})>
        >
    with
        $FutureModifier<({double totalLiability, int walletCount})>,
        $FutureProvider<({double totalLiability, int walletCount})> {
  const WalletLiabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletLiabilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletLiabilityHash();

  @$internal
  @override
  $FutureProviderElement<({double totalLiability, int walletCount})>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<({double totalLiability, int walletCount})> create(Ref ref) {
    return walletLiability(ref);
  }
}

String _$walletLiabilityHash() => r'28d98140fcefbc0e5162d6d74293c58781f369d1';
