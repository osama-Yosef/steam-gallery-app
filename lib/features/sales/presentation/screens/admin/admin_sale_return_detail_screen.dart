import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../cashbox/data/models/cashbox_balance.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../../data/models/sale_return_item.dart';
import '../../providers/sales_providers.dart';

/// A walk-in sale's invoice, line by line, each with its own "إرجاع" —
/// return any quantity up to what's left on that line — plus a top action
/// to return everything still outstanding at once. See 0058.
///
/// Every return asks explicitly which till (نقدي/تحويل) the refund comes
/// out of, defaulting to how the sale was originally paid but overridable —
/// see 0063: leaving this to be silently inferred server-side meant a
/// return could succeed while the refund landed in a till nobody at the
/// counter was looking at, looking exactly like "no money was deducted".
class AdminSaleReturnDetailScreen extends ConsumerWidget {
  final String saleId;
  const AdminSaleReturnDetailScreen({super.key, required this.saleId});

  CashboxKind _defaultKind(PaymentMethod saleMethod) =>
      saleMethod == PaymentMethod.cash ? CashboxKind.cash : CashboxKind.transfer;

  Future<void> _returnItem(
    BuildContext context,
    WidgetRef ref,
    SaleReturnItem item,
    PaymentMethod saleMethod,
  ) async {
    var qty = 1;
    var refundKind = _defaultKind(saleMethod);
    final reasonCtrl = TextEditingController();
    final result = await showDialog<(int, String, CashboxKind)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('إرجاع ${item.productNameSnapshot}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.remainingQuantity > 1) ...[
                Text('الكمية (المتاح ${item.remainingQuantity})'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.minus_copy),
                      onPressed: qty > 1
                          ? () => setDialogState(() => qty--)
                          : null,
                    ),
                    Text('$qty', style: Theme.of(ctx).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Iconsax.add_copy),
                      onPressed: qty < item.remainingQuantity
                          ? () => setDialogState(() => qty++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'الفلوس هترجع من',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              SegmentedButton<CashboxKind>(
                segments: [
                  for (final k in CashboxKind.values)
                    ButtonSegment(value: k, label: Text(cashboxKindLabelAr(k))),
                ],
                selected: {refundKind},
                onSelectionChanged: (s) =>
                    setDialogState(() => refundKind = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'سبب الإرجاع'),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('تراجع'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(
                ctx,
              ).pop((qty, reasonCtrl.text.trim(), refundKind)),
              child: const Text('تأكيد الإرجاع'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result.$2.isEmpty || !context.mounted) return;

    try {
      await ref
          .read(salesRepositoryProvider)
          .returnSaleItem(
            saleItemId: item.id,
            quantity: result.$1,
            reason: result.$2,
            refundKind: result.$3,
          );
      ref.invalidate(saleReturnItemsProvider(saleId));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تسجيل المرتجع')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  Future<void> _returnWholeSale(
    BuildContext context,
    WidgetRef ref,
    PaymentMethod saleMethod,
  ) async {
    final reasonCtrl = TextEditingController();
    var refundKind = _defaultKind(saleMethod);
    final result = await showDialog<(String, CashboxKind)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إرجاع باقي الفاتورة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الفلوس هترجع من',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              SegmentedButton<CashboxKind>(
                segments: [
                  for (final k in CashboxKind.values)
                    ButtonSegment(value: k, label: Text(cashboxKindLabelAr(k))),
                ],
                selected: {refundKind},
                onSelectionChanged: (s) =>
                    setDialogState(() => refundKind = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'سبب الإرجاع'),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('تراجع'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(
                ctx,
              ).pop((reasonCtrl.text.trim(), refundKind)),
              child: const Text('تأكيد الإرجاع'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result.$1.isEmpty || !context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'تأكيد نهائي',
      message: 'هيتم رجوع كل الأصناف المتبقية للمخزن وخصم قيمتها من الخزنة.',
      confirmLabel: 'إرجاع الكل',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref
          .read(salesRepositoryProvider)
          .returnSale(
            saleId: saleId,
            reason: result.$1,
            refundKind: result.$2,
          );
      ref.invalidate(saleReturnItemsProvider(saleId));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إرجاع الفاتورة')));
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
    final itemsAsync = ref.watch(saleReturnItemsProvider(saleId));
    final saleAsync = ref.watch(saleByIdProvider(saleId));
    final saleMethod = saleAsync.value?.paymentMethod ?? PaymentMethod.cash;

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الفاتورة')),
      body: itemsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الفاتورة'),
        data: (items) {
          final anyRemaining = items.any((i) => i.remainingQuantity > 0);
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final fullyReturned = item.remainingQuantity == 0;
                    return Card(
                      color: fullyReturned
                          ? AppColors.danger.withValues(alpha: 0.06)
                          : null,
                      child: ListTile(
                        title: Text(item.productNameSnapshot),
                        subtitle: Text(
                          fullyReturned
                              ? 'اتُرجع بالكامل (${item.quantity})'
                              : 'الكمية: ${item.quantity}'
                                    '${item.returnedQuantity > 0 ? ' — اتُرجع ${item.returnedQuantity}' : ''}'
                                    ' • ${Formatters.currency(item.unitPriceSnapshot)}',
                        ),
                        trailing: fullyReturned
                            ? const Icon(
                                Iconsax.tick_circle_copy,
                                color: AppColors.danger,
                              )
                            : OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(
                                    color: AppColors.danger,
                                  ),
                                ),
                                onPressed: () =>
                                    _returnItem(context, ref, item, saleMethod),
                                child: const Text('إرجاع'),
                              ),
                      ),
                    );
                  },
                ),
              ),
              if (anyRemaining)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                      onPressed: () =>
                          _returnWholeSale(context, ref, saleMethod),
                      icon: const Icon(Iconsax.undo_copy),
                      label: const Text('إرجاع باقي الفاتورة'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
