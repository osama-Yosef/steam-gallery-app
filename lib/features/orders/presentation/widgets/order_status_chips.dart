import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/order.dart';

Color orderStatusColor(OrderStatus status) => switch (status) {
  OrderStatus.pending => AppColors.warning,
  OrderStatus.confirmed || OrderStatus.preparing => AppColors.info,
  OrderStatus.delivered || OrderStatus.completed => AppColors.success,
  OrderStatus.cancelled || OrderStatus.returned => AppColors.danger,
};

Color paymentStatusColor(PaymentStatus status) => switch (status) {
  PaymentStatus.unpaid => AppColors.warning,
  PaymentStatus.partiallyPaid => AppColors.info,
  PaymentStatus.paid => AppColors.success,
  PaymentStatus.refunded => AppColors.textSecondary,
};

/// Fulfilment state — pending/confirmed/preparing/delivered/completed, or
/// cancelled/returned. Shared by the customer and admin order screens.
class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status);
    return Chip(
      label: Text(orderStatusLabelAr(status)),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color),
      side: BorderSide.none,
    );
  }
}

/// Payment state (0037) — deliberately independent of [OrderStatusChip]:
/// an order can be `preparing` and `paid` at once, or `cancelled` and
/// `refunded` at once. Never inferred client-side; always the server's
/// [Order.paymentStatus].
class PaymentStatusChip extends StatelessWidget {
  final PaymentStatus status;
  const PaymentStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = paymentStatusColor(status);
    return Chip(
      label: Text(paymentStatusLabelAr(status)),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color),
      side: BorderSide.none,
    );
  }
}

/// A compact text-only label for list rows, where a full [Chip] would be too
/// heavy next to the price.
class PaymentStatusLabel extends StatelessWidget {
  final PaymentStatus status;
  const PaymentStatusLabel({super.key, required this.status});

  @override
  Widget build(BuildContext context) => Text(
    paymentStatusLabelAr(status),
    style: TextStyle(
      color: paymentStatusColor(status),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  );
}
