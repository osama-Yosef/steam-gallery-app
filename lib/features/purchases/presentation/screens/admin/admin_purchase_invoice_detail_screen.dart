import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/purchase_models.dart';
import '../../providers/purchases_providers.dart';
import '../../widgets/pay_supplier_dialog.dart';

class AdminPurchaseInvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;
  const AdminPurchaseInvoiceDetailScreen({super.key, required this.invoiceId});

  void _refresh(WidgetRef ref) {
    ref.invalidate(purchaseInvoiceProvider(invoiceId));
    ref.invalidate(purchaseInvoicePaymentsProvider(invoiceId));
    ref.invalidate(purchaseInvoicesProvider);
    ref.invalidate(suppliersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(purchaseInvoiceProvider(invoiceId));
    final itemsAsync = ref.watch(purchaseInvoiceItemsProvider(invoiceId));
    final paymentsAsync = ref.watch(purchaseInvoicePaymentsProvider(invoiceId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('فاتورة شراء')),
      body: invoiceAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل الفاتورة',
          onRetry: () => _refresh(ref),
        ),
        data: (inv) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'فاتورة #${inv.invoiceNumber}',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text('المورد: ${inv.supplierName}'),
                    if (inv.supplierPhone != null)
                      Text('التليفون: ${inv.supplierPhone}'),
                    Text('التاريخ: ${Formatters.date(inv.invoiceDate)}'),
                    if (inv.supplierInvoiceRef != null)
                      Text('رقم فاتورة المورد: ${inv.supplierInvoiceRef}'),
                    if (inv.notes != null) Text('ملاحظات: ${inv.notes}'),
                    const Divider(height: 24),
                    _Row('الإجمالي قبل الخصم', inv.subtotal),
                    _Row('الخصم', inv.discount),
                    _Row('صافي الفاتورة', inv.total, bold: true),
                    _Row('المدفوع', inv.paidAmount),
                    _Row('المتبقي (آجل)', inv.remainingAmount, bold: true),
                    if (inv.remainingAmount > 0) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () async {
                          final paid = await showPaySupplierDialog(
                            context,
                            ref,
                            supplierId: inv.supplierId,
                            supplierName: inv.supplierName,
                            maxAmount: inv.remainingAmount,
                            invoiceId: inv.id,
                          );
                          if (paid) _refresh(ref);
                        },
                        icon: const Icon(Iconsax.money_send_copy),
                        label: const Text('سداد'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('الأصناف', style: theme.textTheme.titleMedium),
            itemsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Text('تعذَّر تحميل الأصناف'),
              data: (items) => Card(
                child: Column(
                  children: [
                    for (final i in items)
                      ListTile(
                        title: Text(i.productName),
                        subtitle: Text(
                          '${i.quantity} × ${Formatters.currency(i.unitCost)}',
                        ),
                        trailing: Text(Formatters.currency(i.lineTotal)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('المدفوعات', style: theme.textTheme.titleMedium),
            paymentsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (payments) => payments.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('لا توجد مدفوعات — الفاتورة آجل بالكامل'),
                    )
                  : Card(
                      child: Column(
                        children: [
                          for (final SupplierPayment p in payments)
                            ListTile(
                              leading: Icon(
                                p.kind == 'cash'
                                    ? Iconsax.money_copy
                                    : Iconsax.card_copy,
                              ),
                              title: Text(Formatters.currency(p.amount)),
                              subtitle: Text(
                                '${p.kind == 'cash' ? 'كاش' : 'تحويل'} · ${Formatters.dateTime(p.createdAt)}'
                                '${p.notes == null ? '' : '\n${p.notes}'}',
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;
  const _Row(this.label, this.amount, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold)
        : const TextStyle();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(Formatters.currency(amount), style: style),
        ],
      ),
    );
  }
}
