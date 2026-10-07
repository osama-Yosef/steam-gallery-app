import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/core/offline/outbox.dart';
import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/core/utils/formatters.dart';
import 'package:steam_gallery_app/features/auth/data/models/app_user.dart';
import 'package:steam_gallery_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:steam_gallery_app/features/orders/data/models/order.dart';
import 'package:steam_gallery_app/features/orders/data/models/order_item.dart';
import 'package:steam_gallery_app/features/orders/data/repositories/order_repository.dart';
import 'package:steam_gallery_app/features/orders/presentation/providers/order_providers.dart';
import 'package:steam_gallery_app/features/orders/presentation/screens/admin/admin_order_detail_screen.dart';
import 'package:steam_gallery_app/features/technician_account/data/models/sale.dart';

import 'helpers/test_outbox.dart';

Order _order(
  OrderStatus status, {
  double paid = 0,
  String feeStatus = 'not_set',
  double? fee,
  String? rejection,
}) => Order.fromRow({
  'id': 'o1',
  'order_number': 7,
  'customer_id': 'c1',
  'status': status.name,
  'subtotal': 300,
  'discount': 0,
  'total': 300,
  'paid_amount': paid,
  'payment_status': paid >= 300 ? 'paid' : (paid > 0 ? 'partial' : 'unpaid'),
  'shipping_fee': fee,
  'shipping_fee_status': feeStatus,
  'shipping_fee_rejection_reason': rejection,
  'created_at': '2026-10-07T08:00:00Z',
});

class _FakeOrderRepo implements OrderRepository {
  final calls = <String>[];
  double? fee;
  ({double amount, PaymentMethod method, String orderId})? payment;
  OutboxResult result = const OutboxResult.done(null);
  Object? error;

