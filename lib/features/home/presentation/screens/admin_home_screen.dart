import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../../notifications/presentation/widgets/notification_bell_icon.dart';

/// The admin's actual landing page: just the dashboard overview (the user
/// asked for the KPIs to be what greets them, not a menu they have to dig
/// into). The section shortcuts that used to fill the rest of this page now
/// live behind the "الأقسام" button in the sidebar rail, so this page stays
/// short.
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
          children: const [DashboardOverview()],
        ),
      ),
    );
  }
}
