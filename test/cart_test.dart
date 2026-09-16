import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/formatters.dart';
import 'package:steam_gallery_app/features/auth/data/models/app_user.dart';
import 'package:steam_gallery_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:steam_gallery_app/features/cart/data/models/cart.dart';
import 'package:steam_gallery_app/features/cart/data/repositories/cart_repository.dart';
import 'package:steam_gallery_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:steam_gallery_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:steam_gallery_app/features/products/data/models/catalog_query.dart';
import 'package:steam_gallery_app/features/products/data/models/product_category.dart';
import 'package:steam_gallery_app/features/products/data/models/product_image.dart';
import 'package:steam_gallery_app/features/products/data/models/product_public.dart';
import 'package:steam_gallery_app/features/products/data/repositories/product_repository.dart';
import 'package:steam_gallery_app/features/products/presentation/providers/product_providers.dart';
import 'package:steam_gallery_app/features/products/presentation/screens/customer/product_detail_screen.dart';

final _customer = const AppUser(
  id: 'cust-1',
  role: AppRole.customer,
  fullName: 'عميل تجريبي',
  isActive: true,
);
final _technician = const AppUser(
  id: 'tech-1',
  role: AppRole.technician,
  fullName: 'فني تجريبي',
  isActive: true,
);

CartLine _line(
  String id, {
  String name = 'منتج',
  int quantity = 1,
  double unitPrice = 100,
  double? priceSeen,
  bool isActive = true,
  bool isAvailable = true,
}) => CartLine(
  productId: id,
  name: name,
  quantity: quantity,
  unitPrice: unitPrice,
  priceSeen: priceSeen ?? unitPrice,
  priceChanged: (priceSeen ?? unitPrice) != unitPrice,
  lineTotal: isActive ? unitPrice * quantity : 0,
  isActive: isActive,
  isAvailable: isAvailable,
);

/// A minimal product catalogue backing [_FakeCartRepo]: enough for the RPCs'
/// pricing/availability/active checks, without a real database.
class _CatalogProduct {
  final String name;
  final double price;
  final bool active;
  final bool available;
  const _CatalogProduct(
    this.name,
    this.price, {
    this.active = true,
    this.available = true,
  });
}

/// Mirrors the shape of 0035's RPCs in memory: quantity caps, product
/// lookups, and price-change/availability flags recomputed on every read —
/// just like `rpc_get_my_cart` re-prices from `products` every time.
class _FakeCartRepo implements CartRepository {
  _FakeCartRepo([Map<String, _CatalogProduct>? products])
    : products = products ?? {};

  final Map<String, _CatalogProduct> products;
  final Map<String, CartLine> _lines = {};
  final calls = <String>[];

  void seed(String productId, {int quantity = 1, double? priceSeen}) {
    final p = products[productId]!;
    _lines[productId] = _line(
      productId,
      name: p.name,
      quantity: quantity,
      unitPrice: p.price,
      priceSeen: priceSeen,
      isActive: p.active,
      isAvailable: p.active && p.available,
    );
  }

  CartSummary _reprice() {
    for (final id in _lines.keys.toList()) {
      final p = products[id];
      if (p == null) continue;
      final l = _lines[id]!;
      _lines[id] = l.copyWith(
        unitPrice: p.price,
        priceChanged: p.price != l.priceSeen,
        isActive: p.active,
        isAvailable: p.active && p.available,
        lineTotal: p.active ? p.price * l.quantity : 0,
      );
    }
    final items = _lines.values.toList()
      ..sort((a, b) => a.productId.compareTo(b.productId));
    return CartSummary(
      items: items,
      itemCount: items.where((l) => l.isActive).fold(0, (s, l) => s + l.quantity),
      subtotal: items.fold(0.0, (s, l) => s + l.lineTotal),
      currency: 'EGP',
      hasIssues: items.any((l) => l.blocksCheckout || l.priceChanged),
    );
  }

  @override
  Future<CartSummary> getCart() async {
    calls.add('get');
    return _reprice();
  }

  @override
  Future<CartSummary> addItem(String productId, int quantity) async {
    calls.add('add:$productId:$quantity');
    final p = products[productId];
    if (p == null || !p.active) throw Exception('PRODUCT_NOT_FOUND');
    final next = ((_lines[productId]?.quantity ?? 0) + quantity).clamp(
      0,
      maxCartLineQuantity,
    );
    _lines[productId] = _line(
      productId,
      name: p.name,
      quantity: next,
      unitPrice: p.price,
      isActive: true,
      isAvailable: p.available,
    );
    return _reprice();
  }

