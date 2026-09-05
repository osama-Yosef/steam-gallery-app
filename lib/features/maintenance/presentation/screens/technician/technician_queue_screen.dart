import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../notifications/presentation/widgets/notification_bell_icon.dart';
import '../../../data/models/maintenance_request.dart';
import '../../providers/maintenance_providers.dart';

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
              icon: Icons.build_outlined,
            );
          }
          return ListView.separated(
            itemCount: queue.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = queue[i];
              final isMine = r.assignedTechnicianId == profile?.id;
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(r.customerName),
                subtitle: Text(
                  '${r.phone} · ${maintenanceStatusLabelAr(r.status)}',
                ),
                trailing: isMine
                    ? const Icon(Icons.person_pin_circle_outlined)
                    : null,
                onTap: () =>
                    context.push(Routes.technicianMaintenanceDetail(r.id)),
              );
            },
          );
        },
      ),
    );
  }
}
