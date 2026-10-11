import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/offline_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/widgets/amount_row.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cashbox/data/models/cashbox_balance.dart';
import '../../../cashbox/presentation/widgets/cashbox_kind_selector.dart';
import '../../data/models/employee_models.dart';
import '../providers/employees_providers.dart';

/// Pays one month's salary. The month's attendance suggests the absence
/// deduction (salary / 30 per absent day) and the advance balance suggests
/// what to deduct; both can be changed, and a bonus added, before paying.
class AdminPaySalaryScreen extends ConsumerStatefulWidget {
  final Employee employee;
  const AdminPaySalaryScreen({super.key, required this.employee});

  @override
  ConsumerState<AdminPaySalaryScreen> createState() =>
      _AdminPaySalaryScreenState();
}

class _AdminPaySalaryScreenState extends ConsumerState<AdminPaySalaryScreen> {
  late DateTime _month = _defaultMonth();
  PayrollPreview? _preview;
  Object? _previewError;
  final _absenceCtrl = TextEditingController();
  final _bonusCtrl = TextEditingController(text: '0');
  final _advanceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  CashboxKind _kind = CashboxKind.main;
  bool _paying = false;

  /// The month after the last one paid, else this month.
  DateTime _defaultMonth() {
    final now = DateTime.now();
    final last = widget.employee.lastPaidMonth;
    final next = last == null ? null : DateTime(last.year, last.month + 1);
    if (next != null && !next.isAfter(DateTime(now.year, now.month))) {
      return next;
    }
    return DateTime(now.year, now.month);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_absenceCtrl, _bonusCtrl, _advanceCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _preview = null;
      _previewError = null;
    });
    try {
      final p = await ref
          .read(employeesRepositoryProvider)
          .payrollPreview(widget.employee.id, _month);
      if (!mounted) return;
      final earned = p.baseSalary - p.absenceDeduction;
      setState(() {
        _preview = p;
        _absenceCtrl.text = p.absenceDeduction.toStringAsFixed(2);
        _bonusCtrl.text = '0';
        _advanceCtrl.text = math
            .max(0, math.min(p.advanceBalance, earned))
            .toStringAsFixed(2);
      });
    } catch (e) {
      if (mounted) setState(() => _previewError = e);
    }
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0;

  /// Why the figures can't be paid as they are, or null.
  String? _problem(PayrollPreview p) {
    final absence = _val(_absenceCtrl);
    final advance = _val(_advanceCtrl);
    final earned = p.baseSalary - absence + _val(_bonusCtrl);
    if (absence > p.baseSalary) return 'خصم الغياب أكبر من المرتب';
    if (advance > p.advanceBalance) return 'خصم السلف أكبر من السلف اللي عليه';
    if (advance > earned) return 'خصم السلف أكبر من المستحق';
    return null;
  }

  Future<void> _pay(PayrollPreview p) async {
    if (_paying || _problem(p) != null) return;
    setState(() => _paying = true);
    try {
      final notes = _notesCtrl.text.trim();
      final result = await ref
          .read(employeesRepositoryProvider)
          .paySalary(
            employeeId: widget.employee.id,
            employeeName: widget.employee.fullName,
            month: _month,
            absenceDeduction: _val(_absenceCtrl),
            bonus: _val(_bonusCtrl),
            advanceDeduction: _val(_advanceCtrl),
            kind: _kind,
            notes: notes.isEmpty ? null : notes,
          );
      if (mounted) {
        if (result.queued) showSavedOfflineSnack(context, 'المرتب اتسجل');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      for (var i = 0; i < 12; i++) DateTime(now.year, now.month - i),
    ];
    final p = _preview;

    return Scaffold(
      appBar: AppBar(title: Text('مرتب ${widget.employee.fullName}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<DateTime>(
            initialValue: months.contains(_month) ? _month : null,
            decoration: const InputDecoration(labelText: 'عن شهر'),
            items: [
              for (final m in months)
                DropdownMenuItem(value: m, child: Text(Formatters.month(m))),
            ],
            onChanged: (m) {
              if (m == null) return;
              _month = m;
              _load();
            },
          ),
          const SizedBox(height: 16),
          if (_previewError != null)
            ErrorView(
              message: AppException.from(_previewError!).messageAr,
              onRetry: _load,
            )
          else if (p == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (p.alreadyPaid)
            const Card(
              child: ListTile(
                leading: Icon(
                  Iconsax.tick_circle_copy,
                  color: AppColors.success,
                ),
                title: Text('مرتب الشهر ده اتصرف قبل كدا'),
                subtitle: Text('اختر شهر تاني'),
              ),
            )
          else
            ..._form(p),
        ],
      ),
    );
  }

  List<Widget> _form(PayrollPreview p) {
    final theme = Theme.of(context);
    final absence = _val(_absenceCtrl);
    final bonus = _val(_bonusCtrl);
    final advance = _val(_advanceCtrl);
    final earned = p.baseSalary - absence + bonus;
    final net = earned - advance;
    final problem = _problem(p);
    void changed(String _) => setState(() {});

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              Text('حاضر ${p.presentDays}'),
              Text(
                'غائب ${p.absentDays}',
                style: const TextStyle(color: AppColors.danger),
              ),
              Text('متأخر ${p.lateDays}'),
              Text('إجازة ${p.leaveDays}'),
              Text(
                'اليوم = ${Formatters.currency(p.dailyRate)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _absenceCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [moneyInputFormatter],
        decoration: InputDecoration(
          labelText: 'خصم الغياب',
          helperText: '${p.absentDays} يوم غياب',
        ),
        onChanged: changed,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _bonusCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [moneyInputFormatter],
        decoration: const InputDecoration(labelText: 'مكافأة / إضافي'),
        onChanged: changed,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _advanceCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [moneyInputFormatter],
        decoration: InputDecoration(
          labelText: 'خصم من السلف',
          helperText:
              'عليه سلف بإجمالي ${Formatters.currency(p.advanceBalance)}',
        ),
        onChanged: changed,
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
              AmountRow('الصافي اللي هيتصرف', net, bold: true),
            ],
          ),
        ),
      ),
      if (problem != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(problem, style: const TextStyle(color: AppColors.danger)),
        ),
      const SizedBox(height: 16),
      const Text('يُصرف من'),
      const SizedBox(height: 8),
      CashboxKindSelector(
        value: _kind,
        onChanged: (k) => setState(() => _kind = k),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _notesCtrl,
        decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: _paying || problem != null ? null : () => _pay(p),
        icon: _paying
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Iconsax.wallet_check_copy),
        label: Text('صرف ${Formatters.currency(net)}'),
      ),
    ];
  }
}
