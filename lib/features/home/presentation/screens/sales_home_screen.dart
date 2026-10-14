import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/navigation/sales_sections_screen.dart';
import '../../../../core/navigation/section_grid.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../../notifications/presentation/widgets/notification_bell_icon.dart';

/// The sales role's landing tab: its dashboard, with its sections right
/// under it on the same page. Selling (بيع مباشر) is the second tab.
class SalesHomeScreen extends ConsumerWidget {
  const SalesHomeScreen({super.key});

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
            onPressed: () => ref.invalidate(dashboardSummaryProvider),
          ),
          const NotificationBellIcon(),
          const SalesLogoutButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SalesDashboardOverview(),
            const SizedBox(height: 24),
            Text('الأقسام', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const SectionGrid(sections: salesSections, embedded: true),
          ],
        ),
      ),
    );
  }
}
