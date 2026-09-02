import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../data/models/inventory_count.dart';
import '../../../data/models/inventory_count_item.dart';
import '../../providers/inventory_count_providers.dart';

class AdminInventoryCountDetailScreen extends ConsumerStatefulWidget {
  final String countId;
  const AdminInventoryCountDetailScreen({super.key, required this.countId});

  @override
  ConsumerState<AdminInventoryCountDetailScreen> createState() => _AdminInventoryCountDetailScreenState();
}

class _AdminInventoryCountDetailScreenState extends ConsumerState<AdminInventoryCountDetailScreen> {
  bool _completing = false;

  Future<void> _editItem(InventoryCountItem item) async {
    final qtyCtrl = TextEditingController(text: (item.actualQuantity ?? item.systemQuantity).toString());
    final reasonCtrl = TextEditingController(text: item.reason ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final qty = int.tryParse(qtyCtrl.text) ?? item.systemQuantity;
          final differs = qty != item.systemQuantity;
          return AlertDialog(
            title: Text(item.productName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('الكمية بالنظام: ${item.systemQuantity}'),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية الفعلية'),
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (differs) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(labelText: 'سبب الفرق (مطلوب)'),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
              FilledButton(
                onPressed: () {
                  if (differs && reasonCtrl.text.trim().isEmpty) return;
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
    if (saved != true) return;
    final qty = int.tryParse(qtyCtrl.text);
    if (qty == null || qty < 0) return;
    try {
      await ref.read(inventoryCountRepositoryProvider).saveItem(
            itemId: item.id,
            actualQuantity: qty,
            reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
          );
      ref.invalidate(inventoryCountItemsProvider(widget.countId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  Future<void> _complete(List<InventoryCountItem> items) async {
    final uncounted = items.where((i) => !i.isCounted).length;
    final confirmed = await showConfirmDialog(
      context,
      title: 'اعتماد الجرد',
      message: uncounted > 0
          ? 'يوجد $uncounted صنف لم تُدخَل له كمية فعلية (سيُعتبر مطابقًا للنظام). هل تريد الاعتماد؟'
          : 'سيتم تحديث المخزون الفعلي بناءً على الكميات المدخلة. هل تريد المتابعة؟',
    );
    if (!confirmed) return;
    setState(() => _completing = true);
    try {
      await ref.read(inventoryCountRepositoryProvider).completeCount(widget.countId);
      ref.invalidate(inventoryCountDetailProvider(widget.countId));
      ref.invalidate(inventoryCountItemsProvider(widget.countId));
      // Approving a count can adjust real warehouse quantities — make sure
      // the warehouse screen doesn't show stale figures if the admin goes
      // back there next.
      ref.invalidate(warehouseStockProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(inventoryCountDetailProvider(widget.countId));
    final itemsAsync = ref.watch(inventoryCountItemsProvider(widget.countId));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الجرد')),
      body: countAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الجرد'),
        data: (count) {
          if (count == null) return const EmptyView(message: 'الجرد غير موجود');
          final isDraft = count.status == InventoryCountStatus.draft;
          return itemsAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: 'تعذَّر تحميل الأصناف',
              onRetry: () => ref.invalidate(inventoryCountItemsProvider(widget.countId)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyView(message: 'لا توجد أصناف في هذا الجرد');
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(label: Text(inventoryCountStatusLabelAr(count.status))),
                        Text('${items.where((i) => i.isCounted).length} / ${items.length} مُدخَل'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.only(bottom: isDraft ? 88 : 16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return ListTile(
                          title: Text(item.productName),
                          subtitle: Text('SKU: ${item.sku} · بالنظام: ${item.systemQuantity}'
                              '${item.reason != null ? ' · السبب: ${item.reason}' : ''}'),
                          trailing: item.isCounted
                              ? Text(
                                  item.hasDifference
                                      ? '${item.actualQuantity} (${item.difference > 0 ? '+' : ''}${item.difference})'
                                      : '${item.actualQuantity}',
                                  style: TextStyle(
                                    color: item.hasDifference
                                        ? Theme.of(context).colorScheme.error
                                        : Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const Icon(Icons.radio_button_unchecked),
                          onTap: isDraft ? () => _editItem(item) : null,
                        );
                      },
                    ),
                  ),
                  if (isDraft)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton.icon(
                        onPressed: _completing ? null : () => _complete(items),
                        icon: _completing
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline),
                        label: const Text('اعتماد الجرد'),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
