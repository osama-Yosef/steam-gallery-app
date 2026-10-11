import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/data/models/app_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/cashbox_balance.dart';
import '../../../data/models/expense_category.dart';
import '../../providers/cashbox_providers.dart';
import '../../widgets/cashbox_kind_selector.dart';
import '../../../../../core/offline/offline_widgets.dart';
import '../../../../../core/utils/input_formatters.dart';

/// One بند on the form: a category, an amount and an optional note.
class _ExpenseLine {
  final amountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  ExpenseCategory? category;

  double get amount => double.tryParse(amountCtrl.text) ?? 0;
  String? get notes =>
      notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();

  void dispose() {
    amountCtrl.dispose();
    notesCtrl.dispose();
  }
}

/// Records one or several expense lines (بنود) at once, all from the same
/// till on the same date. A single line goes through rpc_record_expense as
/// it always did; several go through rpc_record_expenses (0080), all or
/// nothing.
class AdminRecordExpenseScreen extends ConsumerStatefulWidget {
  const AdminRecordExpenseScreen({super.key});

  @override
  ConsumerState<AdminRecordExpenseScreen> createState() =>
      _AdminRecordExpenseScreenState();
}

class _AdminRecordExpenseScreenState
    extends ConsumerState<AdminRecordExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lines = [_ExpenseLine()];
  DateTime _expenseDate = DateTime.now();
  CashboxKind _cashboxKind = CashboxKind.cash;
  bool _submitting = false;

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  double get _total => _lines.fold(0, (s, l) => s + l.amount);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  void _addLine() => setState(() => _lines.add(_ExpenseLine()));

  void _removeLine(_ExpenseLine line) {
    setState(() => _lines.remove(line));
    line.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    final missingCategory = _lines.any((l) => l.category == null);
    if (!valid || missingCategory) {
      if (missingCategory) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('اختر التصنيف أولًا')));
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = ref.read(cashboxRepositoryProvider);
      final result = _lines.length == 1
          ? await repo.recordExpense(
              categoryId: _lines.single.category!.id,
              amount: _lines.single.amount,
              expenseDate: _expenseDate,
              kind: _cashboxKind,
              notes: _lines.single.notes,
            )
          : await repo.recordExpenses(
              lines: [
                for (final l in _lines)
                  (
                    categoryId: l.category!.id,
                    amount: l.amount,
                    notes: l.notes,
                  ),
              ],
              expenseDate: _expenseDate,
              kind: _cashboxKind,
            );
      if (mounted) {
        if (result.queued) showSavedOfflineSnack(context, 'المصروف اتسجل');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final isAdmin =
        ref.watch(currentUserProfileProvider).value?.role == AppRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل مصروف'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Iconsax.category_copy),
              tooltip: 'تصنيفات المصروفات',
              onPressed: () => context.push(Routes.adminExpenseCategories),
            ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل التصنيفات'),
        data: (categories) {
          // An empty dropdown reads as "the app is broken" when the real
          // problem is that no categories exist yet — say so explicitly.
          if (categories.isEmpty) {
            return const EmptyView(
              message: 'لا توجد تصنيفات مصروفات — أضف تصنيفًا أولًا',
              icon: Iconsax.category_copy,
            );
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final (i, line) in _lines.indexed)
                  _LineCard(
                    key: ObjectKey(line),
                    index: i,
                    line: line,
                    categories: categories,
                    numbered: _lines.length > 1,
                    onChanged: () => setState(() {}),
                    onRemove: _lines.length > 1
                        ? () => _removeLine(line)
                        : null,
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _lines.length >= 50 ? null : _addLine,
                    icon: const Icon(Iconsax.add_square_copy),
                    label: const Text('إضافة بند'),
                  ),
                ),
                if (_lines.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('إجمالي ${_lines.length} بنود: '),
                        MoneyText(
                          _total,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                const Text('يُصرف من'),
                const SizedBox(height: 8),
                CashboxKindSelector(
                  value: _cashboxKind,
                  onChanged: (k) => setState(() => _cashboxKind = k),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تاريخ المصروف'),
                  subtitle: Text(Formatters.date(_expenseDate)),
                  trailing: const Icon(Iconsax.calendar_copy),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.tick_circle_copy),
                  label: Text(
                    _lines.length == 1
                        ? 'تسجيل المصروف'
                        : 'تسجيل ${_lines.length} بنود',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  final int index;
  final _ExpenseLine line;
  final List<ExpenseCategory> categories;
  final bool numbered;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _LineCard({
    super.key,
    required this.index,
    required this.line,
    required this.categories,
    required this.numbered,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final fields = Column(
      children: [
        if (numbered)
          Row(
            children: [
              Expanded(
                child: Text(
                  'بند ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Iconsax.trash_copy),
                  tooltip: 'حذف البند',
                  onPressed: onRemove,
                ),
            ],
          ),
        DropdownButtonFormField<ExpenseCategory>(
          initialValue: line.category,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'التصنيف'),
          items: categories
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (c) {
            line.category = c;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: line.amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [moneyInputFormatter],
          decoration: const InputDecoration(labelText: 'المبلغ'),
          onChanged: (_) => onChanged(),
          validator: (v) {
            final n = double.tryParse(v ?? '');
            if (n == null || n <= 0) return 'أدخل مبلغًا صحيحًا';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: line.notesCtrl,
          decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
          maxLines: numbered ? 1 : 2,
        ),
      ],
    );
    if (!numbered) return fields;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(12), child: fields),
    );
  }
}
