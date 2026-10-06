import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/offline/outbox.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/purchase_models.dart';
import '../../providers/purchases_providers.dart';

/// Purchase invoices, newest first — optionally one supplier's only.
/// Invoices entered offline and not yet sent are listed on top.
class AdminPurchaseInvoicesScreen extends ConsumerWidget {
  final String? supplierId;
  final String? supplierName;
  const AdminPurchaseInvoicesScreen({
    super.key,
    this.supplierId,
    this.supplierName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(
      purchaseInvoicesProvider(supplierId: supplierId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          supplierName == null ? 'فواتير الشراء' : 'فواتير $supplierName',
        ),
        actions: [
          if (supplierId == null)
            TextButton.icon(
              onPressed: () => context.push(Routes.adminSuppliers),
              icon: const Icon(Iconsax.profile_2user_copy),
              label: const Text('الموردين'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.adminPurchaseInvoiceNew),
        icon: const Icon(Iconsax.receipt_add_copy),
        label: const Text('فاتورة شراء'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(purchaseInvoicesProvider),
        child: invoicesAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: 'تعذَّر تحميل فواتير الشراء',
            onRetry: () => ref.invalidate(purchaseInvoicesProvider),
          ),
          data: (invoices) => ListenableBuilder(
            listenable: Outbox.instance,
            builder: (context, _) {
              final pending = supplierId == null
                  ? Outbox.instance.pendingOf('purchase_invoice')
                  : const <OutboxEntry>[];
              if (invoices.isEmpty && pending.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 120),
                    EmptyView(
                      message: 'لا توجد فواتير شراء بعد',
                      icon: Iconsax.receipt_copy,
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  for (final p in pending)
                    Card(
                      child: ListTile(
                        leading: const Icon(Iconsax.clock_copy),
                        title: Text(p.label),
                        subtitle: const Text('مستنية المزامنة'),
                      ),
                    ),
                  for (final inv in invoices) _InvoiceCard(invoice: inv),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final PurchaseInvoice invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = invoice.paymentState;
    final color = switch (state) {
      PurchasePaymentState.paid => AppColors.success,
      PurchasePaymentState.partial => AppColors.warning,
      PurchasePaymentState.deferred => AppColors.danger,
    };
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () =>
            context.push(Routes.adminPurchaseInvoiceDetail(invoice.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${invoice.invoiceNumber} · ${invoice.supplierName}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Chip(
                    label: Text(purchasePaymentStateLabelAr(state)),
                    labelStyle: TextStyle(color: color, fontSize: 12),
                    side: BorderSide(color: color.withValues(alpha: 0.4)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Text(
                '${Formatters.date(invoice.invoiceDate)} · ${invoice.itemsCount} صنف',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'الإجمالي ${Formatters.currency(invoice.total)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (invoice.remainingAmount > 0)
                    Text(
                      'متبقي ${Formatters.currency(invoice.remainingAmount)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
