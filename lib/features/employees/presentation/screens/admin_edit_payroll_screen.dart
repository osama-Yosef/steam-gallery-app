import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/widgets/amount_row.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cashbox/data/models/cashbox_balance.dart';
import '../../../cashbox/presentation/providers/cashbox_providers.dart';
import '../../data/models/employee_models.dart';
import '../providers/employees_providers.dart';

/// Corrects a salary already paid, or cancels it so the month can be paid
/// again (admin only, 0091). The difference in the net moves through the
/// till it was paid from; the "مرتبات" expense follows what was earned.
class AdminEditPayrollScreen extends ConsumerStatefulWidget {
  final EmployeePayroll payroll;
  final Employee employee;
  const AdminEditPayrollScreen({
    super.key,
    required this.payroll,
    required this.employee,
  });

  @override
  ConsumerState<AdminEditPayrollScreen> createState() =>
      _AdminEditPayrollScreenState();
}

class _AdminEditPayrollScreenState
    extends ConsumerState<AdminEditPayrollScreen> {
  late final _absenceCtrl = TextEditingController(
    text: Formatters.plain(widget.payroll.absenceDeduction),
  );
  late final _bonusCtrl = TextEditingController(
    text: Formatters.plain(widget.payroll.bonus),
  );
  late final _advanceCtrl = TextEditingController(
    text: Formatters.plain(widget.payroll.advanceDeduction),
  );
  late final _notesCtrl = TextEditingController(
    text: widget.payroll.notes ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_absenceCtrl, _bonusCtrl, _advanceCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0;

  /// What can be deducted: the balance, plus what this salary already took.
  double get _advanceLimit =>
      widget.employee.advanceBalance + widget.payroll.advanceDeduction;

  String? get _problem {
    final absence = _val(_absenceCtrl);
    final advance = _val(_advanceCtrl);
    final earned = widget.payroll.baseSalary - absence + _val(_bonusCtrl);
    if (absence > widget.payroll.baseSalary) return 'خصم الغياب أكبر من المرتب';
    if (advance > _advanceLimit) return 'خصم السلف أكبر من السلف اللي عليه';
    if (advance > earned) return 'خصم السلف أكبر من المستحق';
    return null;
  }

  void _refresh() {
    final id = widget.employee.id;
    ref.invalidate(employeeProvider(id));
    ref.invalidate(employeesProvider);
    ref.invalidate(employeeAdvancesProvider(id));
    ref.invalidate(employeePayrollsProvider(id));
    ref.invalidate(cashboxBalancesProvider);
    ref.invalidate(cashTransactionsProvider);
    ref.invalidate(expensesProvider);
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _saving = true);
    try {
      await action();
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _problem != null) return;
    final notes = _notesCtrl.text.trim();
    await _run(
      () => ref
          .read(employeesRepositoryProvider)
          .editPayroll(
            payrollId: widget.payroll.id,
            absenceDeduction: _val(_absenceCtrl),
            bonus: _val(_bonusCtrl),
            advanceDeduction: _val(_advanceCtrl),
            notes: notes.isEmpty ? null : notes,
          ),
      'تم تعديل المرتب',
    );
  }

  Future<void> _delete() async {
    final p = widget.payroll;
    final confirmed = await showConfirmDialog(
      context,
      title: 'إلغاء المرتب',
      message:
          'هيرجع ${Formatters.currency(p.netAmount)} لـ${cashboxKindLabelAr(p.kind)}، '
          'ويتشال مصروف المرتب، وخصم السلف يرجع عليه تاني. '
          'وبعدها تقدر تصرف الشهر ده من جديد.',
      confirmLabel: 'إلغاء المرتب',
      cancelLabel: 'رجوع',
      isDangerous: true,
    );
    if (!confirmed) return;
    await _run(
      () =>
          ref.read(employeesRepositoryProvider).deletePayroll(payrollId: p.id),
      'تم إلغاء المرتب',
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payroll;
    final absence = _val(_absenceCtrl);
    final bonus = _val(_bonusCtrl);
    final advance = _val(_advanceCtrl);
    final earned = p.baseSalary - absence + bonus;
    final net = earned - advance;
    final diff = net - p.netAmount;
    final problem = _problem;
    void changed(String _) => setState(() {});

    Widget money(TextEditingController c, String label, {String? helper}) =>
        TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [moneyInputFormatter],
          decoration: InputDecoration(labelText: label, helperText: helper),
          onChanged: changed,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مرتب ${widget.employee.fullName} · ${Formatters.month(p.periodMonth)}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.trash_copy),
            tooltip: 'إلغاء المرتب',
            onPressed: _saving ? null : _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          money(_absenceCtrl, 'خصم الغياب', helper: '${p.absentDays} يوم غياب'),
          const SizedBox(height: 12),
          money(_bonusCtrl, 'مكافأة / إضافي'),
          const SizedBox(height: 12),
          money(
            _advanceCtrl,
            'خصم من السلف',
            helper: 'أقصى خصم ${Formatters.currency(_advanceLimit)}',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  AmountRow('المرتب الأساسي', p.baseSalary),
                  if (absence > 0) AmountRow('خصم الغياب', -absence),
                  if (bonus > 0) AmountRow('مكافأة', bonus),
                  AmountRow('المستحق (يُسجَّل مصروف مرتبات)', earned),
                  if (advance > 0) AmountRow('خصم السلف', -advance),
                  const Divider(),
                  AmountRow('الصافي', net, bold: true),
                ],
              ),
            ),
          ),
          if (problem != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                problem,
                style: const TextStyle(color: AppColors.danger),
              ),
            )
          else if (diff.abs() >= 0.005)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                diff > 0
                    ? 'هيتخصم ${Formatters.currency(diff)} زيادة من ${cashboxKindLabelAr(p.kind)}'
                    : 'هيرجع ${Formatters.currency(-diff)} لـ${cashboxKindLabelAr(p.kind)}',
                style: TextStyle(
                  color: diff > 0 ? AppColors.danger : AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving || problem != null ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconsax.tick_circle_copy),
            label: const Text('حفظ التعديل'),
          ),
        ],
      ),
    );
  }
}

/// Opens [AdminEditPayrollScreen] for the salary of an expense, loading the
/// employee it needs first.
class AdminEditPayrollLoader extends ConsumerWidget {
  final EmployeePayroll payroll;
  const AdminEditPayrollLoader({super.key, required this.payroll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(employeeProvider(payroll.employeeId!))
        .when(
          loading: () => Scaffold(appBar: AppBar(), body: const LoadingView()),
          error: (e, _) => Scaffold(
            appBar: AppBar(),
            body: const ErrorView(message: 'تعذَّر تحميل بيانات الموظف'),
          ),
          data: (employee) =>
              AdminEditPayrollScreen(payroll: payroll, employee: employee),
        );
  }
}
