import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/widgets/notification_bell_icon.dart';

/// Admin landing screen. Each entry below lights up as its module lands
/// (see docs/07-implementation-roadmap.md) — Products is the first one.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text('مرحبًا ${profile?.fullName ?? ''}'),
        actions: [
          const NotificationBellIcon(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'تسجيل الخروج',
                message: 'هل تريد تسجيل الخروج من حسابك؟',
              );
              if (confirmed) await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _MenuTile(
            icon: Icons.dashboard_outlined,
            label: 'لوحة التحكم',
            onTap: () => context.push(Routes.adminDashboard),
          ),
          _MenuTile(
            icon: Icons.inventory_2_outlined,
            label: 'المنتجات',
            onTap: () => context.push(Routes.adminProducts),
          ),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            label: 'الطلبات',
            onTap: () => context.push(Routes.adminOrders),
          ),
          _MenuTile(
            icon: Icons.build_outlined,
            label: 'الصيانة',
            onTap: () => context.push(Routes.adminMaintenance),
          ),
          _MenuTile(
            icon: Icons.warehouse_outlined,
            label: 'المخزن',
            onTap: () => context.push(Routes.adminWarehouse),
          ),
          _MenuTile(
            icon: Icons.payments_outlined,
            label: 'الخزنة',
            onTap: () => context.push(Routes.adminCashbox),
          ),
          _MenuTile(
            icon: Icons.people_outline,
            label: 'العملاء',
            onTap: () => context.push(Routes.adminCustomers),
          ),
          _MenuTile(
            icon: Icons.bar_chart_outlined,
            label: 'التقارير',
            onTap: () => context.push(Routes.adminReports),
          ),
          _MenuTile(
            icon: Icons.manage_accounts_outlined,
            label: 'المستخدمون',
            onTap: () => context.push(Routes.adminUsers),
          ),
          _MenuTile(
            icon: Icons.fact_check_outlined,
            label: 'سجل العمليات',
            onTap: () => context.push(Routes.adminAuditLog),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _MenuTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