  @override
  Future<CartSummary> setQuantity(String productId, int quantity) async {
    calls.add('set:$productId:$quantity');
    if (quantity <= 0) {
      _lines.remove(productId);
      return _reprice();
    }
    final p = products[productId];
    if (p == null || !p.active) throw Exception('PRODUCT_NOT_FOUND');
    final existing = _lines[productId];
    _lines[productId] = (existing ?? _line(productId, name: p.name, unitPrice: p.price))
        .copyWith(quantity: quantity.clamp(0, maxCartLineQuantity));
    return _reprice();
  }

  @override
  Future<CartSummary> clear() async {
    calls.add('clear');
    _lines.clear();
    return _reprice();
  }

  @override
  Future<CartSummary> acknowledgePrices() async {
    calls.add('ack');
    for (final id in _lines.keys.toList()) {
      final p = products[id];
      if (p != null) {
        _lines[id] = _lines[id]!.copyWith(priceSeen: p.price, priceChanged: false);
      }
    }
    return _reprice();
  }
}

dynamic _cartOverrides(_FakeCartRepo repo, {AppUser? user}) => [
  cartRepositoryProvider.overrideWithValue(repo),
  currentUserProfileProvider.overrideWith((ref) async => user ?? _customer),
];

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required dynamic overrides,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: Consumer(
        builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(
            theme: AppTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: screen,
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// A tiny product repository stand-in for [ProductDetailScreen] tests, kept
/// local to this file rather than shared with catalog_test.dart.
class _FakeProductRepo implements ProductRepository {
  _FakeProductRepo({this.product});
  final ProductPublic? product;

  @override
  Future<List<ProductPublic>> browseCatalog(
    CatalogQuery query, {
    required int limit,
    required int offset,
  }) async => [];

  @override
  Future<List<ProductCategory>> getCategories({bool activeOnly = false}) async =>
      [];

  @override
  Future<ProductPublic?> getProductPublicById(String id) async => product;

  @override
  Future<List<ProductImage>> getProductImages(String productId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProductPublic _product(
  String id, {
  double price = 100,
  bool available = true,
}) => ProductPublic(
  id: id,
  sku: 'SKU-$id',
  name: 'منتج $id',
  specs: const {},
  sellingPrice: price,
  isAvailable: available,
  createdAt: DateTime(2026, 9, 1),
);

void main() {
  group('CartLine / CartSummary', () {
    test('blocksCheckout when inactive or out of stock', () {
      expect(_line('a').blocksCheckout, isFalse);
      expect(_line('a', isActive: false).blocksCheckout, isTrue);
      expect(_line('a', isAvailable: false).blocksCheckout, isTrue);
    });

    test('CartSummary derives item count, checkout eligibility and lookup', () {
      final s = CartSummary(
        items: [
          _line('a', quantity: 2, unitPrice: 50),
          _line('b', quantity: 1, isAvailable: false),
        ],
        itemCount: 3,
        subtotal: 100,
        currency: 'EGP',
        hasIssues: true,
      );
      expect(s.canCheckout, isFalse); // b blocks it
      expect(s.hasPriceChanges, isFalse);
      expect(s.quantityOf('a'), 2);
      expect(s.quantityOf('missing'), 0);
      expect(CartSummary.empty.isEmpty, isTrue);
      expect(CartSummary.empty.canCheckout, isFalse);
    });

    test('fromRpc parses the jsonb the RPC returns, with no cost column', () {
      final s = CartSummary.fromRpc({
        'items': [
          {
            'product_id': 'p1',
            'name': 'مكواة',
            'sku': 'IR-1',
            'image_url': null,
            'quantity': 2,
            'unit_price': 120,
            'price_seen': 100,
            'price_changed': true,
            'line_total': 240,
            'is_active': true,
            'is_available': true,
          },
        ],
        'item_count': 2,
        'subtotal': 240,
        'currency': 'EGP',
        'has_issues': true,
      });
      expect(s.items.single.priceChanged, isTrue);
      expect(s.items.single.priceSeen, 100);
      expect(s.subtotal, 240);
    });
  });

  group('Cart notifier', () {
    test('add accumulates and caps at maxCartLineQuantity', () async {
      final repo = _FakeCartRepo({'p': const _CatalogProduct('منتج', 5)});
      final c = ProviderContainer(overrides: _cartOverrides(repo));
      addTearDown(c.dispose);
      await c.read(cartProvider.future);

      var cart = await c.read(cartProvider.notifier).add('p', quantity: 3);
      expect(cart.quantityOf('p'), 3);
      cart = await c.read(cartProvider.notifier).add('p', quantity: 4);
      expect(cart.quantityOf('p'), 7);
      cart = await c.read(cartProvider.notifier).add('p', quantity: 99);
      expect(cart.quantityOf('p'), maxCartLineQuantity);
      expect(c.read(cartProvider).value!.subtotal, 5.0 * maxCartLineQuantity);
    });

    test('setQuantity(0) removes the line; clear empties the cart', () async {
      final repo = _FakeCartRepo({'p': const _CatalogProduct('منتج', 10)});
      final c = ProviderContainer(overrides: _cartOverrides(repo));
      addTearDown(c.dispose);
      await c.read(cartProvider.notifier).add('p', quantity: 2);
      var cart = await c.read(cartProvider.notifier).setQuantity('p', 0);
      expect(cart.items, isEmpty);

      await c.read(cartProvider.notifier).add('p', quantity: 1);
      cart = await c.read(cartProvider.notifier).clear();
      expect(cart.isEmpty, isTrue);
    });

    test('a non-customer (technician) always sees an empty cart, no RPC call', () async {
      final repo = _FakeCartRepo();
      final c = ProviderContainer(
        overrides: _cartOverrides(repo, user: _technician),
      );
      addTearDown(c.dispose);
      final cart = await c.read(cartProvider.future);
      expect(cart.isEmpty, isTrue);
      expect(repo.calls, isEmpty);
    });
  });

  group('CartScreen', () {
    testWidgets('empty cart offers to browse the store', (tester) async {
      final repo = _FakeCartRepo();
      await _pumpScreen(
        tester,
        const CartScreen(),
        overrides: _cartOverrides(repo),
      );
      expect(find.text('السلة فارغة'), findsOneWidget);
      expect(find.text('تصفح المتجر'), findsOneWidget);
    });

    testWidgets('shows lines, subtotal, and adjusts quantity via the stepper', (
      tester,
    ) async {
      final repo = _FakeCartRepo({
        'p1': const _CatalogProduct('مكواة بخار', 100),
      })..seed('p1', quantity: 2);
      await _pumpScreen(
        tester,
        const CartScreen(),
        overrides: _cartOverrides(repo),
      );

      expect(find.text('مكواة بخار'), findsOneWidget);
      expect(
        find.text(Formatters.currency(200)),
        findsOneWidget,
        reason: 'subtotal for 2 × 100',
      );

      await tester.tap(find.byKey(const Key('qty-plus')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('set:p1:3'));
      expect(
        find.text(Formatters.currency(300)),
        findsOneWidget,
        reason: 'subtotal updates from the server response',
      );
    });

    testWidgets('price-change notice can be acknowledged', (tester) async {
      final repo = _FakeCartRepo({'p1': const _CatalogProduct('منتج', 150)})
        ..seed('p1', quantity: 1, priceSeen: 100);
      await _pumpScreen(
        tester,
        const CartScreen(),
        overrides: _cartOverrides(repo),
      );
      expect(find.byKey(const Key('cart-price-notice')), findsOneWidget);

      await tester.tap(find.text('تمام'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('ack'));
      expect(find.byKey(const Key('cart-price-notice')), findsNothing);
    });

    testWidgets('an unavailable line blocks checkout until removed', (
      tester,
    ) async {
      final repo = _FakeCartRepo({
        'p1': const _CatalogProduct('متوفر', 50),
        'p2': const _CatalogProduct('غير متوفر', 80, available: false),
      })
        ..seed('p1', quantity: 1)
        ..seed('p2', quantity: 1);
      await _pumpScreen(
        tester,
        const CartScreen(),
        overrides: _cartOverrides(repo),
      );

      expect(find.byKey(const Key('cart-blocked-notice')), findsOneWidget);
      final checkoutButton = tester.widget<FilledButton>(
        find.byKey(const Key('cart-checkout')),
      );
      expect(checkoutButton.onPressed, isNull);

      await tester.tap(find.byIcon(Icons.delete_outline).last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cart-blocked-notice')), findsNothing);
      final enabled = tester.widget<FilledButton>(
        find.byKey(const Key('cart-checkout')),
      );
      expect(enabled.onPressed, isNotNull);
    });

    testWidgets(
      'a product switched off server-side stays visible at zero total and blocks checkout',
      (tester) async {
        final repo = _FakeCartRepo({
          'p1': const _CatalogProduct('منتج موقوف', 90, active: false),
        })..seed('p1', quantity: 2);
        await _pumpScreen(
          tester,
          const CartScreen(),
          overrides: _cartOverrides(repo),
        );

        expect(find.text('لم يعد متاحًا في المتجر'), findsOneWidget);
        expect(find.byKey(const Key('cart-subtotal')), findsOneWidget);
        expect(
          find.text(Formatters.currency(0)),
          findsOneWidget,
          reason: 'an inactive line contributes nothing to the subtotal',
        );
        final checkoutButton = tester.widget<FilledButton>(
          find.byKey(const Key('cart-checkout')),
        );
        expect(checkoutButton.onPressed, isNull);
        // Its quantity can only go down (to remove it), never up.
        expect(find.byKey(const Key('qty-plus')), findsNothing);
      },
    );

    testWidgets('clearing the cart asks for confirmation first', (
      tester,
    ) async {
      final repo = _FakeCartRepo({'p1': const _CatalogProduct('منتج', 10)})
        ..seed('p1');
      await _pumpScreen(
        tester,
        const CartScreen(),
        overrides: _cartOverrides(repo),
      );

      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();
      expect(find.text('تفريغ السلة؟'), findsOneWidget);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(repo.calls, isNot(contains('clear')));
      expect(find.text('منتج'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تفريغ'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('clear'));
      expect(find.text('السلة فارغة'), findsOneWidget);
    });
  });

  group('ProductDetailScreen — add to cart', () {
    Future<ProviderContainer> pumpDetail(
      WidgetTester tester,
      ProductPublic p,
      _FakeCartRepo cartRepo,
    ) async {
      final overrides = [
        productRepositoryProvider.overrideWithValue(
          _FakeProductRepo(product: p),
        ),
        productOffersProvider(p.id).overrideWith((ref) async => []),
      ]
        // Spreading a dynamic-typed Iterable here would infer List<dynamic>,
        // not List<Override> (Override isn't nameable outside riverpod's own
        // codegen); addAll keeps the outer list's real (Override) runtime type.
        // ignore: prefer_spread_collections
        ..addAll(_cartOverrides(cartRepo));
      return _pumpScreen(
        tester,
        ProductDetailScreen(productId: p.id),
        overrides: overrides,
      );
    }

    testWidgets('quantity stepper adds that many to the cart', (tester) async {
      final repo = _FakeCartRepo({'p1': const _CatalogProduct('منتج p1', 250)});
      final c = await pumpDetail(tester, _product('p1', price: 250), repo);

      await tester.tap(find.byKey(const Key('qty-plus')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('qty-plus')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('add-to-cart')));
      await tester.pumpAndSettle();
      expect(c.read(cartProvider).value!.quantityOf('p1'), 3);
      expect(find.text('في السلة الآن: 3'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('qty-value'))).data,
        '1',
      );
    });

    testWidgets('unavailable products cannot be added', (tester) async {
      final repo = _FakeCartRepo({
        'p2': const _CatalogProduct('منتج p2', 100, available: false),
      });
      final c = await pumpDetail(
        tester,
        _product('p2', available: false),
        repo,
      );
      expect(find.text('غير متوفر حاليًا'), findsWidgets);
      expect(find.byKey(const Key('qty-plus')), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('add-to-cart')))
            .onPressed,
        isNull,
      );
      expect(c.read(cartProvider).value!.isEmpty, isTrue);
    });

    testWidgets('a hidden or deleted product says so', (tester) async {
      final repo = _FakeCartRepo();
      final overrides = [
        productRepositoryProvider.overrideWithValue(_FakeProductRepo()),
        productOffersProvider('gone').overrideWith((ref) async => []),
      ]
        // See the note in pumpDetail above.
        // ignore: prefer_spread_collections
        ..addAll(_cartOverrides(repo));
      await _pumpScreen(
        tester,
        const ProductDetailScreen(productId: 'gone'),
        overrides: overrides,
      );
      expect(find.text('هذا المنتج لم يعد متاحًا في المتجر'), findsOneWidget);
    });
  });
}
