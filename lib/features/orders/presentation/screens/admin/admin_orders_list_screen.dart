import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/order.dart';
import '../../../presentation/providers/order_providers.dart';

class AdminOrdersListScreen extends ConsumerStatefulWidget {
  const AdminOrdersListScreen({super.key});

  @override
  ConsumerState<AdminOrdersListScreen> createState() => _AdminOrdersListScreenState();
}

class _AdminOrdersListScreenState extends ConsumerState<AdminOrdersListScreen> {
  OrderStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allOrdersProvider);

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
                _FilterChip(label: 'الكل', selected: _statusFilter == null,
                    onTap: () => setState(() => _statusFilter = null)),
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
                final filtered =
                    _statusFilter == null ? orders : orders.where((o) => o.status == _statusFilter).toList();
                if (filtered.isEmpty) {
                  return const EmptyView(message: 'لا توجد طلبات', icon: Icons.receipt_long_outlined);
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final o = filtered[i];
                    return ListTile(
                      title: Text('طلب #${o.orderNumber}'),
                      subtitle: Text('${orderStatusLabelAr(o.status)} · ${Formatters.date(o.createdAt)}'),
                      trailing: Text(Formatters.currency(o.total)),
                      onTap: () => context.push(Routes.adminOrderDetail(o.id)),
                    );
                  },
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
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}
