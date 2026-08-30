import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/expense_category.dart';
import '../../providers/cashbox_providers.dart';

class AdminRecordExpenseScreen extends ConsumerStatefulWidget {
  const AdminRecordExpenseScreen({super.key});

  @override
  ConsumerState<AdminRecordExpenseScreen> createState() => _AdminRecordExpenseScreenState();
}

class _AdminRecordExpenseScreenState extends ConsumerState<AdminRecordExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  ExpenseCategory? _selectedCategory;
  DateTime _expenseDate = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر التصنيف أولًا')));
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(cashboxRepositoryProvider).recordExpense(
            categoryId: _selectedCategory!.id,
            amount: double.parse(_amountCtrl.text),
            expenseDate: _expenseDate,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل مصروف')),
      body: categoriesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التصنيفات'),
        data: (categories) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<ExpenseCategory>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (c) => setState(() => _selectedCategory = c),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'أدخل مبلغًا صحيحًا';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تاريخ المصروف'),
                  subtitle: Text(Formatters.date(_expenseDate)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text('تسجيل المصروف'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
