import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale.freezed.dart';

enum PaymentMethod { cash, card, transfer, deferred }

PaymentMethod paymentMethodFromString(String v) => switch (v) {
  'cash' => PaymentMethod.cash,
  'card' => PaymentMethod.card,
  'transfer' => PaymentMethod.transfer,
  'deferred' => PaymentMethod.deferred,
  _ => PaymentMethod.cash,
};

String paymentMethodToString(PaymentMethod m) => switch (m) {
  PaymentMethod.cash => 'cash',
  PaymentMethod.card => 'card',
  PaymentMethod.transfer => 'transfer',
  PaymentMethod.deferred => 'deferred',
};

String paymentMethodLabelAr(PaymentMethod m) => switch (m) {
  PaymentMethod.cash => 'نقدًا',
  PaymentMethod.card => 'بطاقة',
  PaymentMethod.transfer => 'تحويل',
  PaymentMethod.deferred => 'آجل',
};

enum SaleStatus { completed, returned, cancelled }

SaleStatus saleStatusFromString(String v) => switch (v) {
  'completed' => SaleStatus.completed,
  'returned' => SaleStatus.returned,
  'cancelled' => SaleStatus.cancelled,
  _ => SaleStatus.completed,
};

String saleStatusLabelAr(SaleStatus s) => switch (s) {
  SaleStatus.completed => 'مكتمل',
  SaleStatus.returned => 'مرتجع',
  SaleStatus.cancelled => 'ملغي',
};

@freezed
abstract class Sale with _$Sale {
  const factory Sale({
    required String id,
    required int saleNumber,
    String? customerName,
    String? customerPhone,
    required PaymentMethod paymentMethod,
    required double subtotal,
    required double discount,
    required double total,
    required double paidAmount,
    required SaleStatus status,
    required DateTime createdAt,
  }) = _Sale;

  factory Sale.fromRow(Map<String, dynamic> row) => Sale(
    id: row['id'] as String,
    saleNumber: row['sale_number'] as int,
    customerName: row['customer_name'] as String?,
    customerPhone: row['customer_phone'] as String?,
    paymentMethod: paymentMethodFromString(row['payment_method'] as String),
    subtotal: (row['subtotal'] as num).toDouble(),
    discount: (row['discount'] as num).toDouble(),
    total: (row['total'] as num).toDouble(),
    paidAmount: (row['paid_amount'] as num).toDouble(),
    status: saleStatusFromString(row['status'] as String),
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
