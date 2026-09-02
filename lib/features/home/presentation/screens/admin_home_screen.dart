import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Admin dashboard — the "الرئيسية" branch of AdminShell. The sidebar now
/// owns primary navigation, so this is a welcome/quick-links surface rather
/// than the app's only way into each section.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text('مرحبًا ${profile?.fullName ?? ''}')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.9,
        children: [
          _MenuTile(
            icon: Icons.inventory_2_rounded,
            label: 'المنتجات',
            colors: const [Color(0xFF6D8CFF), Color(0xFF3B5BFF)],
            onTap: () => context.push(Routes.adminProducts),
          ),
          _MenuTile(
            icon: Icons.receipt_long_rounded,
            label: 'الطلبات',
            colors: const [Color(0xFFB07CFF), Color(0xFF7C4DFF)],
            onTap: () => context.push(Routes.adminOrders),
          ),
          _MenuTile(
            icon: Icons.build_rounded,
            label: 'الصيانة',
            colors: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
            onTap: () => context.push(Routes.adminMaintenance),
          ),
          _MenuTile(
            icon: Icons.warehouse_rounded,
            label: 'المخزن',
            colors: const [Color(0xFF34D399), Color(0xFF10B981)],
            onTap: () => context.push(Routes.adminWarehouse),
          ),
          _MenuTile(
            icon: Icons.account_balance_wallet_rounded,
            label: 'الخزنة',
            colors: const [Color(0xFF7CE0FF), Color(0xFF38BDF8)],
            onTap: () => context.push(Routes.adminCashbox),
          ),
          _MenuTile(
            icon: Icons.point_of_sale_rounded,
            label: 'بيع مباشر',
            colors: const [Color(0xFFFF8A65), Color(0xFFE64A19)],
            onTap: () => context.push(Routes.adminWalkInSale),
          ),
          _MenuTile(
            icon: Icons.insert_chart_rounded,
            label: 'التقارير',
            colors: const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
            onTap: () => context.push(Routes.adminReports),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback? onTap;
  const _MenuTile({required this.icon, required this.label, required this.colors, this.onTap});

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
                    gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.4), blurRadius: 16)],
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
