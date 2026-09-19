import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/data/models/app_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/order.dart';
import '../../../presentation/providers/order_providers.dart';
import '../../widgets/order_status_chips.dart';

/// Shared by the admin and sales roles — sales gets the exact same "handle
/// every order" view (see the widened order RPCs in migration 0044), just
/// reached under /sales/orders instead of /admin/orders.
class AdminOrdersListScreen extends ConsumerStatefulWidget {
  const AdminOrdersListScreen({super.key});

  @override
  ConsumerState<AdminOrdersListScreen> createState() =>
      _AdminOrdersListScreenState();
}

class _AdminOrdersListScreenState extends ConsumerState<AdminOrdersListScreen> {
  OrderStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allOrdersProvider);
    final isSales =
        ref.watch(currentUserProfileProvider).value?.role == AppRole.sales;
    String orderDetailRoute(String id) =>
        isSales ? Routes.salesOrderDetail(id) : Routes.adminOrderDetail(id);

    return Scaffold(
      appBar: AppBar(title: const Text('الطلبات')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'الكل',
                  selected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null),
                ),
                for (final s in OrderStatus.values) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: orderStatusLabelAr(s),
                    selected: _statusFilter == s,
                    onTap: () => setState(() => _statusFilter = s),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الطلبات'),
              data: (orders) {
                final filtered = _statusFilter == null
                    ? orders
                    : orders.where((o) => o.status == _statusFilter).toList();
                if (filtered.isEmpty) {
                  return const EmptyView(
                    message: 'لا توجد طلبات',
                    icon: Iconsax.receipt_text_copy,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _OrderTile(
                    order: filtered[i],
                    detailRoute: orderDetailRoute(filtered[i].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

/// A full-width, colour-coded card — matches the customer order/maintenance
/// tiles: the order number reads first, and the status colour says what
/// stage it's at before the label is even read. The payment state gets its
/// own smaller pill since it's independent of the fulfilment status.
class _OrderTile extends StatelessWidget {
  final Order order;
  final String detailRoute;
  const _OrderTile({required this.order, required this.detailRoute});

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
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
