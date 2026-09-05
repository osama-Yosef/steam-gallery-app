import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/inventory_count.dart';
import '../../providers/inventory_count_providers.dart';

class AdminInventoryCountsListScreen extends ConsumerStatefulWidget {
  const AdminInventoryCountsListScreen({super.key});

  @override
  ConsumerState<AdminInventoryCountsListScreen> createState() =>
      _AdminInventoryCountsListScreenState();
}

class _AdminInventoryCountsListScreenState
    extends ConsumerState<AdminInventoryCountsListScreen> {
  bool _starting = false;

  Future<void> _startNewCount() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'بدء جرد جديد',
      message:
          'سيتم تسجيل الكميات الحالية للمخزن الرئيسي كأساس للجرد. هل تريد المتابعة؟',
    );
    if (!confirmed) return;
    setState(() => _starting = true);
    try {
      final countId = await ref
          .read(inventoryCountRepositoryProvider)
          .startWarehouseCount();
      if (mounted) {
        await context.push(Routes.adminInventoryCountDetail(countId));
        ref.invalidate(inventoryCountsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final countsAsync = ref.watch(inventoryCountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الجرد')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _starting ? null : _startNewCount,
        icon: _starting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.checklist_outlined),
        label: const Text('بدء جرد جديد'),
      ),
      body: countsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل عمليات الجرد',
          onRetry: () => ref.invalidate(inventoryCountsProvider),
        ),
        data: (counts) {
          if (counts.isEmpty) {
            return const EmptyView(
              message: 'لا توجد عمليات جرد بعد',
              icon: Icons.checklist_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: counts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = counts[i];
              return ListTile(
                leading: CircleAvatar(child: Text('#${c.countNumber}')),
                title: const Text('جرد المخزن الرئيسي'),
                subtitle: Text(
                  '${inventoryCountStatusLabelAr(c.status)} · ${Formatters.dateTime(c.startedAt)}',
                ),
                trailing: c.status == InventoryCountStatus.draft
                    ? const Icon(Icons.edit_note_outlined)
                    : const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                onTap: () async {
                  await context.push(Routes.adminInventoryCountDetail(c.id));
                  ref.invalidate(inventoryCountsProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}
