import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/offline_widgets.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cashbox/data/models/cashbox_balance.dart';
import '../../../cashbox/presentation/providers/cashbox_providers.dart';
import '../../../cashbox/presentation/widgets/cashbox_kind_selector.dart';
import '../../data/models/employee_models.dart';
import '../providers/employees_providers.dart';
import 'admin_attendance_screen.dart';
import 'admin_pay_salary_screen.dart';

/// One employee: salary and advance balance up top, then their attendance
/// month by month, their advances and their salary payments.
class AdminEmployeeDetailScreen extends ConsumerWidget {
  final String employeeId;
  const AdminEmployeeDetailScreen({super.key, required this.employeeId});

  void _refresh(WidgetRef ref) {
    ref.invalidate(employeeProvider(employeeId));
    ref.invalidate(employeesProvider);
    ref.invalidate(employeeAdvancesProvider(employeeId));
    ref.invalidate(employeePayrollsProvider(employeeId));
    ref.invalidate(cashboxBalancesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeProvider(employeeId));
    return employeeAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: 'تعذَّر تحميل بيانات الموظف',
          onRetry: () => ref.invalidate(employeeProvider(employeeId)),
        ),
      ),
      data: (employee) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(employee.fullName),
            actions: [
              IconButton(
                icon: const Icon(Iconsax.edit_copy),
                tooltip: 'تعديل',
                onPressed: () =>
                    context.push(Routes.adminEmployeeEdit(employeeId)),
              ),
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: _Header(
                  employee: employee,
                  onAdvance: () async {
                    if (await showAdvanceDialog(context, ref, employee)) {
                      _refresh(ref);
                    }
                  },
                  onPay: () async {
                    final paid = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminPaySalaryScreen(employee: employee),
                      ),
                    );
                    if (paid == true) _refresh(ref);
                  },
                ),
              ),
              const SliverToBoxAdapter(
                child: TabBar(
                  tabs: [
                    Tab(text: 'الحضور'),
                    Tab(text: 'السلف'),
                    Tab(text: 'المرتبات'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _AttendanceTab(employeeId: employeeId),
                _AdvancesTab(employeeId: employeeId),
                _PayrollsTab(employeeId: employeeId),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Employee employee;
  final VoidCallback onAdvance;
  final VoidCallback onPay;
  const _Header({
    required this.employee,
    required this.onAdvance,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final e = employee;
    final theme = Theme.of(context);
    Widget stat(String label, Widget value) => Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          if (e.jobTitle != null || e.phone != null || !e.isActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                [
                  if (e.jobTitle != null) e.jobTitle!,
                  if (e.phone != null) e.phone!,
                  if (!e.isActive) 'موقوف',
                ].join(' · '),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  stat(
                    'المرتب الشهري',
                    MoneyText(
                      e.monthlySalary,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  stat(
                    'سلف عليه',
                    MoneyText(
                      e.advanceBalance,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  stat(
                    'آخر مرتب',
                    Text(
                      e.lastPaidMonth == null
                          ? '—'
                          : Formatters.month(e.lastPaidMonth!),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: e.isActive ? onAdvance : null,
                  icon: const Icon(Iconsax.money_send_copy),
                  label: const Text('صرف سلفة'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPay,
                  icon: const Icon(Iconsax.wallet_check_copy),
                  label: const Text('صرف مرتب'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// سلفة: amount, the till it comes out of, a date and a note. True if given.
Future<bool> showAdvanceDialog(
  BuildContext context,
  WidgetRef ref,
  Employee employee,
) async {
  final amountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  var kind = CashboxKind.cash;
  var date = DateUtils.dateOnly(DateTime.now());
  String? error;
  var saving = false;

  final done = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text('سلفة لـ ${employee.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [moneyInputFormatter],
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              const Text('من خزنة'),
              const SizedBox(height: 6),
              CashboxKindSelector(
                value: kind,
                onChanged: (k) => setDialogState(() => kind = k),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('التاريخ'),
                subtitle: Text(Formatters.date(date)),
                trailing: const Icon(Iconsax.calendar_copy),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setDialogState(() => date = picked);
                },
              ),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (amount == null || amount <= 0) {
                      setDialogState(() => error = 'أدخل مبلغًا صحيحًا');
                      return;
                    }
                    setDialogState(() {
                      error = null;
                      saving = true;
                    });
                    try {
                      final notes = notesCtrl.text.trim();
                      final result = await ref
                          .read(employeesRepositoryProvider)
                          .giveAdvance(
                            employeeId: employee.id,
                            employeeName: employee.fullName,
                            amount: amount,
                            date: date,
                            kind: kind,
                            notes: notes.isEmpty ? null : notes,
                          );
                      if (ctx.mounted) {
                        if (result.queued) {
                          showSavedOfflineSnack(ctx, 'السلفة اتسجلت');
                        }
                        Navigator.of(ctx).pop(true);
                      }
                    } catch (e) {
                      setDialogState(() {
                        saving = false;
                        error = AppException.from(e).messageAr;
                      });
                    }
                  },
            child: const Text('صرف السلفة'),
          ),
        ],
      ),
    ),
  );
  amountCtrl.dispose();
  notesCtrl.dispose();
  return done == true;
}

class _AttendanceTab extends ConsumerStatefulWidget {
  final String employeeId;
  const _AttendanceTab({required this.employeeId});

  @override
  ConsumerState<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<_AttendanceTab> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      employeeAttendanceProvider(widget.employeeId, _month),
    );
    final isCurrent =
        _month.year == DateTime.now().year &&
        _month.month == DateTime.now().month;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Iconsax.arrow_right_3_copy),
              tooltip: 'الشهر السابق',
              onPressed: () => _shift(-1),
            ),
            Expanded(
              child: Text(
                Formatters.month(_month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              icon: const Icon(Iconsax.arrow_left_2_copy),
              tooltip: 'الشهر التالي',
              onPressed: isCurrent ? null : () => _shift(1),
            ),
          ],
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingView(),
            error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الحضور'),
            data: (records) {
              if (records.isEmpty) {
                return const EmptyView(
                  message: 'لا يوجد حضور مسجَّل في الشهر ده',
                  icon: Iconsax.calendar_copy,
                );
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final s in AttendanceStatus.values)
                          Chip(
                            label: Text(
                              '${attendanceStatusLabelAr(s)}: '
                              '${records.where((r) => r.status == s).length}',
                            ),
                            backgroundColor: attendanceStatusColor(
                              s,
                            ).withValues(alpha: 0.15),
                          ),
                      ],
                    ),
                  ),
                  for (final r in records.reversed)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.circle,
                        size: 12,
                        color: attendanceStatusColor(r.status),
                      ),
                      title: Text(Formatters.date(r.workDate)),
                      trailing: Text(attendanceStatusLabelAr(r.status)),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdvancesTab extends ConsumerWidget {
  final String employeeId;
  const _AdvancesTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(employeeAdvancesProvider(employeeId))
        .when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'تعذَّر تحميل السلف'),
          data: (advances) {
            if (advances.isEmpty) {
              return const EmptyView(
                message: 'لا توجد سلف',
                icon: Iconsax.money_send_copy,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: advances.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = advances[i];
                return ListTile(
                  leading: Icon(cashboxKindIcon(a.kind)),
                  title: Text(Formatters.date(a.advanceDate)),
                  subtitle: Text(
                    cashboxKindLabelAr(a.kind) +
                        (a.notes == null ? '' : ' · ${a.notes}'),
                  ),
                  trailing: MoneyText(a.amount),
                );
              },
            );
          },
        );
  }
}

class _PayrollsTab extends ConsumerWidget {
  final String employeeId;
  const _PayrollsTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(employeePayrollsProvider(employeeId))
        .when(
          loading: () => const LoadingView(),
          error: (e, _) => const ErrorView(message: 'تعذَّر تحميل المرتبات'),
          data: (payrolls) {
            if (payrolls.isEmpty) {
              return const EmptyView(
                message: 'لم يُصرف أي مرتب بعد',
                icon: Iconsax.wallet_check_copy,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: payrolls.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = payrolls[i];
                final parts = [
                  'المرتب ${Formatters.currency(p.baseSalary)}',
                  if (p.absenceDeduction > 0)
                    'غياب ${p.absentDays} يوم −${Formatters.currency(p.absenceDeduction)}',
                  if (p.bonus > 0) 'مكافأة +${Formatters.currency(p.bonus)}',
                  if (p.advanceDeduction > 0)
                    'خصم سلف −${Formatters.currency(p.advanceDeduction)}',
                  cashboxKindLabelAr(p.kind),
                ];
                return ListTile(
                  title: Text(Formatters.month(p.periodMonth)),
                  subtitle: Text(
                    parts.join(' · ') + (p.notes == null ? '' : '\n${p.notes}'),
                  ),
                  isThreeLine: p.notes != null,
                  trailing: MoneyText(p.netAmount),
                );
              },
            );
          },
        );
  }
}
