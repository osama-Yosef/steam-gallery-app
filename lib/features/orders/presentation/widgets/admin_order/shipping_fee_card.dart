import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../data/models/order.dart';

/// Shipping-fee negotiation status (0065) — set/re-set while pending, and
/// what the customer answered once they have.
class ShippingFeeCard extends StatelessWidget {
  final Order order;
  final VoidCallback onSet;
  const ShippingFeeCard({super.key, required this.order, required this.onSet});

  @override
  Widget build(BuildContext context) {
    final canSet = order.status == OrderStatus.pending;
    final color = switch (order.shippingFeeStatus) {
      ShippingFeeStatus.approved => AppColors.success,
      ShippingFeeStatus.rejected => AppColors.danger,
      ShippingFeeStatus.pendingApproval => AppColors.warning,
      ShippingFeeStatus.notSet => AppColors.textSecondary,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.truck_copy, size: 18),
                const SizedBox(width: 6),
                Text(
                  'سعر الشحن',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.shippingFee == null
                      ? 'لم يُحدَّد بعد'
                      : Formatters.currency(order.shippingFee!),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  shippingFeeStatusLabelAr(order.shippingFeeStatus),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (order.shippingFeeStatus == ShippingFeeStatus.rejected &&
                order.shippingFeeRejectionReason != null) ...[
              const SizedBox(height: 4),
              Text(
                'سبب الرفض: ${order.shippingFeeRejectionReason}',
                style: TextStyle(color: AppColors.danger),
              ),
            ],
            if (canSet) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onSet,
                  style: FilledButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                  ),
                  icon: const Icon(Iconsax.dollar_circle_copy, size: 18),
                  label: Text(
                    order.shippingFeeStatus == ShippingFeeStatus.notSet
                        ? 'تحديد سعر الشحن'
                        : 'تعديل سعر الشحن',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
