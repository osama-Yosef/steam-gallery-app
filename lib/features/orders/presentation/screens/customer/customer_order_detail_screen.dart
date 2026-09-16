import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../presentation/providers/order_providers.dart';
import '../../widgets/order_status_chips.dart';

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
                          Expanded(
                            child: Text(
                              'طلب #${order.orderNumber}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          OrderStatusChip(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.dateTime(order.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      // Order status and payment status are independent
                      // facts (0037) — an order can be "جاري التجهيز" and
                      // "مدفوع بالكامل" at the same time.
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: PaymentStatusChip(status: order.paymentStatus),
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
                if (order.deliveryRecipientName != null ||
                    order.deliveryPhone != null)
                  Text(
                    [
                      if (order.deliveryRecipientName != null)
                        order.deliveryRecipientName!,
                      if (order.deliveryPhone != null) order.deliveryPhone!,
                    ].join(' — '),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(order.deliveryAddress!),
                if (order.deliveryDetailsLine.isNotEmpty)
                  Text(order.deliveryDetailsLine),
                if (order.deliveryLandmark != null)
                  Text('علامة مميزة: ${order.deliveryLandmark}'),
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
