import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/reports_providers.dart';

const reportTypes = <(String type, String label, IconData icon, Color color)>[
  ('sales', 'تقرير المبيعات', Iconsax.card_pos_copy, Color(0xFF3B5BFF)),
  ('profit', 'تقرير الأرباح', Iconsax.trend_up_copy, Color(0xFF10B981)),
  (
    'orders_profit',
    'أرباح الطلبات',
    Iconsax.chart_success_copy,
    Color(0xFF7C3AED),
  ),
  ('expenses', 'تقرير المصروفات', Iconsax.money_remove_copy, Color(0xFFEF4444)),
  ('inventory', 'تقرير المخزن', Iconsax.box_copy, Color(0xFFF59E0B)),
  (
    'technicians',
    'تقرير الصنايعية',
    Iconsax.personalcard_copy,
    Color(0xFF0EA5E9),
  ),
  ('customers', 'تقرير العملاء', Iconsax.people_copy, Color(0xFFEC4899)),
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
              leading: const Icon(Iconsax.calendar_1_copy),
              title: const Text('الفترة الزمنية'),
              subtitle: Text(
                '${Formatters.date(range.from)}  إلى  ${Formatters.date(range.to.subtract(const Duration(days: 1)))}',
              ),
              trailing: const Icon(Iconsax.edit_2_copy),
              onTap: () => _pickRange(context, ref),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: reportTypes.length,
              itemBuilder: (context, i) {
                final (type, label, icon, color) = reportTypes[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Material(
                      color: color.withValues(alpha: 0.08),
                      child: InkWell(
                        onTap: () =>
                            context.push(Routes.adminReportDetail(type)),
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
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  label,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Icon(Iconsax.arrow_left_2_copy, color: color),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
