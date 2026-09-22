import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../wallet/presentation/providers/wallet_providers.dart';
import '../../../data/models/order.dart';
import '../../../presentation/providers/order_providers.dart';
import '../../widgets/order_status_chips.dart';

class CustomerOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const CustomerOrderDetailScreen({super.key, required this.orderId});

  Future<void> _respondShippingFee(
    BuildContext context,
    WidgetRef ref,
    bool approve,
  ) async {
    String? reason;
    if (!approve) {
      final reasonCtrl = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('رفض سعر الشحن'),
          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(labelText: 'السبب'),
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
              child: const Text('تأكيد الرفض'),
            ),
          ],
        ),
      );
      if (reason == null || reason.isEmpty || !context.mounted) return;
    } else {
      final confirmed = await showConfirmDialog(
        context,
        title: 'الموافقة على سعر الشحن',
        message: 'هيتم إضافة سعر الشحن لإجمالي طلبك والمتابعة في التجهيز.',
        confirmLabel: 'موافق',
      );
      if (!confirmed || !context.mounted) return;
    }

    try {
      await ref
          .read(orderRepositoryProvider)
          .respondToShippingFee(
            orderId: orderId,
            approve: approve,
            rejectionReason: reason,
          );
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
              if (order.shippingFeeStatus == ShippingFeeStatus.pendingApproval ||
                  order.shippingFeeStatus == ShippingFeeStatus.rejected) ...[
                const SizedBox(height: 12),
                _ShippingFeeApprovalCard(
                  order: order,
                  onRespond: (approve) =>
                      _respondShippingFee(context, ref, approve),
                ),
              ],
              const SizedBox(height: 12),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Iconsax.wallet_money_copy),
                title: Text('طريقة الدفع'),
                subtitle: Text('تحويل كامل قبل الشحن'),
              ),
              const SizedBox(height: 4),
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
                                  ? 'الكمية: ${it.quantity}'
                                  : 'الكمية: ${it.quantity} — ${it.selectedOptions.map((o) => o.name).join('، ')}',
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
                      if (order.shippingFeeStatus == ShippingFeeStatus.approved &&
                          order.shippingFee != null)
                        _row(
                          context,
                          'رسوم الشحن',
                          Formatters.currency(order.shippingFee!),
                        ),
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
              if (order.remaining > 0 &&
                  order.paymentStatus != PaymentStatus.refunded &&
                  ![
                    OrderStatus.cancelled,
                    OrderStatus.returned,
                  ].contains(order.status)) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    Routes.customerInstapayPayment(order.id),
                  ),
                  icon: const Icon(Iconsax.bank_copy),
                  label: const Text('ادفع عبر InstaPay'),
                ),
                const SizedBox(height: 8),
                _WalletPayButton(orderId: order.id, amount: order.remaining),
              ],
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

/// The customer's answer to a proposed shipping fee (0065) — the order
/// can't be confirmed until they approve one. Shown while pending, and
/// again (informationally) if they already rejected one, since the same
/// screen is where they'll see the next proposal too.
class _ShippingFeeApprovalCard extends StatelessWidget {
  final Order order;
  final void Function(bool approve) onRespond;
  const _ShippingFeeApprovalCard({required this.order, required this.onRespond});

  @override
  Widget build(BuildContext context) {
    final rejected = order.shippingFeeStatus == ShippingFeeStatus.rejected;
    return Card(
      color: AppColors.warning.withValues(alpha: 0.08),
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
                  rejected ? 'في انتظار سعر شحن جديد' : 'تكلفة شحن طلبك',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (rejected)
              Text(
                'رفضت سعر الشحن السابق (${Formatters.currency(order.shippingFee ?? 0)})'
                '، وفي انتظار المعرض يحدد سعر جديد.',
              )
            else ...[
              Text(
                'المعرض حدد سعر الشحن بـ ${Formatters.currency(order.shippingFee ?? 0)}. '
                'يجب الموافقة عليه لإتمام الطلب.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => onRespond(true),
                      child: const Text('موافق'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      onPressed: () => onRespond(false),
                      child: const Text('رفض'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Instant, no admin review needed — the money already cleared when the
/// wallet was topped up (rpc_pay_order_from_wallet, 0040). Confirmed first
/// since spending it is immediate and cannot be undone from the app.
class _WalletPayButton extends ConsumerStatefulWidget {
  final String orderId;
  final double amount;
  const _WalletPayButton({required this.orderId, required this.amount});

  @override
  ConsumerState<_WalletPayButton> createState() => _WalletPayButtonState();
}

class _WalletPayButtonState extends ConsumerState<_WalletPayButton> {
  bool _paying = false;

  Future<void> _pay() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'الدفع من المحفظة',
      message:
          'هيتم خصم ${Formatters.currency(widget.amount)} من رصيد محفظتك الآن. متأكد؟',
      confirmLabel: 'ادفع',
    );
    if (!confirmed || !mounted) return;

    setState(() => _paying = true);
    try {
      await ref
          .read(walletRepositoryProvider)
          .payOrderFromWallet(
            orderId: widget.orderId,
            amount: widget.amount,
            clientRequestId: const Uuid().v4(),
          );
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(myWalletProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(myWalletProvider).value;
    return OutlinedButton.icon(
      onPressed: _paying ? null : _pay,
      icon: _paying
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Iconsax.wallet_copy),
      label: Text(
        wallet == null
            ? 'ادفع من المحفظة'
            : 'ادفع من المحفظة (الرصيد: ${Formatters.currency(wallet.balance)})',
      ),
    );
  }
}
