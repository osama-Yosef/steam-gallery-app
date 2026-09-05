import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/order.dart';
import '../../../presentation/providers/order_providers.dart';

class CustomerOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const CustomerOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final itemsAsync = ref.watch(orderItemsProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: orderAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الطلب'),
        data: (order) {
          if (order == null) {
            return const EmptyView(message: 'الطلب غير موجود');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'طلب #${order.orderNumber}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          _StatusChip(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.dateTime(order.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (order.cancelledReason != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'سبب الإلغاء: ${order.cancelledReason}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('المنتجات', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              itemsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => const Text('تعذَّر تحميل المنتجات'),
                data: (items) => Card(
                  child: Column(
                    children: items
                        .map(
                          (it) => ListTile(
                            title: Text(it.productNameSnapshot),
                            subtitle: Text('الكمية: ${it.quantity}'),
                            trailing: Text(Formatters.currency(it.lineTotal)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row(
                        context,
                        'الإجمالي',
                        Formatters.currency(order.total),
                      ),
                      _row(
                        context,
                        'المدفوع',
                        Formatters.currency(order.paidAmount),
                      ),
                      _row(
                        context,
                        'المتبقي',
                        Formatters.currency(order.remaining),
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (order.deliveryAddress != null) ...[
                const SizedBox(height: 16),
                Text(
                  'عنوان التوصيل',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(order.deliveryAddress!),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    final style = bold
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.pending => Colors.orange,
      OrderStatus.confirmed || OrderStatus.preparing => Colors.blue,
      OrderStatus.delivered || OrderStatus.completed => Colors.green,
      OrderStatus.cancelled ||
      OrderStatus.returned => Theme.of(context).colorScheme.error,
    };
    return Chip(
      label: Text(orderStatusLabelAr(status)),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color),
      side: BorderSide.none,
    );
  }
}
