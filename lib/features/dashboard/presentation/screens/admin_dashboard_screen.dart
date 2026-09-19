import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/revenue_trend_chart.dart';

/// The KPI grid + revenue chart, with no Scaffold of its own — embedded
/// directly at the top of [AdminHomeScreen] (the user asked for the
/// dashboard to be the admin's actual landing page, not a separate tile),
/// and also still reachable as its own route for a direct/bookmarked link.
class DashboardOverview extends ConsumerWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final trendAsync = ref.watch(dashboardRevenueTrendProvider);

    return summaryAsync.when(
      loading: () => const SizedBox(
        height: 300,
        child: LoadingView(),
      ),
      error: (e, _) => SizedBox(
        height: 220,
        child: ErrorView(
          message: 'تعذَّر تحميل بيانات اللوحة',
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
        ),
      ),
      data: (s) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KpiCard(
            icon: Iconsax.wallet_money_copy,
            colors: const [AppColors.brandTeal, AppColors.primaryDark],
            label: 'رصيد الخزنة',
            value: MoneyText(
              s.cashboxBalance,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            onTap: () => context.push(Routes.adminCashbox),
            highlight: true,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              // Width-driven rather than a fixed column count, so the grid
              // stays 2-up on a phone (where the admin rail already eats a
              // big slice of the width) and spreads out on a desktop window
              // instead of stretching two cards across a whole monitor.
              // Computed explicitly rather than via GridView.extent, whose
              // ceil() can drop a narrow phone to a single column.
              final columns = (c.maxWidth / 210).floor().clamp(2, 6);
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // A fixed row height (rather than childAspectRatio, which
                // ties height to width) so a card's 2-line label + value
                // always has room to fit — otherwise, whenever the sidebar
                // rail opens and narrows this grid, the shorter cells that
                // childAspectRatio produced would overflow their card and
                // spill text into the row above.
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  mainAxisExtent: 168,
                ),
                children: [
                  _KpiCard(
                    icon: Iconsax.calendar_1_copy,
                    colors: const [Color(0xFF6D8CFF), Color(0xFF3B5BFF)],
                    label: 'مبيعات اليوم',
                    value: MoneyText(s.todayRevenue),
                  ),
                  _KpiCard(
                    icon: Iconsax.trend_up_copy,
                    colors: const [Color(0xFF34D399), Color(0xFF059669)],
                    label: 'صافي ربح اليوم',
                    value: MoneyText(s.todayNetProfit, colorBySign: true),
                  ),
                  _KpiCard(
                    icon: Iconsax.calendar_copy,
                    colors: const [Color(0xFF6D8CFF), Color(0xFF3B5BFF)],
                    label: 'مبيعات الشهر',
                    value: MoneyText(s.monthRevenue),
                  ),
                  _KpiCard(
                    icon: Iconsax.chart_success_copy,
                    colors: const [Color(0xFF34D399), Color(0xFF059669)],
                    label: 'صافي ربح الشهر',
                    value: MoneyText(s.monthNetProfit, colorBySign: true),
                  ),
                  _KpiCard(
                    icon: Iconsax.receipt_text_copy,
                    colors: const [Color(0xFFB07CFF), Color(0xFF7C4DFF)],
                    label: 'طلبات جديدة',
                    value: Text(
                      '${s.pendingOrdersCount}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    onTap: () => context.push(Routes.adminOrders),
                  ),
                  _KpiCard(
                    icon: Iconsax.setting_2_copy,
                    colors: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    label: 'صيانات نشطة',
                    value: Text(
                      '${s.activeMaintenanceCount}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    onTap: () => context.push(Routes.adminMaintenance),
                  ),
                  _KpiCard(
                    icon: Iconsax.warning_2_copy,
                    colors: const [Color(0xFFFF8A65), Color(0xFFE64A19)],
                    label: 'منتجات منخفضة',
                    value: Text(
                      '${s.lowStockCount}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    onTap: () => context.push(Routes.adminWarehouse),
                  ),
                  _KpiCard(
                    icon: Iconsax.profile_2user_copy,
                    colors: const [Color(0xFF80CBC4), Color(0xFF00897B)],
                    label: 'الصنايعية النشطون',
                    value: Text(
                      '${s.activeTechniciansCount}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  _KpiCard(
                    icon: Iconsax.people_copy,
                    colors: const [Color(0xFFF48FB1), Color(0xFFEC407A)],
                    label: 'ديون العملاء',
                    value: MoneyText(s.customerDebtsTotal),
                    onTap: () => context.push(Routes.adminCustomers),
                  ),
                  _KpiCard(
                    icon: Iconsax.card_receive_copy,
                    colors: const [Color(0xFF9575CD), Color(0xFF5E35B1)],
                    label: 'مستحقات الصنايعية',
                    value: MoneyText(s.technicianDuesTotal),
                    onTap: () => context.push(Routes.adminTechnicianBags),
                  ),
                  _KpiCard(
                    icon: Iconsax.buildings_2_copy,
                    colors: const [Color(0xFF34D399), Color(0xFF10B981)],
                    label: 'قيمة المخزون',
                    value: MoneyText(s.warehouseStockValue),
                    onTap: () => context.push(Routes.adminWarehouse),
                  ),
                  _KpiCard(
                    icon: Iconsax.card_remove_copy,
                    colors: const [Color(0xFFFF7A7A), Color(0xFFDC2626)],
                    label: 'مصروفات الشهر',
                    value: MoneyText(s.monthExpenses),
                    onTap: () => context.push(Routes.adminExpenses),
                  ),
                  _KpiCard(
                    icon: Iconsax.wallet_2_copy,
                    colors: const [Color(0xFF64B5F6), Color(0xFF1976D2)],
                    label: 'أرصدة محافظ العملاء',
                    value: MoneyText(s.walletLiabilityTotal),
                    onTap: () => context.push(Routes.adminWallets),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'مبيعات آخر 7 أيام',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  trendAsync.when(
                    loading: () =>
                        const SizedBox(height: 140, child: LoadingView()),
                    error: (e, _) => const SizedBox(
                      height: 140,
                      child: Center(child: Text('تعذَّر تحميل الرسم')),
                    ),
                    data: (points) => RevenueTrendChart(points: points),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => context.push(Routes.adminReports),
            icon: const Icon(Iconsax.chart_2_copy),
            label: const Text('التقارير التفصيلية'),
          ),
        ],
      ),
    );
  }
}

/// Standalone wrapper kept for a direct/bookmarked `/admin/dashboard` link;
/// [AdminHomeScreen] embeds [DashboardOverview] itself and is the normal way
/// admins reach this.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Iconsax.refresh_copy),
            onPressed: () {
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(dashboardRevenueTrendProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(dashboardRevenueTrendProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [DashboardOverview()],
        ),
      ),
    );
  }
}

/// A KPI tile with a colour-coded icon badge — same visual language as the
/// section-menu tiles below it on [AdminHomeScreen], so the whole screen
/// reads as one designed surface instead of two different UI styles glued
/// together.
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final List<Color> colors;
  final String label;
  final Widget value;
  final VoidCallback? onTap;
  final bool highlight;

  const _KpiCard({
    required this.icon,
    required this.colors,
    required this.label,
    required this.value,
    this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight) {
      return _HighlightCard(icon: icon, colors: colors, label: label, value: value, onTap: onTap);
    }
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, c) {
              final badgeSize = c.maxWidth < 150 ? 34.0 : 38.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: badgeSize,
                    height: badgeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: badgeSize * 0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: value,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final List<Color> colors;
  final String label;
  final Widget value;
  final VoidCallback? onTap;

  const _HighlightCard({
    required this.icon,
    required this.colors,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: value,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
