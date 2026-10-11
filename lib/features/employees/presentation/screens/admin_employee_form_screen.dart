import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/models/employee_models.dart';
import '../providers/employees_providers.dart';

/// Add an employee ([employeeId] null) or edit one. Employees are never
/// deleted — their advances and salaries stay on record — only stopped.
class AdminEmployeeFormScreen extends ConsumerWidget {
  final String? employeeId;
  const AdminEmployeeFormScreen({super.key, this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = employeeId;
    if (id == null) return const _EmployeeForm(employee: null);
    return ref
        .watch(employeeProvider(id))
        .when(
          loading: () => Scaffold(appBar: AppBar(), body: const LoadingView()),
          error: (e, _) => Scaffold(
            appBar: AppBar(),
            body: const ErrorView(message: 'تعذَّر تحميل بيانات الموظف'),
          ),
          data: (e) => _EmployeeForm(employee: e),
        );
  }
}

class _EmployeeForm extends ConsumerStatefulWidget {
  final Employee? employee;
  const _EmployeeForm({required this.employee});

  @override
  ConsumerState<_EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends ConsumerState<_EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.employee?.fullName);
  late final _phoneCtrl = TextEditingController(text: widget.employee?.phone);
  late final _jobCtrl = TextEditingController(text: widget.employee?.jobTitle);
  late final _salaryCtrl = TextEditingController(
    text: widget.employee?.monthlySalary.toStringAsFixed(2),
  );
  late final _notesCtrl = TextEditingController(text: widget.employee?.notes);
  late DateTime? _hireDate = widget.employee?.hireDate;
  late bool _isActive = widget.employee?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _jobCtrl,
      _salaryCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _pickHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _hireDate = picked);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(employeesRepositoryProvider)
          .saveEmployee(
            id: widget.employee?.id,
            fullName: _nameCtrl.text.trim(),
            phone: _text(_phoneCtrl),
            jobTitle: _text(_jobCtrl),
            monthlySalary: double.parse(_salaryCtrl.text),
            hireDate: _hireDate,
            notes: _text(_notesCtrl),
            isActive: _isActive,
          );
      ref.invalidate(employeesProvider);
      if (widget.employee != null) {
        ref.invalidate(employeeProvider(widget.employee!.id));
      }
      if (mounted) Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    final isNew = widget.employee == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'موظف جديد' : 'تعديل بيانات الموظف')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              autofocus: isNew,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'اسم الموظف'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'اكتب اسم الموظف' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _jobCtrl,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'الوظيفة (اختياري)',
                hintText: 'مثال: بائع، فني، محاسب',
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _salaryCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [moneyInputFormatter],
              decoration: const InputDecoration(labelText: 'المرتب الشهري'),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n < 0) return 'أدخل مرتبًا صحيحًا';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف (اختياري)',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تاريخ التعيين'),
              subtitle: Text(
                _hireDate == null ? 'غير محدد' : Formatters.date(_hireDate!),
              ),
              trailing: const Icon(Iconsax.calendar_copy),
              onTap: _pickHireDate,
            ),
            TextFormField(
              controller: _notesCtrl,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              maxLines: 2,
            ),
            if (!isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('يعمل حاليًا'),
                subtitle: const Text(
                  'الموظف الموقوف لا يظهر في الحضور ولا تُصرف له سلف',
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.tick_circle_copy),
              label: Text(isNew ? 'إضافة الموظف' : 'حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }
}
