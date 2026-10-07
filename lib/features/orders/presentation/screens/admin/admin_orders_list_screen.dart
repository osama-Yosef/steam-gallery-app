import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/data/models/app_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/order.dart';
import '../../../presentation/providers/order_providers.dart';
import '../../widgets/admin_order/admin_order_tile.dart';
import 'admin_orders_history_screen.dart';

/// Shared by the admin and sales roles — sales gets the exact same "handle
/// every order" view (see the widened order RPCs in migration 0044), just
/// reached under /sales/orders instead of /admin/orders.
///
/// Shows the orders still being worked plus today's, live; finished orders
/// from earlier days are in "السجل" ([AdminOrdersHistoryScreen]).
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
    final ordersAsync = ref.watch(openOrdersProvider);
    final isSales =
        ref.watch(currentUserProfileProvider).value?.role == AppRole.sales;
    String orderDetailRoute(String id) =>
        isSales ? Routes.salesOrderDetail(id) : Routes.adminOrderDetail(id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(
              isSales ? Routes.salesOrdersHistory : Routes.adminOrdersHistory,
            ),
            icon: const Icon(Iconsax.archive_book_copy),
            label: const Text('السجل'),
          ),
        ],
      ),
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
                    message: 'لا توجد طلبات مفتوحة أو جديدة النهارده',
                    icon: Iconsax.receipt_text_copy,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => AdminOrderTile(
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
