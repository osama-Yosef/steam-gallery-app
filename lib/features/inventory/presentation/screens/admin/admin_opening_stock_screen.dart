import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/input_formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../products/data/models/product.dart';
import '../../../../products/presentation/providers/product_providers.dart';
import '../../providers/inventory_providers.dart';

class _OpeningLine {
  final String productId;
  final String productName;
  final String sku;
  int quantity;
  double unitCost;
  _OpeningLine({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitCost,
  });
}

/// رصيد افتتاحي — what the warehouse already holds on the day the app goes
/// live, entered once per product with its cost. Adds to whatever stock is
/// already recorded; no supplier, no till (0080).
class AdminOpeningStockScreen extends ConsumerStatefulWidget {
  const AdminOpeningStockScreen({super.key});

  @override
  ConsumerState<AdminOpeningStockScreen> createState() =>
      _AdminOpeningStockScreenState();
}

class _AdminOpeningStockScreenState
    extends ConsumerState<AdminOpeningStockScreen> {
  final _notesCtrl = TextEditingController();
  final List<_OpeningLine> _lines = [];
  bool _submitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _total => _lines.fold(0, (s, l) => s + l.quantity * l.unitCost);

  Future<void> _addLine() async {
    final products = await ref.read(adminProductsProvider().future);
    if (!mounted) return;
    final stockProducts =
        products
            .where(
              (p) =>
                  p.isActive &&
                  !p.isService &&
                  !p.isAssembly &&
                  !_lines.any((l) => l.productId == p.id),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final product = await showSearchPickerSheet<Product>(
      context,
      title: 'اختر الصنف',
      items: stockProducts,
      label: (p) => p.name,
      subtitle: (p) =>
          '${p.sku}  ·  التكلفة ${Formatters.currency(p.costPrice)}',
      searchText: (p) => '${p.name} ${p.sku} ${p.barcode ?? ''}',
    );
    if (product == null || !mounted) return;
    final line = _OpeningLine(
      productId: product.id,
      productName: product.name,
      sku: product.sku,
      quantity: 1,
      unitCost: product.costPrice,
    );
    if (await _editLine(line)) setState(() => _lines.add(line));
  }

  /// Quantity and cost for [line]; false if cancelled or invalid.
  Future<bool> _editLine(_OpeningLine line) async {
    final qtyCtrl = TextEditingController(text: line.quantity.toString());
    final costCtrl = TextEditingController(
      text: line.unitCost.toStringAsFixed(2),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(line.productName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'الكمية الموجودة'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [moneyInputFormatter],
              decoration: const InputDecoration(labelText: 'تكلفة القطعة'),
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
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    final qty = int.tryParse(qtyCtrl.text) ?? 0;
    final cost = double.tryParse(costCtrl.text);
    qtyCtrl.dispose();
    costCtrl.dispose();
    if (ok != true) return false;
    if (qty <= 0 || cost == null || cost < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الكمية أو التكلفة غير صحيحة')),
        );
      }
      return false;
    }
    line
      ..quantity = qty
      ..unitCost = cost;
    return true;
  }

  Future<void> _submit() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف صنفًا واحدًا على الأقل')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final notes = _notesCtrl.text.trim();
      await ref
          .read(inventoryRepositoryProvider)
          .addOpeningStock(
            items: [
              for (final l in _lines)
                (
                  productId: l.productId,
                  quantity: l.quantity,
                  unitCost: l.unitCost,
                ),
            ],
            notes: notes.isEmpty ? null : notes,
          );
      ref.invalidate(adminProductsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الرصيد الافتتاحي')),
        );
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('رصيد افتتاحي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'سجّل الكميات اللي موجودة فعلًا في المخزن قبل بداية الشغل على '
            'البرنامج. بتتضاف على الرصيد الحالي، ومن غير مورد ولا خزنة.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('الأصناف', style: theme.textTheme.titleMedium),
              ),
              TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Iconsax.add_square_copy),
                label: const Text('إضافة صنف'),
              ),
            ],
          ),
          if (_lines.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('لم تُضف أصناف بعد'),
            ),
          for (final line in _lines)
            Card(
              child: ListTile(
                title: Text(line.productName),
                subtitle: Text(
                  '${line.sku} · ${line.quantity} × ${Formatters.currency(line.unitCost)}',
                ),
                onTap: () async {
                  if (await _editLine(line)) setState(() {});
                },
                trailing: IconButton(
                  icon: const Icon(Iconsax.trash_copy),
                  tooltip: 'حذف',
                  onPressed: () => setState(() => _lines.remove(line)),
                ),
              ),
            ),
          if (_lines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('قيمة الرصيد (تكلفة): '),
                  MoneyText(_total, style: theme.textTheme.titleSmall),
                ],
              ),
            ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'ملاحظات (اختياري)',
              hintText: 'رصيد افتتاحي',
            ),
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
            label: const Text('حفظ الرصيد الافتتاحي'),
          ),
        ],
      ),
    );
  }
}
