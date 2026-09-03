import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../inventory/data/models/warehouse_stock_item.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../providers/sales_providers.dart';

class _SaleLine {
  final String productId;
  final String productName;
  final double sellingPrice;
  final int available;
  int quantity;
  _SaleLine({
    required this.productId,
    required this.productName,
    required this.sellingPrice,
    required this.available,
    required this.quantity,
  });

  double get lineTotal => quantity * sellingPrice;
}

/// Counter sale for a walk-in customer who came to the gallery in person and
/// has no app account — reachable from the admin home dashboard. Same shape
/// as TechnicianSaleScreen (bag sale) but sells from the main warehouse and
/// always takes payment in full (no credit tracking for walk-ins).
class AdminWalkInSaleScreen extends ConsumerStatefulWidget {
  const AdminWalkInSaleScreen({super.key});

  @override
  ConsumerState<AdminWalkInSaleScreen> createState() => _AdminWalkInSaleScreenState();
}

class _AdminWalkInSaleScreenState extends ConsumerState<AdminWalkInSaleScreen> {
  final String _clientRequestId = const Uuid().v4();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  final List<_SaleLine> _lines = [];
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _submitting = false;

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _lines.fold<double>(0, (sum, l) => sum + l.lineTotal);
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total => _subtotal - _discount;

  Future<void> _addLine(List<WarehouseStockItem> stock) async {
    final available = stock.where((s) => s.quantity > 0 && !_lines.any((l) => l.productId == s.productId));
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد منتجات متاحة بالمخزن')));
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
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('${s.productName} (متاح: ${s.quantity})', overflow: TextOverflow.ellipsis),
                        ))
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
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('إضافة')),
          ],
        ),
      ),
    );
    if (added != true) return;
    final qty = int.tryParse(qtyCtrl.text) ?? 0;
    if (qty <= 0 || qty > selected.quantity) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كمية غير صحيحة')));
      }
      return;
    }
    setState(() {
      _lines.add(_SaleLine(
        productId: selected.productId,
        productName: selected.productName,
        sellingPrice: selected.sellingPrice,
        available: selected.quantity,
        quantity: qty,
      ));
    });
  }

  Future<void> _submit() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف منتجًا واحدًا على الأقل')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(salesRepositoryProvider).recordWalkInSale(
            customerName: _customerNameCtrl.text.trim().isEmpty ? null : _customerNameCtrl.text.trim(),
            customerPhone: _customerPhoneCtrl.text.trim().isEmpty ? null : _customerPhoneCtrl.text.trim(),
            items: _lines.map((l) => (productId: l.productId, quantity: l.quantity)).toList(),
            paymentMethod: _paymentMethod,
            discount: _discount,
            clientRequestId: _clientRequestId,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      ref.invalidate(warehouseStockProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل البيع بنجاح')));
        Navigator.of(context).pop(true);
      }
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
    final stockAsync = ref.watch(warehouseStockProvider());

    return Scaffold(
      appBar: AppBar(title: const Text('بيع مباشر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الأصناف', style: Theme.of(context).textTheme.titleMedium),
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
          if (_lines.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('لم تُضف منتجات بعد')),
          for (final line in _lines)
            ListTile(
              title: Text(line.productName),
              subtitle: Text('${line.quantity} × ${Formatters.currency(line.sellingPrice)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(Formatters.currency(line.lineTotal)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _lines.remove(line)),
                  ),
                ],
              ),
            ),
          const Divider(height: 32),
          Text('بيانات العميل (اختياري)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _customerNameCtrl,
            decoration: const InputDecoration(labelText: 'اسم العميل'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customerPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'رقم الهاتف'),
          ),
          const Divider(height: 32),
          DropdownButtonFormField<PaymentMethod>(
            initialValue: _paymentMethod,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'طريقة الدفع'),
            items: const [PaymentMethod.cash, PaymentMethod.card, PaymentMethod.transfer]
                .map((m) => DropdownMenuItem(value: m, child: Text(paymentMethodLabelAr(m))))
                .toList(),
            onChanged: (m) => setState(() => _paymentMethod = m!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _discountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'الخصم'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي المطلوب', style: Theme.of(context).textTheme.titleMedium),
              Text(Formatters.currency(_total), style: Theme.of(context).textTheme.titleMedium),
            ],
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
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('تأكيد البيع'),
          ),
        ],
      ),
    );
  }
}
