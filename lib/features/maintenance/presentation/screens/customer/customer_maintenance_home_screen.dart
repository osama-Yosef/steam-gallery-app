import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/maintenance_request.dart';
import '../../providers/maintenance_providers.dart';
import '../../widgets/maintenance_status_chips.dart';

class CustomerMaintenanceHomeScreen extends ConsumerWidget {
  const CustomerMaintenanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('الصيانة')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.customerMaintenanceNew),
        icon: const Icon(Iconsax.add_copy),
        label: const Text('طلب صيانة جديد'),
      ),
      body: profile == null
          ? const LoadingView()
          : ref
                .watch(myMaintenanceRequestsProvider(profile.id))
                .when(
                  loading: () => const LoadingView(),
                  error: (e, _) =>
                      const ErrorView(message: 'تعذَّر تحميل طلبات الصيانة'),
                  data: (requests) {
                    if (requests.isEmpty) {
                      return const EmptyView(
                        message: 'لا توجد طلبات صيانة بعد',
                        icon: Iconsax.setting_2_copy,
                      );
                    }
                    final active = requests
                        .where(
                          (r) => kActiveMaintenanceStatuses.contains(r.status),
                        )
                        .toList();
                    final history = requests
                        .where(
                          (r) => !kActiveMaintenanceStatuses.contains(r.status),
                        )
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 88),
                      children: [
                        if (active.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'الطلب النشط',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          for (final r in active) _RequestTile(request: r),
                        ],
                        if (history.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'السجل',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          for (final r in history) _RequestTile(request: r),
                        ],
                      ],
                    );
                  },
                ),
    );
  }
}

/// A full-width, colour-coded card — the ticket number reads clearly at a
/// glance, and the status colour (amber/teal/green/red) says what stage
/// it's at before you even read the label.
class _RequestTile extends StatelessWidget {
  final MaintenanceRequest request;
  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final color = maintenanceStatusColor(request.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: color.withValues(alpha: 0.08),
          child: InkWell(
            onTap: () =>
                context.push(Routes.customerMaintenanceDetail(request.id)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                    child: const Icon(
                      Iconsax.setting_2_copy,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب #${request.ticketNumber}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.date(request.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      maintenanceStatusLabelAr(request.status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
