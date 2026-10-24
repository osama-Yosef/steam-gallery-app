import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../data/models/inventory_count_item.dart';
import '../../providers/inventory_count_providers.dart';

/// One count — the warehouse's or a technician's bag (0089).
///
/// Admin/sales enter quantities and approve. With [technicianView] it is the
/// technician's own bag count: he enters quantities and sends it for review,
/// and can't change it after that.
class AdminInventoryCountDetailScreen extends ConsumerStatefulWidget {
  final String countId;
  final bool technicianView;
  const AdminInventoryCountDetailScreen({
    super.key,
    required this.countId,
    this.technicianView = false,
  });

  @override
  ConsumerState<AdminInventoryCountDetailScreen> createState() =>
      _AdminInventoryCountDetailScreenState();
}

class _AdminInventoryCountDetailScreenState
    extends ConsumerState<AdminInventoryCountDetailScreen> {
  bool _busy = false;

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
  }

  Future<void> _editItem(InventoryCountItem item) async {
    final qtyCtrl = TextEditingController(
      text: (item.actualQuantity ?? item.systemQuantity).toString(),
    );
    final reasonCtrl = TextEditingController(text: item.reason ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final qty = int.tryParse(qtyCtrl.text) ?? item.systemQuantity;
          final diff = qty - item.systemQuantity;
          return AlertDialog(
            title: Text(item.productName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('الكمية بالنظام: ${item.systemQuantity}'),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'الكمية الفعلية',
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (diff != 0) ...[
                  const SizedBox(height: 12),
                  _DiffChip(diff),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    decoration: InputDecoration(
                      labelText: diff < 0
                          ? 'سبب العجز (مطلوب)'
                          : 'سبب الزيادة (مطلوب)',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: diff != 0 && reasonCtrl.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(ctx).pop(true),
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
      await ref
          .read(inventoryCountRepositoryProvider)
          .saveItem(
            itemId: item.id,
            actualQuantity: qty,
            // A matching count needs no reason; don't keep a stale one.
            reason: qty == item.systemQuantity || reasonCtrl.text.trim().isEmpty
                ? null
                : reasonCtrl.text.trim(),
          );
      ref.invalidate(inventoryCountItemsProvider(widget.countId));
    } catch (e) {
      _showError(e);
    }
  }

  /// A product found that the count has no line for — a surplus.
  Future<void> _addProduct(List<InventoryCountItem> items) async {
    final repo = ref.read(inventoryCountRepositoryProvider);
    final List<({String id, String name, String sku})> products;
    try {
      products = await repo.getCountableProducts();
    } catch (e) {
      _showError(e);
      return;
    }
    if (!mounted) return;
    final have = {for (final i in items) i.productId};
    final choices = products.where((p) => !have.contains(p.id)).toList();
    final picked = await showDialog<({String id, String name, String sku})>(
      context: context,
      builder: (_) => _ProductPickerDialog(products: choices),
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final itemId = await repo.addItem(
        countId: widget.countId,
        productId: picked.id,
      );
      ref.invalidate(inventoryCountItemsProvider(widget.countId));
      final fresh = await ref.read(
        inventoryCountItemsProvider(widget.countId).future,
      );
      final line = fresh.where((i) => i.id == itemId).firstOrNull;
      if (line != null && mounted) await _editItem(line);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'إرسال الجرد',
      message:
          'هيتبعت الجرد للأدمن أو المبيعات يراجعوه ويعتمدوه، ومش هتقدر تعدّل فيه بعد كده. تكمل؟',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await ref.read(inventoryCountRepositoryProvider).submitCount(widget.countId);
      ref.invalidate(inventoryCountDetailProvider(widget.countId));
      ref.invalidate(inventoryCountsProvider);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
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
    setState(() => _busy = true);
    try {
      await ref
          .read(inventoryCountRepositoryProvider)
          .completeCount(widget.countId);
      ref.invalidate(inventoryCountDetailProvider(widget.countId));
      ref.invalidate(inventoryCountItemsProvider(widget.countId));
      ref.invalidate(inventoryCountsProvider);
      // Approving a count adjusts real quantities — don't leave the
      // warehouse or bag screens showing stale figures.
      ref.invalidate(warehouseStockProvider);
      ref.invalidate(technicianBagStockProvider);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _busyIcon(IconData icon) => _busy
      ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Icon(icon);

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(inventoryCountDetailProvider(widget.countId));
    final itemsAsync = ref.watch(inventoryCountItemsProvider(widget.countId));

    return Scaffold(
      appBar: AppBar(
        title: Text(countAsync.value?.title ?? 'تفاصيل الجرد'),
      ),
      body: countAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الجرد'),
        data: (count) {
          if (count == null) return const EmptyView(message: 'الجرد غير موجود');
          final editable =
              count.isDraft &&
              !(widget.technicianView && count.submittedAt != null);
          return itemsAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: 'تعذَّر تحميل الأصناف',
              onRetry: () =>
                  ref.invalidate(inventoryCountItemsProvider(widget.countId)),
            ),
            data: (items) {
              final shortages = items.where((i) => i.difference < 0).length;
              final surpluses = items.where((i) => i.difference > 0).length;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Chip(label: Text(count.statusLabelAr)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${items.where((i) => i.isCounted).length} / ${items.length} مُدخَل'
                            '${shortages > 0 ? ' · عجز: $shortages' : ''}'
                            '${surpluses > 0 ? ' · زيادة: $surpluses' : ''}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (count.awaitsApproval)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.technicianView
                            ? 'اتبعت للمراجعة — الشنطة هتتعدل بعد ما الأدمن أو المبيعات يعتمدوه'
                            : 'الصنايعي بعت الجرد — راجعه واعتمده',
                        style: TextStyle(color: AppColors.warning),
                      ),
                    ),
                  if (editable)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextButton.icon(
                          onPressed: _busy ? null : () => _addProduct(items),
                          icon: const Icon(Iconsax.add_square_copy),
                          label: const Text('إضافة صنف مش في القائمة'),
                        ),
                      ),
                    ),
                  Expanded(
                    child: items.isEmpty
                        ? const EmptyView(message: 'لا توجد أصناف في هذا الجرد')
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) => _ItemTile(
                              item: items[i],
                              onTap: editable
                                  ? () => _editItem(items[i])
                                  : null,
                            ),
                          ),
                  ),
                  if (widget.technicianView && editable)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _submit,
                        icon: _busyIcon(Iconsax.send_2_copy),
                        label: const Text('إرسال للمراجعة'),
                      ),
                    )
                  else if (!widget.technicianView && count.isDraft)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton.icon(
                        onPressed: _busy ? null : () => _complete(items),
                        icon: _busyIcon(Iconsax.tick_circle_copy),
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

class _ItemTile extends StatelessWidget {
  final InventoryCountItem item;
  final VoidCallback? onTap;
  const _ItemTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.productName),
      subtitle: Text(
        'SKU: ${item.sku} · بالنظام: ${item.systemQuantity}'
        '${item.reason != null ? ' · السبب: ${item.reason}' : ''}',
      ),
      trailing: item.isCounted
          ? Text(
              item.hasDifference
                  ? '${item.actualQuantity} (${item.difference > 0 ? '+' : ''}${item.difference})'
                  : '${item.actualQuantity}',
              style: TextStyle(
                color: item.difference < 0
                    ? Theme.of(context).colorScheme.error
                    : item.difference > 0
                    ? AppColors.warning
                    : Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            )
          : const Icon(Iconsax.square_copy),
      onTap: onTap,
    );
  }
}

class _DiffChip extends StatelessWidget {
  final int diff;
  const _DiffChip(this.diff);

  @override
  Widget build(BuildContext context) {
    final shortage = diff < 0;
    return Text(
      shortage ? 'عجز ${-diff}' : 'زيادة $diff',
      style: TextStyle(
        color: shortage
            ? Theme.of(context).colorScheme.error
            : AppColors.warning,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ProductPickerDialog extends StatefulWidget {
  final List<({String id, String name, String sku})> products;
  const _ProductPickerDialog({required this.products});

  @override
  State<_ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<_ProductPickerDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final q = _search.trim().toLowerCase();
    final shown = q.isEmpty
        ? widget.products
        : widget.products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(q) ||
                    p.sku.toLowerCase().contains(q),
              )
              .toList();
    return AlertDialog(
      title: const Text('اختار الصنف'),
      content: SizedBox(
        width: 400,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'بحث بالاسم أو الكود',
                prefixIcon: Icon(Iconsax.search_normal_copy),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: shown.isEmpty
                  ? const Center(child: Text('مفيش أصناف'))
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, i) => ListTile(
                        title: Text(shown[i].name),
                        subtitle: Text('SKU: ${shown[i].sku}'),
                        onTap: () => Navigator.of(context).pop(shown[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}
