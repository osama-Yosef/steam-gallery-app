// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cartRepository)
const cartRepositoryProvider = CartRepositoryProvider._();

final class CartRepositoryProvider
    extends $FunctionalProvider<CartRepository, CartRepository, CartRepository>
    with $Provider<CartRepository> {
  const CartRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartRepositoryHash();

  @$internal
  @override
  $ProviderElement<CartRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CartRepository create(Ref ref) {
    return cartRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CartRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CartRepository>(value),
    );
  }
}

String _$cartRepositoryHash() => r'7970a6ce29098c891ba5f043e2dcc02ae6379e9d';

/// The signed-in customer's cart, stored and priced by the server (0035).
/// Rebuilds on every sign-in/out, so one account never sees another's cart.
/// Mutations replace the state with the cart the server returns.

@ProviderFor(Cart)
const cartProvider = CartProvider._();

/// The signed-in customer's cart, stored and priced by the server (0035).
/// Rebuilds on every sign-in/out, so one account never sees another's cart.
/// Mutations replace the state with the cart the server returns.
final class CartProvider extends $AsyncNotifierProvider<Cart, CartSummary> {
  /// The signed-in customer's cart, stored and priced by the server (0035).
  /// Rebuilds on every sign-in/out, so one account never sees another's cart.
  /// Mutations replace the state with the cart the server returns.
  const CartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartHash();

  @$internal
  @override
  Cart create() => Cart();
}

String _$cartHash() => r'4843f9296c261a0ab3e06b5987a3cdbdf64f748d';

/// The signed-in customer's cart, stored and priced by the server (0035).
/// Rebuilds on every sign-in/out, so one account never sees another's cart.
/// Mutations replace the state with the cart the server returns.

abstract class _$Cart extends $AsyncNotifier<CartSummary> {
  FutureOr<CartSummary> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<CartSummary>, CartSummary>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CartSummary>, CartSummary>,
              AsyncValue<CartSummary>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Badge count on the «السلة» tab.

@ProviderFor(cartItemCount)
const cartItemCountProvider = CartItemCountProvider._();

/// Badge count on the «السلة» tab.

final class CartItemCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Badge count on the «السلة» tab.
  const CartItemCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cartItemCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cartItemCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return cartItemCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$cartItemCountHash() => r'9c05384ed68f5aaeba82ce2075ac68c00cfef9df';
