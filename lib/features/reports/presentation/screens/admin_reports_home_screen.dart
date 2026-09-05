import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/reports_providers.dart';

const reportTypes = <(String type, String label, IconData icon)>[
  ('sales', 'تقرير المبيعات', Icons.point_of_sale_outlined),
  ('profit', 'تقرير الأرباح', Icons.trending_up),
  ('expenses', 'تقرير المصروفات', Icons.remove_circle_outline),
  ('inventory', 'تقرير المخزن', Icons.inventory_2_outlined),
  ('technicians', 'تقرير الصنايعية', Icons.engineering_outlined),
  ('customers', 'تقرير العملاء', Icons.people_outline),
];

class AdminReportsHomeScreen extends ConsumerWidget {
  const AdminReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportDateRangeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.date_range_outlined),
              title: const Text('الفترة الزمنية'),
              subtitle: Text(
                '${Formatters.date(range.from)}  إلى  ${Formatters.date(range.to.subtract(const Duration(days: 1)))}',
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _pickRange(context, ref),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: reportTypes.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final (type, label, icon) = reportTypes[i];
                return ListTile(
                  leading: Icon(icon),
                  title: Text(label),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.push(Routes.adminReportDetail(type)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final current = ref.read(reportDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: current.from,
        end: current.to.subtract(const Duration(days: 1)),
      ),
    );
    if (picked != null) {
      ref
          .read(reportDateRangeProvider.notifier)
          .setRange(picked.start, picked.end.add(const Duration(days: 1)));
    }
  }
}
