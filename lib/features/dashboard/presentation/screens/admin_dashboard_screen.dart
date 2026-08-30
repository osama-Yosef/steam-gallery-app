import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/revenue_trend_chart.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final trendAsync = ref.watch(dashboardRevenueTrendProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(dashboardRevenueTrendProvider);
            },
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل بيانات اللوحة',
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
        ),
        data: (s) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(dashboardRevenueTrendProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _KpiCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'رصيد الخزنة',
                value: MoneyText(s.cashboxBalance, style: Theme.of(context).textTheme.headlineSmall),
                onTap: () => context.push(Routes.adminCashbox),
                highlight: true,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _KpiCard(icon: Icons.today_outlined, label: 'مبيعات اليوم', value: MoneyText(s.todayRevenue)),
                  _KpiCard(
                    icon: Icons.trending_up,
                    label: 'صافي ربح اليوم',
                    value: MoneyText(s.todayNetProfit, colorBySign: true),
                  ),
                  _KpiCard(icon: Icons.calendar_month_outlined, label: 'مبيعات الشهر', value: MoneyText(s.monthRevenue)),
                  _KpiCard(
                    icon: Icons.savings_outlined,
                    label: 'صافي ربح الشهر',
                    value: MoneyText(s.monthNetProfit, colorBySign: true),
                  ),
                  _KpiCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'طلبات جديدة',
                    value: Text('${s.pendingOrdersCount}', style: Theme.of(context).textTheme.headlineSmall),
                    onTap: () => context.push(Routes.adminOrders),
                  ),
                  _KpiCard(
                    icon: Icons.build_outlined,
                    label: 'صيانات نشطة',
                    value: Text('${s.activeMaintenanceCount}', style: Theme.of(context).textTheme.headlineSmall),
                    onTap: () => context.push(Routes.adminMaintenance),
                  ),
                  _KpiCard(
                    icon: Icons.warning_amber_outlined,
                    label: 'منتجات منخفضة',
                    value: Text('${s.lowStockCount}', style: Theme.of(context).textTheme.headlineSmall),
                    onTap: () => context.push(Routes.adminWarehouse),
                  ),
                  _KpiCard(
                    icon: Icons.engineering_outlined,
                    label: 'الصنايعية النشطون',
                    value: Text('${s.activeTechniciansCount}', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  _KpiCard(
                    icon: Icons.people_outline,
                    label: 'ديون العملاء',
                    value: MoneyText(s.customerDebtsTotal),
                    onTap: () => context.push(Routes.adminCustomers),
                  ),
                  _KpiCard(
                    icon: Icons.handshake_outlined,
                    label: 'مستحقات الصنايعية',
                    value: MoneyText(s.technicianDuesTotal),
                    onTap: () => context.push(Routes.adminTechnicianBags),
                  ),
                  _KpiCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'قيمة المخزون',
                    value: MoneyText(s.warehouseStockValue),
                    onTap: () => context.push(Routes.adminWarehouse),
                  ),
                  _KpiCard(
                    icon: Icons.remove_circle_outline,
                    label: 'مصروفات الشهر',
                    value: MoneyText(s.monthExpenses),
                    onTap: () => context.push(Routes.adminExpenses),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('مبيعات آخر 7 أيام', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      trendAsync.when(
                        loading: () => const SizedBox(height: 140, child: LoadingView()),
                        error: (e, _) => const SizedBox(height: 140, child: Center(child: Text('تعذَّر تحميل الرسم'))),
                        data: (points) => RevenueTrendChart(points: points),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => context.push(Routes.adminReports),
                icon: const Icon(Icons.bar_chart_outlined),
                label: const Text('التقارير التفصيلية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;
  final VoidCallback? onTap;
  final bool highlight;

  const _KpiCard({required this.icon, required this.label, required this.value, this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: highlight ? scheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(label, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              value,
            ],
          ),
        ),
      ),
    );
  }
}
