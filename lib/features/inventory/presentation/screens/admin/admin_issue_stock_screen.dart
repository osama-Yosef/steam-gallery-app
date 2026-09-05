import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../maintenance/presentation/providers/maintenance_providers.dart';
import '../../../data/models/warehouse_stock_item.dart';
import '../../providers/inventory_providers.dart';

class _IssueLine {
  final String productId;
  final String productName;
  final String sku;
  final int available;
  int quantity;
  _IssueLine({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.available,
    required this.quantity,
  });
}

class AdminIssueStockScreen extends ConsumerStatefulWidget {
  const AdminIssueStockScreen({super.key});

  @override
  ConsumerState<AdminIssueStockScreen> createState() =>
      _AdminIssueStockScreenState();
}

class _AdminIssueStockScreenState extends ConsumerState<AdminIssueStockScreen> {
  final _notesCtrl = TextEditingController();
  String? _technicianId;
  final List<_IssueLine> _lines = [];
  bool _submitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _addLine(List<WarehouseStockItem> stock) async {
    final available = stock.where(
      (s) => s.quantity > 0 && !_lines.any((l) => l.productId == s.productId),
    );
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد منتجات متاحة بالمخزن')),
      );
      return;
    }
    WarehouseStockItem selected = available.first;
    final qtyCtrl = TextEditingController(text: '1');
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة منتج'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<WarehouseStockItem>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'المنتج'),
                items: available
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          '${s.productName} (متاح: ${s.quantity})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (s) => setDialogState(() => selected = s!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الكمية'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
    if (added != true) return;
    final qty = int.tryParse(qtyCtrl.text) ?? 0;
    if (qty <= 0 || qty > selected.quantity) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('كمية غير صحيحة')));
      }
      return;
    }
    setState(() {
      _lines.add(
        _IssueLine(
          productId: selected.productId,
          productName: selected.productName,
          sku: selected.sku,
          available: selected.quantity,
          quantity: qty,
        ),
      );
    });
  }

  Future<void> _submit() async {
    if (_technicianId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اختر الصنايعي أولًا')));
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف منتجًا واحدًا على الأقل')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(inventoryRepositoryProvider)
          .issueStock(
            technicianId: _technicianId!,
            items: _lines
                .map((l) => (productId: l.productId, quantity: l.quantity))
                .toList(),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
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
    final techniciansAsync = ref.watch(assignableTechniciansProvider);
    final stockAsync = ref.watch(warehouseStockProvider());

    return Scaffold(
      appBar: AppBar(title: const Text('صرف لصنايعي')),
      body: techniciansAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الصنايعية'),
        data: (technicians) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _technicianId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'الصنايعي'),
              items: technicians
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        '${t.fullName} (${t.employeeCode})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _technicianId = v),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المنتجات',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                stockAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (stock) => TextButton.icon(
                    onPressed: () => _addLine(stock),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة'),
                  ),
                ),
              ],
            ),
            if (_lines.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('لم تُضف منتجات بعد'),
              ),
            for (final line in _lines)
              ListTile(
                title: Text(line.productName),
                subtitle: Text('SKU: ${line.sku} · الكمية: ${line.quantity}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _lines.remove(line)),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              maxLines: 2,
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
                  : const Icon(Icons.check),
              label: const Text('تأكيد الصرف'),
            ),
          ],
        ),
      ),
    );
  }
}
