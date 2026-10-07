import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../data/models/order.dart';
import '../order_status_chips.dart';

/// A full-width, colour-coded card — matches the customer order/maintenance
/// tiles: the order number reads first, and the status colour says what
/// stage it's at before the label is even read. The payment state gets its
/// own smaller pill since it's independent of the fulfilment status.
class AdminOrderTile extends StatelessWidget {
  final Order order;
  final String detailRoute;
  const AdminOrderTile({
    super.key,
    required this.order,
    required this.detailRoute,
  });

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(order.status);
    final payColor = paymentStatusColor(order.paymentStatus);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: color.withValues(alpha: 0.08),
          child: InkWell(
            onTap: () => context.push(detailRoute),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                    child: const Icon(
                      Iconsax.receipt_text_copy,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب #${order.orderNumber}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (order.deliveryRecipientName != null ||
                            order.deliveryPhone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (order.deliveryRecipientName != null)
                                order.deliveryRecipientName!,
                              if (order.deliveryPhone != null)
                                order.deliveryPhone!,
                            ].join(' — '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          Formatters.date(order.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(order.total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          orderStatusLabelAr(order.status),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        paymentStatusLabelAr(order.paymentStatus),
                        style: TextStyle(
                          color: payColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
