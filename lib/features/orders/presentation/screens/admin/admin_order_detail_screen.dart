import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/order.dart';
import '../../../presentation/providers/order_providers.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(context,
        title: 'تأكيد الطلب', message: 'سيتم خصم الكمية من المخزن الرئيسي. متابعة؟');
    if (!ok) return;
    await _run(context, ref, () => ref.read(orderRepositoryProvider).confirmOrder(orderId));
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, OrderStatus status) async {
    final ok = await showConfirmDialog(context,
        title: 'تحديث الحالة', message: 'تغيير حالة الطلب إلى "${orderStatusLabelAr(status)}"؟');
    if (!ok) return;
    await _run(context, ref, () => ref.read(orderRepositoryProvider).updateOrderStatus(orderId, status));
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'سبب الإلغاء'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('تراجع')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(reasonCtrl.text.trim()),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    await _run(context, ref, () => ref.read(orderRepositoryProvider).cancelOrder(orderId, reason));
  }

  Future<void> _recordPayment(BuildContext context, WidgetRef ref, String customerId, double remaining) async {
    final amountCtrl = TextEditingController(text: remaining > 0 ? remaining.toStringAsFixed(2) : '');
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل دفعة'),
        content: TextField(
          controller: amountCtrl,
          decoration: const InputDecoration(labelText: 'المبلغ'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(double.tryParse(amountCtrl.text)),
            child: const Text('تسجيل'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    await _run(
      context,
      ref,
      () => ref.read(orderRepositoryProvider).recordPayment(customerId: customerId, amount: amount, orderId: orderId),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التنفيذ بنجاح')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

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
          if (order == null) return const EmptyView(message: 'الطلب غير موجود');
          final customerAsync = ref.watch(userProfileByIdProvider(order.customerId));
          final canCancel = ![OrderStatus.completed, OrderStatus.cancelled, OrderStatus.returned]
              .contains(order.status);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('طلب #${order.orderNumber}', style: Theme.of(context).textTheme.titleLarge),
                  Chip(label: Text(orderStatusLabelAr(order.status))),
                ],
              ),
              const SizedBox(height: 4),
              Text(Formatters.dateTime(order.createdAt)),
              const SizedBox(height: 12),
              customerAsync.when(
                data: (c) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(c?.fullName ?? '—'),
                    subtitle: Text(c?.phone ?? ''),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              if (order.deliveryAddress != null) ...[
                const SizedBox(height: 8),
                Text('عنوان التوصيل: ${order.deliveryAddress}'),
              ],
              if (order.notes != null) ...[
                const SizedBox(height: 8),
                Text('ملاحظات: ${order.notes}'),
              ],
              const SizedBox(height: 16),
              Text('المنتجات', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              itemsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => const Text('تعذَّر تحميل المنتجات'),
                data: (items) => Card(
                  child: Column(
                    children: items
                        .map((it) => ListTile(
                              title: Text(it.productNameSnapshot),
                              subtitle: Text('${Formatters.currency(it.unitPriceSnapshot)} × ${it.quantity}'),
                              trailing: Text(Formatters.currency(it.lineTotal)),
                            ))
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
                      _row(context, 'الإجمالي', Formatters.currency(order.total)),
                      _row(context, 'المدفوع', Formatters.currency(order.paidAmount)),
                      _row(context, 'المتبقي', Formatters.currency(order.remaining), bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (order.status == OrderStatus.pending)
                    FilledButton.icon(
                      onPressed: () => _confirm(context, ref),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('تأكيد الطلب'),
                    ),
                  if (order.status == OrderStatus.confirmed)
                    FilledButton.icon(
                      onPressed: () => _updateStatus(context, ref, OrderStatus.preparing),
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('بدء التجهيز'),
                    ),
                  if (order.status == OrderStatus.preparing)
                    FilledButton.icon(
                      onPressed: () => _updateStatus(context, ref, OrderStatus.delivered),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('تم التسليم'),
                    ),
                  if (order.status == OrderStatus.delivered)
                    FilledButton.icon(
                      onPressed: () => _updateStatus(context, ref, OrderStatus.completed),
                      icon: const Icon(Icons.done_all),
                      label: const Text('إتمام الطلب'),
                    ),
                  if (order.remaining > 0 &&
                      ![OrderStatus.cancelled, OrderStatus.returned].contains(order.status))
                    OutlinedButton.icon(
                      onPressed: () =>
                          _recordPayment(context, ref, order.customerId, order.remaining),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('تسجيل دفعة'),
                    ),
                  if (canCancel)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      onPressed: () => _cancel(context, ref),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('إلغاء الطلب'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
