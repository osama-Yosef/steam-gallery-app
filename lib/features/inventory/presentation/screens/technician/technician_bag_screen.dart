import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../technician_account/presentation/providers/technician_account_providers.dart';
import '../../providers/inventory_providers.dart';
import '../../widgets/bag_stock_body.dart';

class TechnicianBagScreen extends ConsumerWidget {
  const TechnicianBagScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('شنطتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'سجل مبيعاتي',
            onPressed: () => context.push(Routes.technicianSales),
          ),
        ],
        bottom: profile == null ? null : BagValueAppBarBottom(technicianId: profile.id),
      ),
      floatingActionButton: profile == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await context.push(Routes.technicianBagSell);
                ref.invalidate(technicianBagStockProvider(profile.id));
                ref.invalidate(technicianAccountSummaryProvider(profile.id));
              },
              icon: const Icon(Icons.point_of_sale_outlined),
              label: const Text('بيع'),
            ),
      body: profile == null ? const SizedBox.shrink() : BagStockBody(technicianId: profile.id),
    );
  }
}
