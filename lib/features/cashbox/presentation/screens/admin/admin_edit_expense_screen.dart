import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/input_formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/expense_category.dart';
import '../../providers/cashbox_providers.dart';

/// Corrects a recorded expense — its amount, category, date or note
/// (admin and sales, 0087). The difference comes out of, or goes back
/// into, the till the expense was paid from.
class AdminEditExpenseScreen extends ConsumerStatefulWidget {
  final Expense expense;
  const AdminEditExpenseScreen({super.key, required this.expense});

  @override
  ConsumerState<AdminEditExpenseScreen> createState() =>
      _AdminEditExpenseScreenState();
}

class _AdminEditExpenseScreenState
    extends ConsumerState<AdminEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _amountCtrl = TextEditingController(
    text: Formatters.plain(widget.expense.amount),
  );
  late final _notesCtrl = TextEditingController(
    text: widget.expense.notes ?? '',
  );
  late DateTime _date = widget.expense.expenseDate;
  late String? _categoryId = widget.expense.categoryId;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final categoryId = _categoryId;
    if (categoryId == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(cashboxRepositoryProvider)
          .editExpense(
            expenseId: widget.expense.id,
            categoryId: categoryId,
            amount: double.parse(_amount.toStringAsFixed(2)),
            expenseDate: _date,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      ref.invalidate(expensesProvider);
      ref.invalidate(cashboxBalancesProvider);
      ref.invalidate(cashTransactionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تعديل المصروف')));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppException.from(e).messageAr)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.expense;
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final diff = _amount - e.amount;

    return Scaffold(
      appBar: AppBar(title: Text('تعديل مصروف #${e.expenseNumber}')),
      body: categoriesAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorView(
          message: 'تعذَّر تحميل التصنيفات',
          onRetry: () => ref.invalidate(expenseCategoriesProvider),
        ),
        data: (active) {
          // A category stopped since keeps showing on its own expense.
          final categories = <ExpenseCategory>[
            ...active,
            if (_categoryId != null && !active.any((c) => c.id == _categoryId))
              ExpenseCategory(
                id: _categoryId!,
                name: e.categoryName,
                isActive: false,
              ),
          ];
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  validator: (v) => v == null ? 'اختر التصنيف' : null,
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [moneyInputFormatter],
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  validator: (_) =>
                      _amount <= 0 ? 'أدخل مبلغًا صحيحًا' : null,
                  onChanged: (_) => setState(() {}),
                ),
                if (diff.abs() >= 0.005)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      diff > 0
                          ? 'هيتخصم ${Formatters.currency(diff)} زيادة من الخزنة'
                          : 'هيرجع ${Formatters.currency(-diff)} للخزنة',
                      style: TextStyle(
                        color: diff > 0 ? AppColors.danger : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Iconsax.calendar_1_copy),
                  title: const Text('التاريخ'),
                  subtitle: Text(Formatters.date(_date)),
                  onTap: _pickDate,
                ),
                TextFormField(
                  controller: _notesCtrl,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
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
        },
      ),
    );
  }
}
