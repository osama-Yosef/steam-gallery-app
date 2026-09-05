import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/maintenance_request.dart';
import '../../providers/maintenance_providers.dart';

class CustomerMaintenanceHomeScreen extends ConsumerWidget {
  const CustomerMaintenanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('الصيانة')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.customerMaintenanceNew),
        icon: const Icon(Icons.add),
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
                        icon: Icons.build_outlined,
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

class _RequestTile extends StatelessWidget {
  final MaintenanceRequest request;
  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('طلب #${request.ticketNumber}'),
      subtitle: Text(
        '${maintenanceStatusLabelAr(request.status)} · ${Formatters.date(request.createdAt)}',
      ),
      trailing: const Icon(Icons.chevron_left),
      onTap: () => context.push(Routes.customerMaintenanceDetail(request.id)),
    );
  }
}
