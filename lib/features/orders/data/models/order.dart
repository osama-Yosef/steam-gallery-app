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

/// Whether the order was PAID — independent of [OrderStatus] (0037). A
/// cancelled-and-refunded order is `cancelled` + `refunded` at the same
/// time; a delivered order can still be `partiallyPaid` (deferred payment).
enum PaymentStatus { unpaid, partiallyPaid, paid, refunded }

PaymentStatus paymentStatusFromString(String v) => switch (v) {
  'partially_paid' => PaymentStatus.partiallyPaid,
  'paid' => PaymentStatus.paid,
  'refunded' => PaymentStatus.refunded,
  _ => PaymentStatus.unpaid,
};

String paymentStatusLabelAr(PaymentStatus s) => switch (s) {
  PaymentStatus.unpaid => 'غير مدفوع',
  PaymentStatus.partiallyPaid => 'مدفوع جزئيًا',
  PaymentStatus.paid => 'مدفوع بالكامل',
  PaymentStatus.refunded => 'تم الاسترداد',
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
    required PaymentStatus paymentStatus,
    String? deliveryAddress,
    // Snapshotted from customer_addresses at order time (0036) — never the
    // live address row, so editing/deleting a saved address never rewrites
    // a past order's delivery details.
    String? deliveryRecipientName,
    String? deliveryPhone,
    String? deliveryBuilding,
    String? deliveryFloor,
    String? deliveryApartment,
    String? deliveryLandmark,
    String? notes,
    String? cancelledReason,
    required DateTime createdAt,
  }) = _Order;

  const Order._();

  double get remaining => total - paidAmount;

  /// "عمارة 12، الدور 3، شقة 7" from the snapshot — mirrors
  /// CustomerAddress.detailsLine, only the parts that were filled in.
  String get deliveryDetailsLine => [
    if (deliveryBuilding != null) 'عمارة $deliveryBuilding',
    if (deliveryFloor != null) 'الدور $deliveryFloor',
    if (deliveryApartment != null) 'شقة $deliveryApartment',
  ].join('، ');

  factory Order.fromRow(Map<String, dynamic> row) => Order(
    id: row['id'] as String,
    orderNumber: row['order_number'] as int,
    customerId: row['customer_id'] as String,
    status: orderStatusFromString(row['status'] as String),
    subtotal: (row['subtotal'] as num).toDouble(),
    discount: (row['discount'] as num).toDouble(),
    total: (row['total'] as num).toDouble(),
    paidAmount: (row['paid_amount'] as num).toDouble(),
    paymentStatus: paymentStatusFromString(row['payment_status'] as String),
    deliveryAddress: row['delivery_address'] as String?,
    deliveryRecipientName: row['delivery_recipient_name'] as String?,
    deliveryPhone: row['delivery_phone'] as String?,
    deliveryBuilding: row['delivery_building'] as String?,
    deliveryFloor: row['delivery_floor'] as String?,
    deliveryApartment: row['delivery_apartment'] as String?,
    deliveryLandmark: row['delivery_landmark'] as String?,
    notes: row['notes'] as String?,
    cancelledReason: row['cancelled_reason'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
