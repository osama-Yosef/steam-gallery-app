import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/maintenance_request.dart';
import '../../providers/maintenance_providers.dart';
import '../../widgets/admin_maintenance_tile.dart';
import 'admin_maintenance_history_screen.dart';

/// The requests still open plus today's, live; finished ones from earlier
/// days are in "السجل" ([AdminMaintenanceHistoryScreen]).
class AdminMaintenanceListScreen extends ConsumerStatefulWidget {
  const AdminMaintenanceListScreen({super.key});

  @override
  ConsumerState<AdminMaintenanceListScreen> createState() =>
      _AdminMaintenanceListScreenState();
}

class _AdminMaintenanceListScreenState
    extends ConsumerState<AdminMaintenanceListScreen> {
  MaintenanceStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(openMaintenanceRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الصيانة'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(Routes.adminMaintenanceHistory),
            icon: const Icon(Iconsax.archive_book_copy),
            label: const Text('السجل'),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'النشط',
                  selected: _statusFilter == null,
                  onTap: () => setState(() => _statusFilter = null),
                ),
                for (final s in MaintenanceStatus.values) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: maintenanceStatusLabelAr(s),
                    selected: _statusFilter == s,
                    onTap: () => setState(() => _statusFilter = s),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: allAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) =>
                  const ErrorView(message: 'تعذَّر تحميل الصيانات'),
              data: (all) {
                final filtered =
                    (_statusFilter == null
                            ? all.where(
                                (r) => kActiveMaintenanceStatuses.contains(
                                  r.status,
                                ),
                              )
                            : all.where((r) => r.status == _statusFilter))
                        .toList()
                      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                if (filtered.isEmpty) {
                  return const EmptyView(
                    message: 'لا توجد طلبات صيانة',
                    icon: Iconsax.setting_2_copy,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      AdminMaintenanceTile(request: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
