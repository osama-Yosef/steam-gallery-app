import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/month_invoices.dart';
import 'admin_sale_invoice_screen.dart';

/// "مبيعات الشهر" from the dashboard: every invoice since the 1st — walk-in,
/// a technician's and online — each shown in full: customer, lines,
/// discount, paid and what is still owed. Read-only; a sale opens in the
/// invoice screen for editing.
class AdminMonthSalesScreen extends ConsumerStatefulWidget {
  const AdminMonthSalesScreen({super.key});

  @override
  ConsumerState<AdminMonthSalesScreen> createState() =>
      _AdminMonthSalesScreenState();
}

class _AdminMonthSalesScreenState extends ConsumerState<AdminMonthSalesScreen> {
  /// null = every source.
  InvoiceSource? _source;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(monthInvoicesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('مبيعات شهر ${Formatters.month(DateTime.now())}'),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل فواتير الشهر',
          onRetry: () => ref.invalidate(monthInvoicesProvider),
        ),
        data: (all) {
          final q = _search.toLowerCase();
          final shown = all.where((i) {
            if (_source != null && i.source != _source) return false;
            if (q.isEmpty) return true;
            return '${i.number}'.contains(q) ||
                (i.customerName ?? '').toLowerCase().contains(q) ||
                (i.customerPhone ?? '').contains(q) ||
                (i.technicianName ?? '').toLowerCase().contains(q);
          }).toList();

          final header = <Widget>[
            _Summary(invoices: all),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text('الكل (${all.length})'),
                  selected: _source == null,
                  onSelected: (_) => setState(() => _source = null),
                ),
                for (final s in InvoiceSource.values)
                  ChoiceChip(
                    label: Text(
                      '${invoiceSourceLabelAr(s)} '
                      '(${all.where((i) => i.source == s).length})',
                    ),
                    selected: _source == s,
                    onSelected: (_) => setState(() => _source = s),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'رقم الفاتورة أو العميل أو الصنايعي',
                prefixIcon: Icon(Iconsax.search_normal_1_copy),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
            ),
            const SizedBox(height: 10),
            if (shown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: EmptyView(
                  message: 'لا توجد فواتير',
                  icon: Iconsax.receipt_copy,
                ),
              ),
          ];

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(monthInvoicesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: header.length + shown.length,
              itemBuilder: (context, i) => i < header.length
                  ? header[i]
                  : _InvoiceCard(invoice: shown[i - header.length]),
            ),
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final List<MonthInvoice> invoices;
  const _Summary({required this.invoices});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counted = invoices.where((i) => i.counted).toList();
    double sum(Iterable<MonthInvoice> l) =>
        l.fold<double>(0, (t, i) => t + i.total);
    final owed = counted.fold<double>(0, (t, i) => t + i.remaining);

    Widget row(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إجمالي الفواتير المكتملة: ${counted.length}',
              style: theme.textTheme.titleMedium,
            ),
            const Divider(height: 16),
            for (final s in InvoiceSource.values)
              row(
                invoiceSourceLabelAr(s),
                Formatters.currency(sum(counted.where((i) => i.source == s))),
              ),
            if (owed > 0)
              row(
                'آجل لسه ما اتدفعش',
                Formatters.currency(owed),
                color: AppColors.danger,
              ),
            const Divider(height: 16),
            row(
              'الإجمالي',
              Formatters.currency(sum(counted)),
              color: AppColors.primaryDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final MonthInvoice invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final i = invoice;
    final statusColor = i.counted ? AppColors.success : AppColors.danger;
    final small = theme.textTheme.bodyMedium;

    Widget money(String label, double v, {Color? color, bool bold = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              Expanded(child: Text(label, style: small)),
              Text(
                Formatters.currency(v),
                style: small?.copyWith(
                  color: color,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${i.source == InvoiceSource.online ? 'طلب' : 'فاتورة'} '
                    '#${i.number} · ${invoiceSourceLabelAr(i.source)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    i.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${Formatters.dateTime(i.createdAt)} · ${i.paymentLabel}',
              style: small,
            ),
            if (i.customerName != null || i.customerPhone != null)
              Text(
                'العميل: ${[i.customerName, i.customerPhone].whereType<String>().where((s) => s.isNotEmpty).join(' · ')}',
                style: small,
              ),
            if (i.technicianName != null)
              Text('الصنايعي: ${i.technicianName}', style: small),
            const Divider(height: 18),
            if (i.lines.isEmpty)
              Text('لا توجد أصناف', style: small)
            else
              for (final l in i.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.name, style: theme.textTheme.bodyLarge),
                            Text(
                              '${l.quantity} × ${Formatters.currency(l.unitPrice)}'
                              '${l.discount > 0 ? ' − خصم ${Formatters.currency(l.discount)}' : ''}'
                              '${l.returnedQuantity > 0 ? ' · مرتجع ${l.returnedQuantity}' : ''}',
                              style: small?.copyWith(
                                color: l.returnedQuantity > 0
                                    ? AppColors.warning
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.currency(l.lineTotal),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            const Divider(height: 18),
            money('المجموع', i.subtotal),
            if (i.discount > 0) money('الخصم', -i.discount),
            money('الإجمالي', i.total, bold: true),
            money('المدفوع', i.paid, color: AppColors.success),
            if (i.counted && i.remaining > 0)
              money('الباقي على العميل', i.remaining, color: AppColors.danger),
            if (i.notes != null && i.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('ملاحظات: ${i.notes}', style: small),
            ],
            if (i.source == InvoiceSource.walkIn) ...[
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AdminSaleInvoiceScreen(saleId: i.id),
                    ),
                  ),
                  icon: const Icon(Iconsax.edit_2_copy, size: 18),
                  label: const Text('فتح الفاتورة'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
