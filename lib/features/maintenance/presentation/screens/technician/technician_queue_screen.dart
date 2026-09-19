import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../notifications/presentation/widgets/notification_bell_icon.dart';
import '../../../data/models/maintenance_request.dart';
import '../../providers/maintenance_providers.dart';
import '../../widgets/maintenance_status_chips.dart';

/// Technician's landing screen — the queue itself, per the original spec
/// ("الصفحة الرئيسية تعرض الصيانات مرتبة حسب الدور"). RLS already scopes
/// `visibleMaintenanceRequestsProvider` to waiting requests + this
/// technician's own assignments, so filtering to active statuses here and
/// sorting by created_at reproduces the exact queue order without needing
/// the (non-realtime-capable) maintenance_queue_view.
class TechnicianQueueScreen extends ConsumerWidget {
  const TechnicianQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;
    final allAsync = ref.watch(visibleMaintenanceRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الصيانة'),
        actions: const [NotificationBellIcon()],
      ),
      body: allAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الصيانات'),
        data: (all) {
          final queue =
              all
                  .where((r) => kActiveMaintenanceStatuses.contains(r.status))
                  .toList()
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          if (queue.isEmpty) {
            return const EmptyView(
              message: 'لا توجد طلبات صيانة حاليًا',
              icon: Iconsax.setting_2_copy,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: queue.length,
            itemBuilder: (context, i) {
              final r = queue[i];
              final isMine = r.assignedTechnicianId == profile?.id;
              return _QueueTile(request: r, isMine: isMine);
            },
          );
        },
      ),
    );
  }
}

/// Same colour-coded card as `_MaintenanceTile` in the admin maintenance
/// list, so the queue reads the same way for a technician as it does for an
/// admin — plus a marker for jobs already assigned to this technician.
class _QueueTile extends StatelessWidget {
  final MaintenanceRequest request;
  final bool isMine;
  const _QueueTile({required this.request, required this.isMine});

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
                context.push(Routes.technicianMaintenanceDetail(request.id)),
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
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.customerName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${request.ticketNumber} · ${request.phone} · ${Formatters.date(request.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                      if (isMine) ...[
                        const SizedBox(height: 6),
                        const Icon(
                          Iconsax.personalcard_copy,
                          size: 18,
                          color: Colors.black45,
                        ),
                      ],
                    ],
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
