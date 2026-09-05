import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/product_category.dart';
import '../../../presentation/providers/product_providers.dart';

class AdminCategoryListScreen extends ConsumerWidget {
  const AdminCategoryListScreen({super.key});

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    ProductCategory? existing,
  }) async {
    final ctrl = TextEditingController(text: existing?.name ?? '');
    bool isActive = existing?.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'قسم جديد' : 'تعديل القسم'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(labelText: 'اسم القسم'),
              ),
              if (existing != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('نشط'),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                try {
                  final repo = ref.read(productRepositoryProvider);
                  if (existing == null) {
                    await repo.createCategory(name: name);
                  } else {
                    await repo.updateCategory(
                      existing.id,
                      name: name,
                      isActive: isActive,
                    );
                  }
                  ref.invalidate(categoriesProvider);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(AppException.from(e).messageAr)),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider());

    return Scaffold(
      appBar: AppBar(title: const Text('الأقسام')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل الأقسام',
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyView(
              message: 'لا توجد أقسام بعد',
              icon: Icons.category_outlined,
            );
          }
          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = categories[i];
              return ListTile(
                title: Text(c.name),
                subtitle: c.isActive ? null : const Text('معطَّل'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _showCategoryDialog(context, ref, existing: c),
              );
            },
          );
        },
      ),
    );
  }
}
