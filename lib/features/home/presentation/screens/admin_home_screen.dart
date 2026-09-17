import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../../notifications/presentation/widgets/notification_bell_icon.dart';

/// The admin's actual landing page: the dashboard overview first (the user
/// asked for the KPIs to be what greets them, not a menu they have to dig
/// into), then the section shortcuts below it for whatever isn't already a
/// sidebar rail item (marketing, users, audit log, InstaPay review,
/// wallets, service areas, walk-in sale).
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text('مرحبًا ${profile?.fullName ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Iconsax.refresh_copy),
            onPressed: () {
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(dashboardRevenueTrendProvider);
            },
          ),
          const NotificationBellIcon(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(dashboardRevenueTrendProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const DashboardOverview(),
            const SizedBox(height: 28),
            Text(
              'الأقسام',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, c) {
                // Fixed at 2 columns this grid produced enormous ~500px
                // tiles on a desktop window; width-driven keeps them a sane
                // size everywhere.
                final columns = (c.maxWidth / 190).floor().clamp(2, 6);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.9,
                  children: [
                    _MenuTile(
                      icon: Iconsax.box_copy,
                      label: 'المنتجات',
                      colors: const [Color(0xFF6D8CFF), Color(0xFF3B5BFF)],
                      onTap: () => context.push(Routes.adminProducts),
                    ),
                    _MenuTile(
                      icon: Iconsax.receipt_text_copy,
                      label: 'الطلبات',
                      colors: const [Color(0xFFB07CFF), Color(0xFF7C4DFF)],
                      onTap: () => context.push(Routes.adminOrders),
                    ),
                    _MenuTile(
                      icon: Iconsax.setting_2_copy,
                      label: 'الصيانة',
                      colors: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      onTap: () => context.push(Routes.adminMaintenance),
                    ),
                    _MenuTile(
                      icon: Iconsax.buildings_2_copy,
                      label: 'المخزن',
                      colors: const [Color(0xFF34D399), Color(0xFF10B981)],
                      onTap: () => context.push(Routes.adminWarehouse),
                    ),
                    _MenuTile(
                      icon: Iconsax.wallet_money_copy,
                      label: 'الخزنة',
                      colors: const [Color(0xFF7CE0FF), Color(0xFF38BDF8)],
                      onTap: () => context.push(Routes.adminCashbox),
                    ),
                    _MenuTile(
                      icon: Iconsax.card_pos_copy,
                      label: 'بيع مباشر',
                      colors: const [Color(0xFFFF8A65), Color(0xFFE64A19)],
                      onTap: () => context.push(Routes.adminWalkInSale),
                    ),
                    _MenuTile(
                      icon: Iconsax.chart_2_copy,
                      label: 'التقارير',
                      colors: const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                      onTap: () => context.push(Routes.adminReports),
                    ),
                    _MenuTile(
                      icon: Iconsax.people_copy,
                      label: 'العملاء',
                      colors: const [Color(0xFFF48FB1), Color(0xFFEC407A)],
                      onTap: () => context.push(Routes.adminCustomers),
                    ),
                    _MenuTile(
                      icon: Iconsax.discount_shape_copy,
                      label: 'العروض والبانرات',
                      colors: const [Color(0xFFE4B83F), Color(0xFFB7862A)],
                      onTap: () => context.push(Routes.adminMarketing),
                    ),
                    _MenuTile(
                      icon: Iconsax.map_copy,
                      label: 'مناطق الخدمة',
                      colors: const [Color(0xFF67A9B2), Color(0xFF2F7784)],
                      onTap: () => context.push(Routes.adminServiceAreas),
                    ),
                    _MenuTile(
                      icon: Iconsax.profile_2user_copy,
                      label: 'المستخدمون',
                      colors: const [Color(0xFF80CBC4), Color(0xFF00897B)],
                      onTap: () => context.push(Routes.adminUsers),
                    ),
                    _MenuTile(
                      icon: Iconsax.document_text_copy,
                      label: 'سجل العمليات',
                      colors: const [Color(0xFFBCAAA4), Color(0xFF6D4C41)],
                      onTap: () => context.push(Routes.adminAuditLog),
                    ),
                    _MenuTile(
                      icon: Iconsax.bank_copy,
                      label: 'مراجعة InstaPay',
                      colors: const [Color(0xFF9575CD), Color(0xFF5E35B1)],
                      onTap: () => context.push(Routes.adminInstapayReview),
                    ),
                    _MenuTile(
                      icon: Iconsax.wallet_2_copy,
                      label: 'محافظ العملاء',
                      colors: const [Color(0xFF64B5F6), Color(0xFF1976D2)],
                      onTap: () => context.push(Routes.adminWallets),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback? onTap;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.last.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
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
