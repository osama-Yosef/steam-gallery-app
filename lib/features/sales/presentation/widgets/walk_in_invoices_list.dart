import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/offline/outbox.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../technician_account/data/models/sale.dart';
import '../providers/sales_providers.dart';
import '../screens/admin/admin_sale_invoice_screen.dart';

/// Every walk-in invoice ("بيع مباشر"), newest first, with today's by
/// default. Tapping one opens it for editing or deleting. Sales made offline
/// and not yet sent are listed on top.
class WalkInInvoicesList extends ConsumerStatefulWidget {
  const WalkInInvoicesList({super.key});

  @override
  ConsumerState<WalkInInvoicesList> createState() => _WalkInInvoicesListState();
}

class _WalkInInvoicesListState extends ConsumerState<WalkInInvoicesList> {
  bool _todayOnly = true;
  String _search = '';

  // The search field scrolls with the list, so its text must outlive the
  // field being built and disposed again as it leaves and re-enters view.
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isToday(DateTime d) {
    final l = d.toLocal();
    final now = DateTime.now();
    return l.year == now.year && l.month == now.month && l.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(walkInSalesProvider);
    final theme = Theme.of(context);

    return salesAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: 'تعذَّر تحميل الفواتير',
        onRetry: () => ref.invalidate(walkInSalesProvider),
      ),
      data: (sales) => ListenableBuilder(
        listenable: Outbox.instance,
        builder: (context, _) {
          final q = _search.toLowerCase();
          final shown = sales.where((s) {
            if (_todayOnly && !_isToday(s.createdAt)) return false;
            if (q.isEmpty) return true;
            return '${s.saleNumber}'.contains(q) ||
                (s.customerName ?? '').toLowerCase().contains(q) ||
                (s.customerPhone ?? '').contains(q);
          }).toList();
          final today = sales.where(
            (s) => _isToday(s.createdAt) && s.status == SaleStatus.completed,
          );
          final todayTotal = today.fold<double>(0, (sum, s) => sum + s.total);
          final pending = Outbox.instance.pendingOf('walk_in_sale');

          // Up to 1000 invoices: the summary, filters and pending sales are a
          // fixed header, the invoices themselves are built lazily.
          final header = <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Iconsax.calendar_1_copy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'فواتير اليوم: ${today.length}',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      Formatters.currency(todayTotal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('اليوم')),
                    ButtonSegment(value: false, label: Text('الكل')),
                  ],
                  selected: {_todayOnly},
                  onSelectionChanged: (s) =>
                      setState(() => _todayOnly = s.first),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'رقم الفاتورة أو العميل',
                      prefixIcon: Icon(Iconsax.search_normal_1_copy),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final p in pending)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Iconsax.clock_copy,
                    color: AppColors.warning,
                  ),
                  title: Text(p.label),
                  subtitle: Text(
                    'مستنية المزامنة · ${Formatters.dateTime(p.createdAt)}',
                  ),
                ),
              ),
            if (shown.isEmpty && pending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: EmptyView(
                  message: _todayOnly
                      ? 'لا توجد فواتير اليوم'
                      : 'لا توجد فواتير',
                  icon: Iconsax.receipt_copy,
                ),
              ),
          ];

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(walkInSalesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: header.length + shown.length,
              itemBuilder: (context, i) => i < header.length
                  ? header[i]
                  : _InvoiceTile(sale: shown[i - header.length]),
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Sale sale;
  const _InvoiceTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingEdit =
        Outbox.instance.pendingOf('sale_edit', refId: sale.id).isNotEmpty ||
        Outbox.instance.pendingOf('sale_delete', refId: sale.id).isNotEmpty;
    final statusColor = switch (sale.status) {
      SaleStatus.completed => AppColors.success,
      SaleStatus.returned => AppColors.warning,
      SaleStatus.cancelled => AppColors.danger,
    };
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AdminSaleInvoiceScreen(saleId: sale.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فاتورة #${sale.saleNumber}'
                      '${sale.customerName == null ? '' : ' · ${sale.customerName}'}',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '${Formatters.dateTime(sale.createdAt)} · ${paymentMethodLabelAr(sale.paymentMethod)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (pendingEdit)
                      const Text(
                        'في تعديل مستني المزامنة',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(sale.total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    saleStatusLabelAr(sale.status),
                    style: TextStyle(color: statusColor, fontSize: 12),
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
