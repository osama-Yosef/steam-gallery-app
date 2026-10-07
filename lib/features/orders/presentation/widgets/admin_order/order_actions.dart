import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/order.dart';

/// The next step an admin moves an order to from [status], with its button
/// label and icon — or null when the order has no forward step left (or,
/// for a pending order, when the step is confirming, which has its own
/// shipping-fee rule).
({OrderStatus next, String label, IconData icon})? nextOrderStep(
  OrderStatus status,
) => switch (status) {
  OrderStatus.confirmed => (
    next: OrderStatus.preparing,
    label: 'بدء التجهيز',
    icon: Iconsax.box_copy,
  ),
  OrderStatus.preparing => (
    next: OrderStatus.delivered,
    label: 'تم التسليم',
    icon: Iconsax.truck_copy,
  ),
  OrderStatus.delivered => (
    next: OrderStatus.completed,
    label: 'إتمام الطلب',
    icon: Iconsax.tick_square_copy,
  ),
  _ => null,
};

/// What an admin can do to [order] right now, as one row of same-sized
/// buttons.
class OrderActions extends StatelessWidget {
  final Order order;
  final VoidCallback onConfirm;
  final ValueChanged<OrderStatus> onAdvance;
  final VoidCallback onRecordPayment;
  final VoidCallback onCancel;
  final VoidCallback onReturn;

  const OrderActions({
    super.key,
    required this.order,
    required this.onConfirm,
    required this.onAdvance,
    required this.onRecordPayment,
    required this.onCancel,
    required this.onReturn,
  });

  bool get _closed => const [
    OrderStatus.completed,
    OrderStatus.cancelled,
    OrderStatus.returned,
  ].contains(order.status);

  bool get _canTakePayment =>
      order.remaining > 0 &&
      !const [
        OrderStatus.cancelled,
        OrderStatus.returned,
      ].contains(order.status);

  bool get _canReturn => const [
    OrderStatus.delivered,
    OrderStatus.completed,
  ].contains(order.status);

  @override
  Widget build(BuildContext context) {
    final step = nextOrderStep(order.status);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (order.status == OrderStatus.pending)
          FilledButton.icon(
            style: _style(),
            // 0065: confirming is blocked server-side until the customer
            // has approved a shipping fee — disabled here too so the button
            // doesn't invite a doomed tap.
            onPressed: order.shippingFeeStatus == ShippingFeeStatus.approved
                ? onConfirm
                : null,
            icon: const Icon(Iconsax.tick_circle_copy),
            label: const Text('تأكيد الطلب'),
          ),
        if (step != null)
          FilledButton.icon(
            style: _style(),
            onPressed: () => onAdvance(step.next),
            icon: Icon(step.icon),
            label: Text(step.label),
          ),
        if (_canTakePayment)
          OutlinedButton.icon(
            style: _style(foregroundColor: AppColors.warning),
            onPressed: onRecordPayment,
            icon: const Icon(Iconsax.wallet_money_copy),
            label: const Text('تسجيل دفعة'),
          ),
        if (!_closed)
          OutlinedButton.icon(
            style: _style(foregroundColor: AppColors.danger),
            onPressed: onCancel,
            icon: const Icon(Iconsax.close_circle_copy),
            label: const Text('إلغاء الطلب'),
          ),
        if (_canReturn)
          OutlinedButton.icon(
            style: _style(foregroundColor: AppColors.danger),
            onPressed: onReturn,
            icon: const Icon(Iconsax.undo_copy),
            label: const Text('استرجاع الطلب'),
          ),
      ],
    );
  }

  /// Every action button gets the same minimum size, so the row reads as one
  /// consistent set of actions instead of each button sizing to its own
  /// label length.
  ButtonStyle _style({Color? foregroundColor}) => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(150, 44)),
    foregroundColor: foregroundColor == null
        ? null
        : WidgetStatePropertyAll(foregroundColor),
    side: foregroundColor == null
        ? null
        : WidgetStatePropertyAll(BorderSide(color: foregroundColor)),
  );
}
