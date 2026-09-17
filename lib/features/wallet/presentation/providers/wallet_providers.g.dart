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
