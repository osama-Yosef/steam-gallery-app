import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/core/maps/geo_point.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/features/auth/data/models/app_user.dart';
import 'package:steam_gallery_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:steam_gallery_app/features/cart/data/models/cart.dart';
import 'package:steam_gallery_app/features/cart/data/repositories/cart_repository.dart';
import 'package:steam_gallery_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:steam_gallery_app/features/locations/data/models/location_models.dart';
import 'package:steam_gallery_app/features/locations/presentation/providers/locations_providers.dart';
import 'package:steam_gallery_app/features/orders/data/models/order.dart';
import 'package:steam_gallery_app/features/orders/data/models/order_item.dart';
import 'package:steam_gallery_app/features/orders/data/repositories/order_repository.dart';
import 'package:steam_gallery_app/features/technician_account/data/models/sale.dart';
import 'package:steam_gallery_app/features/orders/presentation/providers/order_providers.dart';
import 'package:steam_gallery_app/features/orders/presentation/screens/customer/checkout_screen.dart';

final _customer = const AppUser(
  id: 'cust-1',
  role: AppRole.customer,
  fullName: 'عميل تجريبي',
  isActive: true,
);

CustomerAddress _address(
  String id, {
  String label = 'المنزل',
  bool isDefault = false,
  bool serviceable = true,
}) => CustomerAddress(
  id: id,
  cityId: 'cairo',
  serviceAreaId: serviceable ? 'area-1' : null,
  serviceAreaName: serviceable ? 'مدينة نصر' : null,
  label: label,
  addressLine: 'شارع عباس العقاد، $label',
  location: const GeoPoint(30.05, 31.33),
  isDefault: isDefault,
);

/// One fixed cart, priced by the "server" — mirrors CartRepository without
/// exercising add/remove RPC logic (that's cart_test.dart's job).
class _FixedCartRepo implements CartRepository {
  _FixedCartRepo(this.summary);
  CartSummary summary;

  @override
  Future<CartSummary> getCart() async => summary;
  @override
  Future<CartSummary> addItem(
    String productId,
    int quantity, {
    List<String> optionIds = const [],
  }) async => summary;
  @override
  Future<CartSummary> setQuantity(
    String productId,
    int quantity, {
    List<String> optionIds = const [],
  }) async => summary;
  @override
  Future<CartSummary> clear() async {
    summary = CartSummary.empty;
    return summary;
  }

  @override
  Future<CartSummary> acknowledgePrices() async => summary;
}

CartLine _cartLine(
  String productId, {
  String name = 'مكواة بخار',
  int quantity = 1,
  double unitPrice = 200,
  bool isActive = true,
  bool isAvailable = true,
}) => CartLine(
  productId: productId,
  name: name,
  quantity: quantity,
  unitPrice: unitPrice,
  priceSeen: unitPrice,
  priceChanged: false,
  lineTotal: isActive ? unitPrice * quantity : 0,
  isActive: isActive,
  isAvailable: isAvailable,
  optionIds: const [],
  options: const [],
);

CartSummary _cart(List<CartLine> items) => CartSummary(
  items: items,
  itemCount: items.where((l) => l.isActive).fold(0, (s, l) => s + l.quantity),
  subtotal: items.fold(0.0, (s, l) => s + l.lineTotal),
  currency: 'EGP',
  hasIssues: items.any((l) => l.blocksCheckout),
);

/// Records every createOrder call; [orderId] is what it "creates".
class _FakeOrderRepo implements OrderRepository {
  final calls = <({
    String customerId,
    List<({String productId, int quantity, List<String> optionIds})> items,
    String addressId,
    String? notes,
  })>[];
  Object? failWith;

  @override
  Future<String> createOrder({
    required String customerId,
    required List<({String productId, int quantity, List<String> optionIds})>
    items,
    required String addressId,
    String? notes,
    required String clientRequestId,
  }) async {
    // Real repositories always throw AppException (see
    // SupabaseOrderRepository.createOrder's catch); mirror that here so
    // this fake behaves like the real contract, not a raw Postgrest error.
    if (failWith != null) throw AppException.from(failWith!);
    calls.add((
      customerId: customerId,
      items: items,
      addressId: addressId,
      notes: notes,
    ));
    return 'order-1';
  }

