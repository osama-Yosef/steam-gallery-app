import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  delivered,
  completed,
  cancelled,
  returned,
}

OrderStatus orderStatusFromString(String v) => OrderStatus.values.firstWhere(
  (s) => s.name == v,
  orElse: () => OrderStatus.pending,
);

String orderStatusLabelAr(OrderStatus s) => switch (s) {
  OrderStatus.pending => 'قيد المراجعة',
  OrderStatus.confirmed => 'تم التأكيد',
  OrderStatus.preparing => 'جاري التجهيز',
  OrderStatus.delivered => 'تم التسليم',
  OrderStatus.completed => 'مكتمل',
  OrderStatus.cancelled => 'ملغي',
  OrderStatus.returned => 'مرتجع',
};

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required int orderNumber,
    required String customerId,
    required OrderStatus status,
    required double subtotal,
    required double discount,
    required double total,
    required double paidAmount,
    String? deliveryAddress,
    String? notes,
    String? cancelledReason,
    required DateTime createdAt,
  }) = _Order;

  const Order._();

  double get remaining => total - paidAmount;

  factory Order.fromRow(Map<String, dynamic> row) => Order(
    id: row['id'] as String,
    orderNumber: row['order_number'] as int,
    customerId: row['customer_id'] as String,
    status: orderStatusFromString(row['status'] as String),
    subtotal: (row['subtotal'] as num).toDouble(),
    discount: (row['discount'] as num).toDouble(),
    total: (row['total'] as num).toDouble(),
    paidAmount: (row['paid_amount'] as num).toDouble(),
    deliveryAddress: row['delivery_address'] as String?,
    notes: row['notes'] as String?,
    cancelledReason: row['cancelled_reason'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
