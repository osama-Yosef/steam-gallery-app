import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:steam_gallery_app/features/orders/data/models/order.dart';
import 'package:steam_gallery_app/features/orders/presentation/widgets/order_status_chips.dart';

void main() {
  group('PaymentStatus (0037)', () {
    test('parses every value the database can send, unknown falls back to unpaid', () {
      expect(paymentStatusFromString('unpaid'), PaymentStatus.unpaid);
      expect(paymentStatusFromString('partially_paid'), PaymentStatus.partiallyPaid);
      expect(paymentStatusFromString('paid'), PaymentStatus.paid);
      expect(paymentStatusFromString('refunded'), PaymentStatus.refunded);
      expect(paymentStatusFromString('something_new'), PaymentStatus.unpaid);
    });

    test('every value has an Arabic label', () {
      for (final s in PaymentStatus.values) {
        expect(paymentStatusLabelAr(s), isNotEmpty);
      }
    });

    test('is independent of OrderStatus — both can be read off one Order', () {
      final o = Order.fromRow({
        'id': 'o1',
        'order_number': 1,
        'customer_id': 'c1',
        'status': 'preparing',
        'subtotal': 100,
        'discount': 0,
        'total': 100,
        'paid_amount': 100,
        'payment_status': 'paid',
        'created_at': '2026-09-17T00:00:00Z',
      });
      // The exact combination the master rule calls out: fulfilment is
      // still in progress while payment is already fully settled.
      expect(o.status, OrderStatus.preparing);
      expect(o.paymentStatus, PaymentStatus.paid);
    });
  });

  group('Status chips render the right label', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );

    testWidgets('OrderStatusChip', (tester) async {
      await pump(tester, const OrderStatusChip(status: OrderStatus.preparing));
      expect(find.text('جاري التجهيز'), findsOneWidget);
    });

    testWidgets('PaymentStatusChip', (tester) async {
      await pump(tester, const PaymentStatusChip(status: PaymentStatus.partiallyPaid));
      expect(find.text('مدفوع جزئيًا'), findsOneWidget);
    });

    testWidgets('PaymentStatusLabel (compact, for list rows)', (tester) async {
      await pump(tester, const PaymentStatusLabel(status: PaymentStatus.refunded));
      expect(find.text('تم الاسترداد'), findsOneWidget);
    });
  });
}
