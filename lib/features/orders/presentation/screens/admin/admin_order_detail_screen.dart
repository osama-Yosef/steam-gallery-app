import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../../data/models/order.dart';
import '../../../presentation/providers/order_providers.dart';
import '../../widgets/order_status_chips.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'تأكيد الطلب',
      message: 'سيتم خصم الكمية من المخزن الرئيسي. متابعة؟',
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(orderRepositoryProvider).confirmOrder(orderId),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    OrderStatus status,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: 'تحديث الحالة',
      message: 'تغيير حالة الطلب إلى "${orderStatusLabelAr(status)}"؟',
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      ref,
      () =>
          ref.read(orderRepositoryProvider).updateOrderStatus(orderId, status),
    );
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(reasonCtrl.text.trim()),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(orderRepositoryProvider).cancelOrder(orderId, reason),
    );
  }

  Future<void> _returnOrder(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استرجاع الطلب'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'سبب الاسترجاع'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(reasonCtrl.text.trim()),
            child: const Text('تأكيد الاسترجاع'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(orderRepositoryProvider).returnOrder(orderId, reason),
    );
  }

  Future<void> _recordPayment(
    BuildContext context,
    WidgetRef ref,
    String customerId,
    double remaining,
  ) async {
    final amountCtrl = TextEditingController(
      text: remaining > 0 ? remaining.toStringAsFixed(2) : '',
    );
    var method = PaymentMethod.cash;
    final result = await showDialog<(double, PaymentMethod)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تسجيل دفعة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'المبلغ'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('استُلم الفلوس إزاي؟'),
              const SizedBox(height: 8),
              SegmentedButton<PaymentMethod>(
                segments: const [
                  ButtonSegment(
                    value: PaymentMethod.cash,
                    label: Text('نقدًا'),
                  ),
                  ButtonSegment(
                    value: PaymentMethod.transfer,
                    label: Text('تحويل'),
                  ),
                ],
                selected: {method},
                onSelectionChanged: (s) =>
                    setDialogState(() => method = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null) return;
                Navigator.of(ctx).pop((amount, method));
              },
              child: const Text('تسجيل'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result.$1 <= 0 || !context.mounted) return;
    // The dialog is already closed, so this call can't be re-triggered by a
    // double tap; the key covers a retried request carrying the same entry.
    final clientRequestId = const Uuid().v4();
    await _run(
      context,
      ref,
      () => ref
          .read(orderRepositoryProvider)
          .recordPayment(
            customerId: customerId,
            amount: result.$1,
            orderId: orderId,
            clientRequestId: clientRequestId,
            paymentMethod: result.$2,
          ),
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم التنفيذ بنجاح')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
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
          final customerAsync = ref.watch(
            userProfileByIdProvider(order.customerId),
          );
          final canCancel = ![
            OrderStatus.completed,
            OrderStatus.cancelled,
            OrderStatus.returned,
          ].contains(order.status);

          return ListView(
            padding: const EdgeInsets.all(16),
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
              Text(Formatters.dateTime(order.createdAt)),
              const SizedBox(height: 8),
              // Independent of order status on purpose (0037) — an admin
              // needs to see both facts at once.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: PaymentStatusChip(status: order.paymentStatus),
              ),
              const SizedBox(height: 12),
              customerAsync.when(
                data: (c) => Card(
                  child: ListTile(
                    leading: const Icon(Iconsax.profile_circle_copy),
                    title: Text(c?.fullName ?? '—'),
                    subtitle: Text(c?.phone ?? ''),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              if (order.deliveryAddress != null) ...[
                const SizedBox(height: 8),
                if (order.deliveryRecipientName != null ||
                    order.deliveryPhone != null)
                  Text(
                    [
                      if (order.deliveryRecipientName != null)
                        order.deliveryRecipientName!,
                      if (order.deliveryPhone != null) order.deliveryPhone!,
                    ].join(' — '),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                Text('عنوان التوصيل: ${order.deliveryAddress}'),
                if (order.deliveryDetailsLine.isNotEmpty)
                  Text(order.deliveryDetailsLine),
                if (order.deliveryLandmark != null)
                  Text('علامة مميزة: ${order.deliveryLandmark}'),
              ],
              if (order.notes != null) ...[
                const SizedBox(height: 8),
                Text('ملاحظات: ${order.notes}'),
              ],
              const SizedBox(height: 8),
              const Text('طريقة الدفع: تحويل كامل قبل الشحن'),
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
                            subtitle: Text(
                              it.selectedOptions.isEmpty
                                  ? '${Formatters.currency(it.unitPriceSnapshot)} × ${it.quantity}'
                                  : '${Formatters.currency(it.unitPriceSnapshot)} × ${it.quantity} — ${it.selectedOptions.map((o) => o.name).join('، ')}',
                            ),
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
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (order.status == OrderStatus.pending)
                    FilledButton.icon(
                      style: _actionButtonStyle(),
                      onPressed: () => _confirm(context, ref),
                      icon: const Icon(Iconsax.tick_circle_copy),
                      label: const Text('تأكيد الطلب'),
                    ),
                  if (order.status == OrderStatus.confirmed)
                    FilledButton.icon(
                      style: _actionButtonStyle(),
                      onPressed: () =>
                          _updateStatus(context, ref, OrderStatus.preparing),
                      icon: const Icon(Iconsax.box_copy),
                      label: const Text('بدء التجهيز'),
                    ),
                  if (order.status == OrderStatus.preparing)
                    FilledButton.icon(
                      style: _actionButtonStyle(),
                      onPressed: () =>
                          _updateStatus(context, ref, OrderStatus.delivered),
                      icon: const Icon(Iconsax.truck_copy),
                      label: const Text('تم التسليم'),
                    ),
                  if (order.status == OrderStatus.delivered)
                    FilledButton.icon(
                      style: _actionButtonStyle(),
                      onPressed: () =>
                          _updateStatus(context, ref, OrderStatus.completed),
                      icon: const Icon(Iconsax.tick_square_copy),
                      label: const Text('إتمام الطلب'),
                    ),
                  if (order.remaining > 0 &&
                      ![
                        OrderStatus.cancelled,
                        OrderStatus.returned,
                      ].contains(order.status))
                    OutlinedButton.icon(
                      style: _actionButtonStyle(
                        foregroundColor: AppColors.warning,
                      ),
                      onPressed: () => _recordPayment(
                        context,
                        ref,
                        order.customerId,
                        order.remaining,
                      ),
                      icon: const Icon(Iconsax.wallet_money_copy),
                      label: const Text('تسجيل دفعة'),
                    ),
                  if (canCancel)
                    OutlinedButton.icon(
                      style: _actionButtonStyle(
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: () => _cancel(context, ref),
                      icon: const Icon(Iconsax.close_circle_copy),
                      label: const Text('إلغاء الطلب'),
                    ),
                  if ([
                    OrderStatus.delivered,
                    OrderStatus.completed,
                  ].contains(order.status))
                    OutlinedButton.icon(
                      style: _actionButtonStyle(
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: () => _returnOrder(context, ref),
                      icon: const Icon(Iconsax.undo_copy),
                      label: const Text('استرجاع الطلب'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Every action button gets the same minimum size, so the row reads as one
  /// consistent set of actions instead of each button sizing to its own
  /// label length.
  ButtonStyle _actionButtonStyle({Color? foregroundColor}) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(150, 44)),
      foregroundColor: foregroundColor == null
          ? null
          : WidgetStatePropertyAll(foregroundColor),
      side: foregroundColor == null
          ? null
          : WidgetStatePropertyAll(BorderSide(color: foregroundColor)),
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