  @override
  Stream<List<Order>> watchCustomerOrders(String customerId) => const Stream.empty();
  @override
  Stream<Order?> watchOrder(String orderId) => const Stream.empty();
  @override
  Future<List<OrderItem>> getOrderItems(String orderId) async => [];
  @override
  Stream<List<Order>> watchAllOrders() => const Stream.empty();
  @override
  Future<void> confirmOrder(String orderId) async {}
  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {}
  @override
  Future<void> cancelOrder(String orderId, String reason) async {}
  @override
  Future<void> returnOrder(String orderId, String reason) async {}
  @override
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? orderId,
    String? notes,
    required String clientRequestId,
    required PaymentMethod paymentMethod,
  }) async {}
}

Future<ProviderContainer> _pumpCheckout(
  WidgetTester tester, {
  required CartSummary cart,
  required List<CustomerAddress> addresses,
  required _FakeOrderRepo orderRepo,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cartRepositoryProvider.overrideWithValue(_FixedCartRepo(cart)),
        currentUserProfileProvider.overrideWith((ref) async => _customer),
        myAddressesProvider.overrideWith((ref) async => addresses),
        orderRepositoryProvider.overrideWithValue(orderRepo),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return MaterialApp(
            theme: AppTheme.light(),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: CheckoutScreen(),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('Order delivery snapshot (0036)', () {
    Order order({
      String? building,
      String? floor,
      String? apartment,
      String? landmark,
      String? recipient,
      String? phone,
    }) => Order.fromRow({
      'id': 'o1',
      'order_number': 1,
      'customer_id': 'cust-1',
      'status': 'pending',
      'subtotal': 100,
      'discount': 0,
      'total': 100,
      'paid_amount': 0,
      'payment_status': 'unpaid',
      'delivery_address': 'شارع عباس العقاد',
      'delivery_recipient_name': recipient,
      'delivery_phone': phone,
      'delivery_building': building,
      'delivery_floor': floor,
      'delivery_apartment': apartment,
      'delivery_landmark': landmark,
      'created_at': '2026-09-17T00:00:00Z',
    });

    test('fromRow parses the full snapshot', () {
      final o = order(
        building: '12',
        floor: '3',
        apartment: '7',
        landmark: 'جنب الصيدلية',
        recipient: 'أحمد علي',
        phone: '+201001234567',
      );
      expect(o.deliveryAddress, 'شارع عباس العقاد');
      expect(o.deliveryRecipientName, 'أحمد علي');
      expect(o.deliveryPhone, '+201001234567');
      expect(o.deliveryLandmark, 'جنب الصيدلية');
    });

    test('deliveryDetailsLine joins only the parts that were filled in', () {
      expect(
        order(building: '12', floor: '3', apartment: '7').deliveryDetailsLine,
        'عمارة 12، الدور 3، شقة 7',
      );
      expect(order(floor: '3').deliveryDetailsLine, 'الدور 3');
      expect(order().deliveryDetailsLine, '');
    });
  });

  group('CheckoutScreen', () {
    testWidgets('empty cart shows the empty state, no address section', (
      tester,
    ) async {
      await _pumpCheckout(
        tester,
        cart: CartSummary.empty,
        addresses: [_address('a1', isDefault: true)],
        orderRepo: _FakeOrderRepo(),
      );
      expect(find.text('السلة فارغة'), findsOneWidget);
      expect(find.text('عنوان التوصيل'), findsNothing);
    });

    testWidgets('no saved address prompts to add one; submit is disabled', (
      tester,
    ) async {
      await _pumpCheckout(
        tester,
        cart: _cart([_cartLine('p1')]),
        addresses: const [],
        orderRepo: _FakeOrderRepo(),
      );
      expect(find.text('أضف عنوان توصيل أولًا'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'إرسال الطلب')).onPressed,
        isNull,
      );
    });

    testWidgets(
      'auto-selects the default address when it is serviceable',
      (tester) async {
        await _pumpCheckout(
          tester,
          cart: _cart([_cartLine('p1')]),
          addresses: [
            _address('a1', label: 'الشغل'),
            _address('a2', label: 'المنزل', isDefault: true),
          ],
          orderRepo: _FakeOrderRepo(),
        );
        expect(find.text('المنزل'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'إرسال الطلب')).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      'falls back to the first serviceable address when the default is not covered',
      (tester) async {
        await _pumpCheckout(
          tester,
          cart: _cart([_cartLine('p1')]),
          addresses: [
            _address('a1', label: 'المنزل', isDefault: true, serviceable: false),
            _address('a2', label: 'الشغل', serviceable: true),
          ],
          orderRepo: _FakeOrderRepo(),
        );
        expect(find.text('الشغل'), findsOneWidget);
      },
    );

    testWidgets(
      'no serviceable address at all: nothing auto-selected, submit disabled',
      (tester) async {
        await _pumpCheckout(
          tester,
          cart: _cart([_cartLine('p1')]),
          addresses: [_address('a1', isDefault: true, serviceable: false)],
          orderRepo: _FakeOrderRepo(),
        );
        expect(find.text('اختر عنوان التوصيل'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'إرسال الطلب')).onPressed,
          isNull,
        );
      },
    );

    testWidgets(
      'a blocked cart line disables submit even with a good address',
      (tester) async {
        await _pumpCheckout(
          tester,
          cart: _cart([_cartLine('p1', isAvailable: false)]),
          addresses: [_address('a1', isDefault: true)],
          orderRepo: _FakeOrderRepo(),
        );
        expect(
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'إرسال الطلب')).onPressed,
          isNull,
        );
      },
    );

    testWidgets('picking a different address from the sheet updates the selection', (
      tester,
    ) async {
      await _pumpCheckout(
        tester,
        cart: _cart([_cartLine('p1')]),
        addresses: [
          _address('a1', label: 'المنزل', isDefault: true),
          _address('a2', label: 'الشغل'),
        ],
        orderRepo: _FakeOrderRepo(),
      );
      expect(find.text('المنزل'), findsOneWidget);

      await tester.tap(find.text('المنزل'));
      await tester.pumpAndSettle();
      expect(find.text('الشغل'), findsWidgets); // once in the sheet list

      await tester.tap(find.text('الشغل').last);
      await tester.pumpAndSettle();
      expect(find.text('الشغل'), findsOneWidget); // sheet closed, on the card
    });

    testWidgets('submits the cart lines and chosen address, then clears the cart', (
      tester,
    ) async {
      final orderRepo = _FakeOrderRepo();
      final container = await _pumpCheckout(
        tester,
        cart: _cart([_cartLine('p1', quantity: 2), _cartLine('p2', quantity: 1)]),
        addresses: [_address('a1', isDefault: true)],
        orderRepo: orderRepo,
      );

      await tester.enterText(find.byType(TextField), 'اطرق الجرس مرتين');
      await tester.tap(find.widgetWithText(FilledButton, 'إرسال الطلب'));
      await tester.pumpAndSettle();

      expect(orderRepo.calls, hasLength(1));
      final call = orderRepo.calls.single;
      expect(call.customerId, 'cust-1');
      expect(call.addressId, 'a1');
      expect(call.notes, 'اطرق الجرس مرتين');
      expect(
        call.items.map((i) => (i.productId, i.quantity)).toSet(),
        {('p1', 2), ('p2', 1)},
      );
      expect(container.read(cartProvider).value!.isEmpty, isTrue);
    });

    testWidgets('a server refusal (e.g. address no longer serviceable) shows its message', (
      tester,
    ) async {
      // A real repository would already have translated this to
      // AppException; PostgrestException here exercises that same mapping
      // (app_exception.dart's _rpcErrorMessages) instead of hardcoding the
      // Arabic text on both sides of the test.
      final orderRepo = _FakeOrderRepo()
        ..failWith = const PostgrestException(message: 'ADDRESS_NOT_SERVICEABLE');
      await _pumpCheckout(
        tester,
        cart: _cart([_cartLine('p1')]),
        addresses: [_address('a1', isDefault: true)],
        orderRepo: orderRepo,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'إرسال الطلب'));
      await tester.pumpAndSettle();
      expect(
        find.text('المنطقة دي غير مغطاة حاليًا — اختر عنوانًا تانيًا'),
        findsOneWidget,
      );
    });

    testWidgets('payment method is shown as full transfer before shipping', (
      tester,
    ) async {
      await _pumpCheckout(
        tester,
        cart: _cart([_cartLine('p1')]),
        addresses: [_address('a1', isDefault: true)],
        orderRepo: _FakeOrderRepo(),
      );
      expect(find.text('طريقة الدفع'), findsOneWidget);
      expect(find.text('تحويل كامل قبل الشحن'), findsOneWidget);
    });
  });
}
