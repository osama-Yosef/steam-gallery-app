import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/expense_category.dart';
import '../../../data/repositories/cashbox_repository.dart';
import '../../providers/cashbox_providers.dart';

/// The expense categories (بنود المصروفات): add new ones, stop ones no
/// longer used. A category is never deleted — past expenses point at it —
/// a stopped one just leaves the expense form.
class AdminExpenseCategoriesScreen extends ConsumerWidget {
  const AdminExpenseCategoriesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصنيف مصروفات جديد'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'اسم التصنيف',
            hintText: 'مثال: إنترنت',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    await _run(context, ref, (repo) => repo.addExpenseCategory(name));
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(CashboxRepository repo) action,
  ) async {
    try {
      await action(ref.read(cashboxRepositoryProvider));
      ref.invalidate(allExpenseCategoriesProvider);
      ref.invalidate(expenseCategoriesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allExpenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تصنيفات المصروفات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Iconsax.add_copy),
        label: const Text('تصنيف جديد'),
      ),
      body: categoriesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل التصنيفات',
          onRetry: () => ref.invalidate(allExpenseCategoriesProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyView(
              message: 'لا توجد تصنيفات بعد',
              icon: Iconsax.category_copy,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final ExpenseCategory c = categories[i];
              return SwitchListTile(
                title: Text(c.name),
                subtitle: Text(c.isActive ? 'مستخدم' : 'موقوف'),
                value: c.isActive,
                onChanged: (v) => _run(
                  context,
                  ref,
                  (repo) => repo.setExpenseCategoryActive(c.id, v),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
