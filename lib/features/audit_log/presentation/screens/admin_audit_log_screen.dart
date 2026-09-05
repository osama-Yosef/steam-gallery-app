import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/models/audit_log_entry.dart';
import '../providers/audit_log_providers.dart';

class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() =>
      _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  String? _tableName;
  DateTime? _from;
  DateTime? _to;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(
      auditLogEntriesProvider(tableName: _tableName, from: _from, to: _to),
    );
    final tableNamesAsync = ref.watch(auditLogTableNamesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('سجل العمليات')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: tableNamesAsync.when(
                    data: (names) => DropdownButtonFormField<String?>(
                      initialValue: _tableName,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'الجدول'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('كل الجداول'),
                        ),
                        ...names.map(
                          (n) => DropdownMenuItem(
                            value: n,
                            child: Text(n, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _tableName = v),
                    ),
                    loading: () => const SizedBox(height: 56),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'فترة زمنية',
                  icon: const Icon(Icons.date_range_outlined),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      initialDateRange: _from != null && _to != null
                          ? DateTimeRange(start: _from!, end: _to!)
                          : null,
                    );
                    if (range != null) {
                      setState(() {
                        _from = range.start;
                        _to = range.end.add(const Duration(days: 1));
                      });
                    }
                  },
                ),
                if (_from != null)
                  IconButton(
                    tooltip: 'إلغاء الفلتر الزمني',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _from = null;
                      _to = null;
                    }),
                  ),
              ],
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => const ErrorView(message: 'تعذَّر تحميل السجل'),
              data: (entries) {
                if (entries.isEmpty) {
                  return const EmptyView(
                    message: 'لا توجد عمليات مسجَّلة',
                    icon: Icons.fact_check_outlined,
                  );
                }
                return ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _AuditTile(entry: entries[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final AuditLogEntry entry;
  const _AuditTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(_actionIcon(entry.action)),
      title: Text('${_actionLabel(entry.action)} · ${entry.tableName}'),
      subtitle: Text(
        '${entry.actorName ?? 'النظام'} · ${Formatters.dateTime(entry.createdAt)}',
      ),
      children: [
        if (entry.oldData != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'قبل: ${entry.oldData}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        if (entry.newData != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'بعد: ${entry.newData}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  IconData _actionIcon(String action) => switch (action) {
    'INSERT' => Icons.add_circle_outline,
    'UPDATE' => Icons.edit_outlined,
    'DELETE' => Icons.delete_outline,
    _ => Icons.receipt_long_outlined,
  };

  String _actionLabel(String action) => switch (action) {
    'INSERT' => 'إضافة',
    'UPDATE' => 'تعديل',
    'DELETE' => 'حذف',
    _ => action,
  };
}