  Future<OutboxResult> _act(String what) async {
    calls.add(what);
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<OutboxResult> setShippingFee({
    required String orderId,
    required double amount,
  }) {
    fee = amount;
    return _act('fee');
  }

  @override
  Future<OutboxResult> confirmOrder(String orderId) => _act('confirm');

  @override
  Future<OutboxResult> updateOrderStatus(String orderId, OrderStatus status) =>
      _act('status:${status.name}');

  @override
  Future<OutboxResult> cancelOrder(String orderId, String reason) =>
      _act('cancel:$reason');

  @override
  Future<OutboxResult> returnOrder(String orderId, String reason) =>
      _act('return:$reason');

  @override
  Future<OutboxResult> recordPayment({
    required String customerId,
    required double amount,
    String? orderId,
    String? notes,
    required String clientRequestId,
    required PaymentMethod paymentMethod,
  }) {
    payment = (amount: amount, method: paymentMethod, orderId: orderId!);
    return _act('payment');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  Order order,
  _FakeOrderRepo repo, {
  Outbox? outbox,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        orderRepositoryProvider.overrideWithValue(repo),
        outboxProvider.overrideWithValue(outbox ?? testOutbox()),
        orderDetailProvider('o1').overrideWith((ref) => Stream.value(order)),
        orderItemsProvider('o1').overrideWith(
          (ref) async => [
            OrderItem(
              id: 'i1',
              orderId: 'o1',
              productId: 'p1',
              productNameSnapshot: 'مكواة بخار',
              quantity: 3,
              unitPriceSnapshot: 100,
              discount: 0,
              lineTotal: 300,
              selectedOptions: const [],
            ),
          ],
        ),
        userProfileByIdProvider('c1').overrideWith(
          (ref) async => const AppUser(
            id: 'c1',
            role: AppRole.customer,
            fullName: 'منى',
            phone: '01099999999',
            isActive: true,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const AdminOrderDetailScreen(orderId: 'o1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapAndConfirm(WidgetTester tester, String button) async {
  await tester.tap(find.text(button));
  await tester.pumpAndSettle();
  await tester.tap(find.text('تأكيد').last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  testWidgets('shows the order, its customer, items and money', (tester) async {
    await _pump(tester, _order(OrderStatus.pending), _FakeOrderRepo());
    expect(find.text('طلب #7'), findsOneWidget);
    expect(find.text('منى'), findsOneWidget);
    expect(find.text('01099999999'), findsOneWidget);
    expect(find.text('مكواة بخار'), findsOneWidget);
    expect(find.text('${Formatters.currency(100)} × 3'), findsOneWidget);
    expect(find.text('لم يُحدَّد بعد'), findsWidgets);
  });

  testWidgets('pending: a shipping fee is set and sent to the customer', (
    tester,
  ) async {
    final repo = _FakeOrderRepo();
    await _pump(tester, _order(OrderStatus.pending), repo);
    // Can't confirm before the customer approves a fee (0065).
    final confirm = find.widgetWithText(FilledButton, 'تأكيد الطلب');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.tap(find.text('تحديد سعر الشحن'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'سعر الشحن'), '45');
    await tester.tap(find.text('إرسال للعميل'));
    await tester.pumpAndSettle();
    expect(repo.fee, 45);
    expect(find.text('تم التنفيذ بنجاح'), findsOneWidget);
  });

  testWidgets('a fee the customer turned down shows their reason', (
    tester,
  ) async {
    await _pump(
      tester,
      _order(
        OrderStatus.pending,
        feeStatus: 'rejected',
        fee: 80,
        rejection: 'غالي',
      ),
      _FakeOrderRepo(),
    );
    expect(find.text('سبب الرفض: غالي'), findsOneWidget);
    expect(find.text('تعديل سعر الشحن'), findsOneWidget);
  });

  testWidgets('approved fee: the order can be confirmed', (tester) async {
    final repo = _FakeOrderRepo();
    await _pump(
      tester,
      _order(OrderStatus.pending, feeStatus: 'approved', fee: 45),
      repo,
    );
    await _tapAndConfirm(tester, 'تأكيد الطلب');
    expect(repo.calls, ['confirm']);
  });

  for (final (status, button, next) in [
    (OrderStatus.confirmed, 'بدء التجهيز', OrderStatus.preparing),
    (OrderStatus.preparing, 'تم التسليم', OrderStatus.delivered),
    (OrderStatus.delivered, 'إتمام الطلب', OrderStatus.completed),
  ]) {
    testWidgets('${status.name}: "$button" moves it to ${next.name}', (
      tester,
    ) async {
      final repo = _FakeOrderRepo();
      await _pump(tester, _order(status, paid: 300), repo);
      await _tapAndConfirm(tester, button);
      expect(repo.calls, ['status:${next.name}']);
    });
  }

  testWidgets('a payment defaults to what is left, into the chosen till', (
    tester,
  ) async {
    final repo = _FakeOrderRepo();
    await _pump(tester, _order(OrderStatus.confirmed, paid: 100), repo);
    await tester.tap(find.text('تسجيل دفعة'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.widgetWithText(TextField, 'المبلغ'),
    );
    expect(field.controller!.text, '200.00');
    await tester.tap(find.text('تحويل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();
    expect(repo.payment!.amount, 200);
    expect(repo.payment!.method, PaymentMethod.transfer);
    expect(repo.payment!.orderId, 'o1');
  });

  testWidgets('a fully paid order has no payment button', (tester) async {
    await _pump(
      tester,
      _order(OrderStatus.confirmed, paid: 300),
      _FakeOrderRepo(),
    );
    expect(find.text('تسجيل دفعة'), findsNothing);
  });

  testWidgets('cancelling needs a reason', (tester) async {
    final repo = _FakeOrderRepo();
    await _pump(tester, _order(OrderStatus.confirmed), repo);
    await tester.tap(find.text('إلغاء الطلب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد الإلغاء'));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);

    await tester.tap(find.text('إلغاء الطلب'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'سبب الإلغاء'),
      'العميل اعتذر',
    );
    await tester.tap(find.text('تأكيد الإلغاء'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['cancel:العميل اعتذر']);
  });

  testWidgets('a finished order can\'t be cancelled', (tester) async {
    await _pump(
      tester,
      _order(OrderStatus.completed, paid: 300),
      _FakeOrderRepo(),
    );
    expect(find.text('إلغاء الطلب'), findsNothing);
  });

  testWidgets('a refusal shows the server\'s message', (tester) async {
    final repo = _FakeOrderRepo()
      ..error = const AppException('الكمية المطلوبة غير متوفرة');
    await _pump(
      tester,
      _order(OrderStatus.pending, feeStatus: 'approved', fee: 45),
      repo,
    );
    await _tapAndConfirm(tester, 'تأكيد الطلب');
    expect(find.text('الكمية المطلوبة غير متوفرة'), findsOneWidget);
  });

  testWidgets('offline: the step is saved, and shown as waiting to sync', (
    tester,
  ) async {
    final server = FakeServer()..online = false;
    final outbox = testOutbox(server: server);
    await outbox.submit(
      rpc: 'rpc_update_order_status',
      params: const {},
      label: 'طلب #7 · بدء التجهيز',
      kind: 'order',
      refId: 'o1',
    );
    final repo = _FakeOrderRepo()..result = const OutboxResult.queued();
    await _pump(tester, _order(OrderStatus.confirmed), repo, outbox: outbox);
    expect(find.text('مستني المزامنة'), findsOneWidget);
    expect(find.text('طلب #7 · بدء التجهيز'), findsOneWidget);

    await _tapAndConfirm(tester, 'بدء التجهيز');
    expect(find.textContaining('على الجهاز'), findsOneWidget);
  });
}
