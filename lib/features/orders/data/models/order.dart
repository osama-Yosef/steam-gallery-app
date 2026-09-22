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

/// Shipping fee negotiation (0065): admin/sales proposes a fee while the
/// order is still `pending`, the customer must approve it before the order
/// can be confirmed at all. [Order.total] only counts the fee once
/// [ShippingFeeStatus.approved] — a merely-proposed or rejected fee never
/// changes what the customer is shown as owing.
enum ShippingFeeStatus { notSet, pendingApproval, approved, rejected }

ShippingFeeStatus shippingFeeStatusFromString(String v) => switch (v) {
  'pending_approval' => ShippingFeeStatus.pendingApproval,
  'approved' => ShippingFeeStatus.approved,
  'rejected' => ShippingFeeStatus.rejected,
  _ => ShippingFeeStatus.notSet,
};

String shippingFeeStatusLabelAr(ShippingFeeStatus s) => switch (s) {
  ShippingFeeStatus.notSet => 'لم يُحدَّد بعد',
  ShippingFeeStatus.pendingApproval => 'بانتظار موافقة العميل',
  ShippingFeeStatus.approved => 'وافق العميل',
  ShippingFeeStatus.rejected => 'رفض العميل',
};

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
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryCityId,
    String? deliveryServiceAreaId,
    double? shippingFee,
    required ShippingFeeStatus shippingFeeStatus,
    String? shippingFeeRejectionReason,
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
    deliveryLatitude: (row['delivery_latitude'] as num?)?.toDouble(),
    deliveryLongitude: (row['delivery_longitude'] as num?)?.toDouble(),
    deliveryCityId: row['delivery_city_id'] as String?,
    deliveryServiceAreaId: row['delivery_service_area_id'] as String?,
    shippingFee: (row['shipping_fee'] as num?)?.toDouble(),
    shippingFeeStatus: shippingFeeStatusFromString(
      row['shipping_fee_status'] as String? ?? 'not_set',
    ),
    shippingFeeRejectionReason: row['shipping_fee_rejection_reason'] as String?,
    notes: row['notes'] as String?,
    cancelledReason: row['cancelled_reason'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
