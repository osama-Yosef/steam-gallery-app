import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../cashbox/presentation/providers/cashbox_providers.dart';
import '../../../data/models/report_models.dart';
import '../../providers/reports_providers.dart';

/// Cross-cutting reports hub reachable from the admin dashboard — every tab
/// reads an existing DB view (0009_views.sql) or aggregates an existing list
/// client-side; no new business logic, just visibility into data that
/// already exists.
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'المبيعات'),
              Tab(text: 'المخزون'),
              Tab(text: 'الصنايعية'),
              Tab(text: 'العملاء'),
              Tab(text: 'المصروفات'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SalesReportTab(),
            _InventoryReportTab(),
            _TechnicianReportTab(),
            _CustomerReportTab(),
            _ExpensesReportTab(),
          ],
        ),
      ),
    );
  }
}

class _SalesReportTab extends ConsumerWidget {
  const _SalesReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailySalesProvider);
    final monthlyAsync = ref.watch(monthlySalesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('آخر 12 شهرًا', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        monthlyAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التقرير'),
          data: (rows) => rows.isEmpty
              ? const EmptyView(message: 'لا توجد مبيعات بعد', icon: Icons.bar_chart_outlined)
              : Column(children: [for (final r in rows) _SalesRow(r, monthLabel: true)]),
        ),
        const Divider(height: 32),
        Text('آخر 30 يومًا', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        dailyAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التقرير'),
          data: (rows) => rows.isEmpty
              ? const EmptyView(message: 'لا توجد مبيعات بعد', icon: Icons.bar_chart_outlined)
              : Column(children: [for (final r in rows) _SalesRow(r, monthLabel: false)]),
        ),
      ],
    );
  }
}

class _SalesRow extends StatelessWidget {
  final SalesPeriodSummary row;
  final bool monthLabel;
  const _SalesRow(this.row, {required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(monthLabel ? Formatters.month(row.period) : Formatters.date(row.period)),
      subtitle: Text('التكلفة: ${Formatters.currency(row.cogs)}'),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(Formatters.currency(row.revenue), style: Theme.of(context).textTheme.titleSmall),
          Text('ربح: ${Formatters.currency(row.profit)}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _InventoryReportTab extends ConsumerWidget {
  const _InventoryReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valueAsync = ref.watch(warehouseStockValueProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: const Text('إجمالي قيمة المخزن (تكلفة)'),
            trailing: valueAsync.when(
              loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => const Text('—'),
              data: (v) => Text(Formatters.currency(v), style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
        ),
        const Divider(height: 32),
        Text('أصناف تحت الحد الأدنى', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        lowStockAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التقرير'),
          data: (rows) => rows.isEmpty
              ? const EmptyView(message: 'كل الأصناف فوق الحد الأدنى', icon: Icons.check_circle_outline)
              : Column(
                  children: [
                    for (final p in rows)
                      ListTile(
                        title: Text(p.name),
                        subtitle: Text('SKU: ${p.sku} · الحد الأدنى: ${p.minStock}'),
                        trailing: Text(
                          'المتاح: ${p.currentQuantity}',
                          style: TextStyle(
                            color: p.currentQuantity == 0
                                ? Theme.of(context).colorScheme.error
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TechnicianReportTab extends ConsumerWidget {
  const _TechnicianReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(technicianAccountsReportProvider);
    return rowsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التقرير'),
      data: (rows) => rows.isEmpty
          ? const EmptyView(message: 'لا يوجد صنايعية بعد', icon: Icons.engineering_outlined)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final r in rows)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.technicianName, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          _kv('قيمة الشنطة', r.bagValue),
                          _kv('إجمالي المبيعات', r.totalSales),
                          _kv('إجمالي التحصيل', r.totalCollected),
                          _kv('المطلوب توريده', r.amountDue, emphasize: true),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _kv(String label, double value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            Formatters.currency(value),
            style: emphasize ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }
}

class _CustomerReportTab extends ConsumerWidget {
  const _CustomerReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(customerAccountsReportProvider);
    return rowsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التقرير'),
      data: (rows) => rows.isEmpty
          ? const EmptyView(message: 'لا توجد حسابات عملاء بعد', icon: Icons.people_outline)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = rows[i];
                return ListTile(
                  title: Text(r.customerName),
                  subtitle: Text('إجمالي المشتريات: ${Formatters.currency(r.totalPurchases)}'),
                  trailing: Text(
                    Formatters.currency(r.remainingBalance),
                    style: TextStyle(
                      color: r.remainingBalance > 0 ? Theme.of(context).colorScheme.error : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ExpensesReportTab extends ConsumerWidget {
  const _ExpensesReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    return expensesAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التقرير'),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const EmptyView(message: 'لا توجد مصروفات بعد', icon: Icons.receipt_long_outlined);
        }
        final totals = <String, double>{};
        for (final e in expenses) {
          totals[e.categoryName] = (totals[e.categoryName] ?? 0) + e.amount;
        }
        final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final grandTotal = totals.values.fold<double>(0, (s, v) => s + v);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: const Text('إجمالي المصروفات'),
                trailing: Text(Formatters.currency(grandTotal), style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            const Divider(height: 32),
            Text('حسب التصنيف', style: Theme.of(context).textTheme.titleMedium),
            for (final entry in sorted)
              ListTile(
                title: Text(entry.key),
                trailing: Text(Formatters.currency(entry.value)),
              ),
          ],
        );
      },
    );
  }
}
