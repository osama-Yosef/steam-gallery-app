import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../customer_account/presentation/providers/customer_account_providers.dart';
import '../../../technician_account/presentation/providers/technician_account_providers.dart';
import '../providers/reports_providers.dart';
import 'admin_reports_home_screen.dart' show reportTypes;

/// One screen, body switches on `reportType` — the 6 reports share the same
/// date-range header and "copy" export action, so a single adaptable screen
/// avoids six near-identical files. See docs/07-implementation-roadmap.md
/// Module 11 (Export is copy-to-clipboard for v1, not PDF/Excel — a
/// deliberate scope cut to avoid pulling in an untested package this late;
/// swapping in `printing`/`excel` later is a presentation-layer-only change).
class AdminReportDetailScreen extends ConsumerWidget {
  final String reportType;
  const AdminReportDetailScreen({super.key, required this.reportType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = reportTypes.firstWhere((t) => t.$1 == reportType).$2;
    final range = ref.watch(reportDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        actions: [
          IconButton(
            tooltip: 'نسخ التقرير',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () => _copyReport(context, ref, range),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${Formatters.date(range.from)} — ${Formatters.date(range.to.subtract(const Duration(days: 1)))}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(child: _buildBody(context, ref, range)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ReportRange range) {
    switch (reportType) {
      case 'sales':
        final async = ref.watch(salesReportProvider(range.from, range.to));
        return async.when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التقرير'),
          data: (r) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _row(context, 'إجمالي المبيعات', r.totalSales),
              _row(context, 'تكلفة البضاعة المباعة', r.cogs),
              _row(context, 'مجمل الربح', r.grossProfit, bold: true),
              _row(context, 'الخصومات', r.discounts),
              _row(context, 'المرتجعات', r.returns),
              const Divider(height: 32),
              _row(
                context,
                'صافي المبيعات',
                r.netSales,
                bold: true,
                highlight: true,
              ),
            ],
          ),
        );

      case 'profit':
        final async = ref.watch(profitReportProvider(range.from, range.to));
        return async.when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التقرير'),
          data: (r) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _row(context, 'الإيرادات (Revenue)', r.revenue),
              _row(context, 'تكلفة البضاعة (COGS)', -r.cogs),
              _row(context, 'مجمل الربح', r.grossProfit, bold: true),
              _row(context, 'المصروفات', -r.expenses),
              const Divider(height: 32),
              _row(
                context,
                'صافي الربح (Net Profit)',
                r.netProfit,
                bold: true,
                highlight: true,
              ),
            ],
          ),
        );

      case 'expenses':
        final async = ref.watch(expensesReportProvider(range.from, range.to));
        return async.when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التقرير'),
          data: (r) {
            if (r.all.isEmpty) {
              return const EmptyView(message: 'لا توجد مصروفات في هذه الفترة');
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _row(
                  context,
                  'إجمالي المصروفات',
                  r.total,
                  bold: true,
                  highlight: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'حسب التصنيف',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...r.byCategory.map(
                  (c) => _row(context, c.categoryName, c.total),
                ),
                const SizedBox(height: 16),
                Text(
                  'أكبر المصروفات',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...r.topExpenses.map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.categoryName),
                    subtitle: Text(
                      Formatters.date(e.date) +
                          (e.notes != null ? ' · ${e.notes}' : ''),
                    ),
                    trailing: MoneyText(e.amount),
                  ),
                ),
              ],
            );
          },
        );

      case 'inventory':
        final async = ref.watch(inventoryReportProvider(range.from, range.to));
        return async.when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التقرير'),
          data: (r) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _row(
                context,
                'قيمة المخزون الحالية',
                r.warehouseStockValue,
                bold: true,
              ),
              _row(
                context,
                'عدد المنتجات منخفضة المخزون',
                r.lowStockCount.toDouble(),
                isCount: true,
              ),
              const SizedBox(height: 16),
              Text(
                'حركة المخزن خلال الفترة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (r.movementsByType.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('لا توجد حركات'),
                ),
              ...r.movementsByType.map(
                (m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_movementTypeLabel(m.movementType)),
                  subtitle: Text('${m.count} حركة'),
                  trailing: MoneyText(m.totalCost),
                ),
              ),
            ],
          ),
        );

      case 'technicians':
        final async = ref.watch(allTechnicianAccountSummariesProvider);
        return async.when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التقرير'),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyView(message: 'لا يوجد صنايعية');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, i) {
                final t = list[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.technicianName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    _row(context, 'قيمة البضاعة معه', t.bagValue),
                    _row(context, 'إجمالي المبيعات', t.totalSales),
                    _row(context, 'التحصيل', t.totalCollected),
                    _row(
                      context,
                      'المطلوب توريده',
                      t.amountDue,
                      highlight: t.amountDue > 0,
                    ),
                  ],
                );
              },
            );
          },
        );

      case 'customers':
        final async = ref.watch(customerAccountsProvider());
        return async.when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التقرير'),
          data: (list) {
            if (list.isEmpty) return const EmptyView(message: 'لا يوجد عملاء');
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, i) {
                final c = list[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      c.customerName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    _row(context, 'إجمالي المشتريات', c.totalPurchases),
                    _row(context, 'المدفوع', c.totalPaid),
                    _row(
                      context,
                      'المتبقي',
                      c.remainingBalance,
                      highlight: c.remainingBalance > 0,
                    ),
                  ],
                );
              },
            );
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _row(
    BuildContext context,
    String label,
    double value, {
    bool bold = false,
    bool highlight = false,
    bool isCount = false,
  }) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: highlight ? Theme.of(context).colorScheme.primary : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          isCount
              ? Text(value.toInt().toString(), style: style)
              : MoneyText(value, style: style),
        ],
      ),
    );
  }

  String _movementTypeLabel(String type) => switch (type) {
    'purchase' => 'شراء',
    'sale' => 'بيع',
    'issue_to_technician' => 'صرف لصنايعي',
    'technician_sale' => 'بيع صنايعي',
    'return_from_customer' => 'مرتجع عميل',
    'return_to_supplier' => 'مرتجع مورد',
    'damage' => 'تالف',
    'inventory_adjustment' => 'تسوية جرد',
    'transfer' => 'نقل',
    _ => type,
  };

  Future<void> _copyReport(
    BuildContext context,
    WidgetRef ref,
    ReportRange range,
  ) async {
    final buffer = StringBuffer()
      ..writeln(reportTypes.firstWhere((t) => t.$1 == reportType).$2)
      ..writeln(
        '${Formatters.date(range.from)} — ${Formatters.date(range.to.subtract(const Duration(days: 1)))}',
      )
      ..writeln();

    switch (reportType) {
      case 'sales':
        final r = await ref.read(
          salesReportProvider(range.from, range.to).future,
        );
        buffer
          ..writeln('إجمالي المبيعات: ${Formatters.currency(r.totalSales)}')
          ..writeln('تكلفة البضاعة: ${Formatters.currency(r.cogs)}')
          ..writeln('مجمل الربح: ${Formatters.currency(r.grossProfit)}')
          ..writeln('الخصومات: ${Formatters.currency(r.discounts)}')
          ..writeln('المرتجعات: ${Formatters.currency(r.returns)}')
          ..writeln('صافي المبيعات: ${Formatters.currency(r.netSales)}');
      case 'profit':
        final r = await ref.read(
          profitReportProvider(range.from, range.to).future,
        );
        buffer
          ..writeln('الإيرادات: ${Formatters.currency(r.revenue)}')
          ..writeln('تكلفة البضاعة: ${Formatters.currency(r.cogs)}')
          ..writeln('مجمل الربح: ${Formatters.currency(r.grossProfit)}')
          ..writeln('المصروفات: ${Formatters.currency(r.expenses)}')
          ..writeln('صافي الربح: ${Formatters.currency(r.netProfit)}');
      case 'expenses':
        final r = await ref.read(
          expensesReportProvider(range.from, range.to).future,
        );
        buffer.writeln('إجمالي المصروفات: ${Formatters.currency(r.total)}');
        for (final c in r.byCategory) {
          buffer.writeln('${c.categoryName}: ${Formatters.currency(c.total)}');
        }
      case 'inventory':
        final r = await ref.read(
          inventoryReportProvider(range.from, range.to).future,
        );
        buffer
          ..writeln(
            'قيمة المخزون: ${Formatters.currency(r.warehouseStockValue)}',
          )
          ..writeln('منتجات منخفضة: ${r.lowStockCount}');
      case 'technicians':
        final list = await ref.read(
          allTechnicianAccountSummariesProvider.future,
        );
        for (final t in list) {
          buffer.writeln(
            '${t.technicianName} — مطلوب توريد: ${Formatters.currency(t.amountDue)}',
          );
        }
      case 'customers':
        final list = await ref.read(customerAccountsProvider().future);
        for (final c in list) {
          buffer.writeln(
            '${c.customerName} — متبقي: ${Formatters.currency(c.remainingBalance)}',
          );
        }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم نسخ التقرير')));
    }
  }
}
