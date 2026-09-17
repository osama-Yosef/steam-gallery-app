import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:steam_gallery_app/core/theme/app_theme.dart';
import 'package:steam_gallery_app/features/auth/data/models/app_user.dart';
import 'package:steam_gallery_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:steam_gallery_app/features/orders/data/models/order.dart';
import 'package:steam_gallery_app/features/orders/data/models/order_item.dart';
import 'package:steam_gallery_app/features/orders/data/repositories/order_repository.dart';
import 'package:steam_gallery_app/features/orders/presentation/providers/order_providers.dart';
import 'package:steam_gallery_app/features/orders/presentation/screens/admin/admin_order_detail_screen.dart';

Order _order(OrderStatus status, {double paidAmount = 0}) => Order.fromRow({
  'id': 'o1',
  'order_number': 1,
  'customer_id': 'c1',
  'status': status.name,
  'subtotal': 100,
  'discount': 0,
  'total': 100,
  'paid_amount': paidAmount,
  'payment_status': paidAmount >= 100 ? 'paid' : 'unpaid',
  'created_at': '2026-09-17T00:00:00Z',
});

class _FakeOrderRepo implements OrderRepository {
  final returnCalls = <({String orderId, String reason})>[];

  @override
  Future<void> returnOrder(String orderId, String reason) async {
    returnCalls.add((orderId: orderId, reason: reason));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  Order order,
  OrderRepository repo,
) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        orderRepositoryProvider.overrideWithValue(repo),
        orderDetailProvider('o1').overrideWith((ref) => Stream.value(order)),
        orderItemsProvider('o1').overrideWith((ref) async => <OrderItem>[]),
        userProfileByIdProvider('c1').overrideWith(
          (ref) async => const AppUser(
            id: 'c1',
            role: AppRole.customer,
            fullName: 'عميل تجريبي',
            isActive: true,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: AdminOrderDetailScreen(orderId: 'o1'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('AdminOrderDetailScreen — return (Phase 14)', () {
    testWidgets('the return button only shows for delivered/completed orders', (
      tester,
    ) async {
      await _pump(tester, _order(OrderStatus.confirmed), _FakeOrderRepo());
      expect(find.text('استرجاع الطلب'), findsNothing);
    });

    testWidgets('shows for a delivered order and asks for a reason first', (
      tester,
    ) async {
      final repo = _FakeOrderRepo();
      await _pump(tester, _order(OrderStatus.delivered, paidAmount: 100), repo);
      expect(find.text('استرجاع الطلب'), findsOneWidget);

      await tester.tap(find.text('استرجاع الطلب'));
      await tester.pumpAndSettle();
      expect(find.text('تأكيد الاسترجاع'), findsOneWidget);

      // Confirming with an empty reason does not call the repository.
      await tester.tap(find.text('تأكيد الاسترجاع'));
      await tester.pumpAndSettle();
      expect(repo.returnCalls, isEmpty);

      await tester.tap(find.text('استرجاع الطلب'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'المنتج به عيب');
      await tester.tap(find.text('تأكيد الاسترجاع'));
      await tester.pumpAndSettle();
      expect(repo.returnCalls, hasLength(1));
      expect(repo.returnCalls.single.orderId, 'o1');
      expect(repo.returnCalls.single.reason, 'المنتج به عيب');
    });

    testWidgets('also shows for a completed order', (tester) async {
      await _pump(tester, _order(OrderStatus.completed, paidAmount: 100), _FakeOrderRepo());
      expect(find.text('استرجاع الطلب'), findsOneWidget);
    });

    testWidgets('does not show for an already-returned order', (tester) async {
      await _pump(tester, _order(OrderStatus.returned), _FakeOrderRepo());
      expect(find.text('استرجاع الطلب'), findsNothing);
    });
  });
}
