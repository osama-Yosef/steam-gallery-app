import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/maintenance_request.dart';
import '../../providers/maintenance_providers.dart';
import '../../widgets/maintenance_status_chips.dart';

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
    final allAsync = ref.watch(visibleMaintenanceRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الصيانة')),
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
                      _MaintenanceTile(request: filtered[i]),
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

/// A full-width, colour-coded card — same visual language as the customer
/// maintenance tile and the admin order tile, so the status colour says
/// what stage a request is at before its label is even read.
class _MaintenanceTile extends StatelessWidget {
  final MaintenanceRequest request;
  const _MaintenanceTile({required this.request});

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
                context.push(Routes.adminMaintenanceDetail(request.id)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
