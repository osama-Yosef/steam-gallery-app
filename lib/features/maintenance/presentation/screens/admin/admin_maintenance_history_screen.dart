import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/history_query.dart';
import '../../../../../core/widgets/history_results_list.dart';
import '../../../../../core/widgets/history_search_bar.dart';
import '../../providers/maintenance_providers.dart';
import '../../widgets/admin_maintenance_tile.dart';

/// "سجل الصيانة": every maintenance request, by ticket number, customer
/// name/phone and the days it was opened. The maintenance tab itself only
/// keeps open requests plus today's, so finished ones are looked up here.
class AdminMaintenanceHistoryScreen extends ConsumerStatefulWidget {
  const AdminMaintenanceHistoryScreen({super.key});

  @override
  ConsumerState<AdminMaintenanceHistoryScreen> createState() =>
      _AdminMaintenanceHistoryScreenState();
}

class _AdminMaintenanceHistoryScreenState
    extends ConsumerState<AdminMaintenanceHistoryScreen> {
  var _query = const HistoryQuery();

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(maintenanceHistoryProvider(_query));

    return Scaffold(
      appBar: AppBar(title: const Text('سجل الصيانة')),
      body: Column(
        children: [
          HistorySearchBar(
            query: _query,
            hint: 'رقم الطلب أو اسم/تليفون العميل',
            onChanged: (q) => setState(() => _query = q),
          ),
          Expanded(
            child: HistoryResultsList(
              results: results,
              emptyMessage: 'لا توجد طلبات صيانة مطابقة',
              onRetry: () => ref.invalidate(maintenanceHistoryProvider(_query)),
              onLoadMore: () => ref
                  .read(maintenanceHistoryProvider(_query).notifier)
                  .loadMore(),
              itemBuilder: (context, request) =>
                  AdminMaintenanceTile(request: request),
            ),
          ),
        ],
      ),
    );
  }
}
