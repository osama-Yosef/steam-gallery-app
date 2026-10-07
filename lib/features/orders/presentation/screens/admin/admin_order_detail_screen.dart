import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/offline/offline_widgets.dart';
import '../../../../../core/offline/outbox.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/order.dart';
import '../../../presentation/providers/order_providers.dart';
import '../../widgets/admin_order/order_actions.dart';
import '../../widgets/admin_order/order_address_card.dart';
import '../../widgets/admin_order/order_dialogs.dart';
import '../../widgets/admin_order/order_summary_cards.dart';
import '../../widgets/admin_order/shipping_fee_card.dart';
import '../../widgets/order_status_chips.dart';

/// One order as the admin works it: the shipping fee (0065), confirming,
/// each status step, payments, cancelling and returning. Every action goes
/// through the offline queue, and steps still waiting to be sent are shown.
///
/// The cards, buttons and dialogs live in `widgets/admin_order/`; this class
/// wires each action to the repository.
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
      () => ref.read(orderRepositoryProvider).confirmOrder(orderId),
    );
  }

  Future<void> _setShippingFee(
    BuildContext context,
    WidgetRef ref,
    double? currentFee,
  ) async {
    final amount = await askShippingFee(context, currentFee);
    if (amount == null || !context.mounted) return;
    await _run(
      context,
      () => ref
          .read(orderRepositoryProvider)
          .setShippingFee(orderId: orderId, amount: amount),
    );
  }

  Future<void> _advance(
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
      () =>
          ref.read(orderRepositoryProvider).updateOrderStatus(orderId, status),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reason = await askOrderReason(
      context,
      title: 'إلغاء الطلب',
      fieldLabel: 'سبب الإلغاء',
      confirmLabel: 'تأكيد الإلغاء',
    );
    if (reason == null || !context.mounted) return;
    await _run(
      context,
      () => ref.read(orderRepositoryProvider).cancelOrder(orderId, reason),
    );
  }

  Future<void> _return(BuildContext context, WidgetRef ref) async {
    final reason = await askOrderReason(
      context,
      title: 'استرجاع الطلب',
      fieldLabel: 'سبب الاسترجاع',
      confirmLabel: 'تأكيد الاسترجاع',
    );
    if (reason == null || !context.mounted) return;
    await _run(
      context,
      () => ref.read(orderRepositoryProvider).returnOrder(orderId, reason),
    );
  }

  Future<void> _recordPayment(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) async {
    final payment = await askOrderPayment(context, remaining: order.remaining);
    if (payment == null || !context.mounted) return;
    // The dialog is already closed, so this call can't be re-triggered by a
    // double tap; the key covers a retried request carrying the same entry.
    final clientRequestId = const Uuid().v4();
    await _run(
      context,
      () => ref
          .read(orderRepositoryProvider)
          .recordPayment(
            customerId: order.customerId,
            amount: payment.amount,
            orderId: orderId,
            clientRequestId: clientRequestId,
            paymentMethod: payment.method,
          ),
    );
  }

  /// Runs one action behind a non-dismissible spinner — mainly to stop a
  /// double tap firing it twice before the first reply lands — and says how
  /// it went.
  Future<void> _run(
    BuildContext context,
    Future<Object?> Function() action,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await action();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (result is OutboxResult && result.queued) {
        showSavedOfflineSnack(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم التنفيذ بنجاح')));
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outbox = ref.watch(outboxProvider);
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
              // Actions taken offline on this order, not sent yet — the
              // status above is still the server's until they are.
              ListenableBuilder(
                listenable: outbox,
                builder: (context, _) => _PendingSync(
                  entries: outbox.pendingOf('order', refId: orderId),
                ),
              ),
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
                const SizedBox(height: 12),
                OrderAddressCard(order: order),
              ],
              if (order.notes != null) ...[
                const SizedBox(height: 8),
                Text('ملاحظات: ${order.notes}'),
              ],
              const SizedBox(height: 8),
              const Text('طريقة الدفع: تحويل كامل قبل الشحن'),
              const SizedBox(height: 16),
              ShippingFeeCard(
                order: order,
                onSet: () => _setShippingFee(context, ref, order.shippingFee),
              ),
              const SizedBox(height: 16),
              Text('المنتجات', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              itemsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => const Text('تعذَّر تحميل المنتجات'),
                data: (items) => OrderItemsCard(items: items),
              ),
              const SizedBox(height: 16),
              OrderTotalsCard(order: order),
              const SizedBox(height: 24),
              OrderActions(
                order: order,
                onConfirm: () => _confirm(context, ref),
                onAdvance: (next) => _advance(context, ref, next),
                onRecordPayment: () => _recordPayment(context, ref, order),
                onCancel: () => _cancel(context, ref),
                onReturn: () => _return(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// "مستني المزامنة": the steps taken on this order offline, not sent yet.
class _PendingSync extends StatelessWidget {
  final List<OutboxEntry> entries;
  const _PendingSync({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Card(
      color: AppColors.warning.withValues(alpha: 0.1),
      child: ListTile(
        leading: const Icon(
          Icons.cloud_upload_outlined,
          color: AppColors.warning,
        ),
        title: const Text('مستني المزامنة'),
        subtitle: Text(entries.map((e) => e.label).join('\n')),
      ),
    );
  }
}
