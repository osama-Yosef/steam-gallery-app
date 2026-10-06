import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/offline/offline_widgets.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../cashbox/data/models/cashbox_balance.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../../products/data/models/product.dart';
import '../../../../products/presentation/providers/product_providers.dart';
import '../../../data/models/purchase_models.dart';
import '../../providers/purchases_providers.dart';

final _moneyFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'^\d*\.?\d*'),
);

/// How the invoice is settled at entry time.
enum _PayMode { cash, partial, deferred }

/// "فاتورة شراء" — replaces the old one-product "استلام بضاعة" form: a
/// supplier, any number of lines, a discount, and how it was paid (in full,
/// partly, or آجل) out of the cash or transfer till. Whatever isn't paid
/// stays on the supplier's balance.
class AdminPurchaseInvoiceFormScreen extends ConsumerStatefulWidget {
  const AdminPurchaseInvoiceFormScreen({super.key});

  @override
  ConsumerState<AdminPurchaseInvoiceFormScreen> createState() =>
      _AdminPurchaseInvoiceFormScreenState();
}

class _AdminPurchaseInvoiceFormScreenState
    extends ConsumerState<AdminPurchaseInvoiceFormScreen> {
  final String _requestId = const Uuid().v4();
  final _supplierCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _paidCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<PurchaseLineInput> _lines = [];
  SupplierBalance? _supplier;
  DateTime _date = DateTime.now();
  _PayMode _payMode = _PayMode.cash;
  CashboxKind _kind = CashboxKind.cash;
  bool _submitting = false;

  @override
  void dispose() {
    _supplierCtrl.dispose();
    _phoneCtrl.dispose();
    _refCtrl.dispose();
    _discountCtrl.dispose();
    _paidCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _lines.fold<double>(0, (s, l) => s + l.lineTotal);
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total => _subtotal - _discount;
  double get _paid => switch (_payMode) {
    _PayMode.cash => _total,
    _PayMode.deferred => 0,
    _PayMode.partial => double.tryParse(_paidCtrl.text) ?? 0,
  };

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickSupplier() async {
    final suppliers = await ref.read(suppliersProvider.future);
    if (!mounted) return;
    if (suppliers.isEmpty) {
      _snack('لا يوجد موردين بعد — اكتب اسم المورد الجديد');
      return;
    }
    final picked = await showSearchPickerSheet<SupplierBalance>(
      context,
      title: 'اختر المورد',
      items: suppliers,
      label: (s) => s.name,
      subtitle: (s) =>
          '${s.phone ?? ''}${s.balance > 0 ? '  ·  مستحق له ${Formatters.currency(s.balance)}' : ''}',
    );
    if (picked == null) return;
    setState(() {
      _supplier = picked;
      _supplierCtrl.text = picked.name;
      _phoneCtrl.text = picked.phone ?? '';
    });
  }

  Future<void> _addLine([int? editIndex]) async {
    Product? product;
    if (editIndex == null) {
      final products = await ref.read(adminProductsProvider().future);
      if (!mounted) return;
      final stockProducts =
          products
              .where((p) => p.isActive && !p.isService && !p.isAssembly)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      product = await showSearchPickerSheet<Product>(
        context,
        title: 'اختر الصنف',
        items: stockProducts,
        label: (p) => p.name,
        subtitle: (p) =>
            '${p.sku}  ·  آخر تكلفة ${Formatters.currency(p.costPrice)}',
        searchText: (p) => '${p.name} ${p.sku} ${p.barcode ?? ''}',
      );
      if (product == null || !mounted) return;
    }
    final existing = editIndex == null ? null : _lines[editIndex];
    final qtyCtrl = TextEditingController(
      text: existing?.quantity.toString() ?? '1',
    );
    final costCtrl = TextEditingController(
      text: (existing?.unitCost ?? product!.costPrice).toStringAsFixed(2),
    );
    final name = existing?.productName ?? product!.name;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'الكمية'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_moneyFormatter],
              decoration: const InputDecoration(labelText: 'سعر الشراء للوحدة'),
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
            child: Text(existing == null ? 'إضافة' : 'حفظ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final qty = int.tryParse(qtyCtrl.text) ?? 0;
    final cost = double.tryParse(costCtrl.text);
    if (qty <= 0 || cost == null || cost < 0) {
      _snack('أدخل كمية وسعر صحيحين');
      return;
    }
    final line = PurchaseLineInput(
      productId: existing?.productId ?? product!.id,
      productName: name,
      quantity: qty,
      unitCost: double.parse(cost.toStringAsFixed(2)),
    );
    setState(() {
      if (editIndex != null) {
        _lines[editIndex] = line;
      } else {
        // Same product at the same cost again just adds up.
        final same = _lines.indexWhere(
          (l) => l.productId == line.productId && l.unitCost == line.unitCost,
        );
        if (same >= 0) {
          _lines[same] = PurchaseLineInput(
            productId: line.productId,
            productName: line.productName,
            quantity: _lines[same].quantity + line.quantity,
            unitCost: line.unitCost,
          );
        } else {
          _lines.add(line);
        }
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final supplierName = _supplierCtrl.text.trim();
    if (_supplier == null && supplierName.isEmpty) {
      _snack('اختر المورد أو اكتب اسمه');
      return;
    }
    if (_lines.isEmpty) {
      _snack('أضف صنفًا واحدًا على الأقل');
      return;
    }
    if (_discount < 0 || _discount > _subtotal) {
      _snack('قيمة الخصم غير صحيحة');
      return;
    }
    final paid = double.parse(_paid.toStringAsFixed(2));
    if (paid < 0 || paid > _total + 0.001) {
      _snack('المدفوع لازم يكون بين صفر وإجمالي الفاتورة');
      return;
    }

    setState(() => _submitting = true);
    try {
      // A typed name that differs from the picked supplier means a new one.
      final useExisting = _supplier != null && _supplier!.name == supplierName;
      final result = await ref
          .read(purchasesRepositoryProvider)
          .createInvoice(
            supplierId: useExisting ? _supplier!.id : null,
            supplierName: supplierName,
            supplierPhone: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            items: _lines,
            discount: _discount,
            paidAmount: paid,
            paymentKind: paid > 0 ? _kind : null,
            invoiceDate: _date,
            supplierInvoiceRef: _refCtrl.text.trim().isEmpty
                ? null
                : _refCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            clientRequestId: _requestId,
          );
      ref.invalidate(purchaseInvoicesProvider);
      ref.invalidate(suppliersProvider);
      ref.invalidate(warehouseStockProvider);
      ref.invalidate(adminProductsProvider);
      if (!mounted) return;
      if (result.queued) {
        showSavedOfflineSnack(context, 'فاتورة الشراء اتسجلت');
      } else {
        _snack('تم تسجيل فاتورة الشراء وإضافة البضاعة للمخزن');
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _snack(AppException.from(e).messageAr);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('فاتورة شراء جديدة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'المورد',
            child: Column(
              children: [
                TextField(
                  controller: _supplierCtrl,
                  decoration: InputDecoration(
                    labelText: 'اسم المورد / التاجر',
                    suffixIcon: IconButton(
                      tooltip: 'اختيار مورد مسجَّل',
                      icon: const Icon(Iconsax.profile_2user_copy),
                      onPressed: _pickSupplier,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'تليفون المورد (اختياري)',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _refCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم فاتورة المورد (اختياري)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                          );
                          if (d != null) setState(() => _date = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'تاريخ الفاتورة',
                          ),
                          child: Text(Formatters.date(_date)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'الأصناف',
            trailing: TextButton.icon(
              onPressed: () => _addLine(),
              icon: const Icon(Iconsax.add_copy),
              label: const Text('إضافة صنف'),
            ),
            child: _lines.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('لم تتم إضافة أصناف بعد')),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < _lines.length; i++)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_lines[i].productName),
                          subtitle: Text(
                            '${_lines[i].quantity} × ${Formatters.currency(_lines[i].unitCost)}',
                          ),
                          onTap: () => _addLine(i),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(Formatters.currency(_lines[i].lineTotal)),
                              IconButton(
                                icon: const Icon(Iconsax.trash_copy),
                                onPressed: () =>
                                    setState(() => _lines.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'الحساب',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TotalRow('الإجمالي قبل الخصم', _subtotal),
                const SizedBox(height: 8),
                TextField(
                  controller: _discountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [_moneyFormatter],
                  decoration: const InputDecoration(labelText: 'الخصم'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                _TotalRow('صافي الفاتورة', _total, bold: true),
                const SizedBox(height: 16),
                Text('طريقة الدفع', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<_PayMode>(
                  segments: const [
                    ButtonSegment(value: _PayMode.cash, label: Text('نقدي')),
                    ButtonSegment(
                      value: _PayMode.partial,
                      label: Text('جزء والباقي آجل'),
                    ),
                    ButtonSegment(value: _PayMode.deferred, label: Text('آجل')),
                  ],
                  selected: {_payMode},
                  onSelectionChanged: (s) => setState(() => _payMode = s.first),
                ),
                if (_payMode != _PayMode.deferred) ...[
                  const SizedBox(height: 12),
                  SegmentedButton<CashboxKind>(
                    segments: const [
                      ButtonSegment(
                        value: CashboxKind.cash,
                        icon: Icon(Iconsax.money_copy),
                        label: Text('كاش'),
                      ),
                      ButtonSegment(
                        value: CashboxKind.transfer,
                        icon: Icon(Iconsax.card_copy),
                        label: Text('تحويل'),
                      ),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() => _kind = s.first),
                  ),
                ],
                if (_payMode == _PayMode.partial) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _paidCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_moneyFormatter],
                    decoration: const InputDecoration(
                      labelText: 'المبلغ المدفوع الآن',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 12),
                _TotalRow('المدفوع', _paid),
                _TotalRow('المتبقي على الحساب (آجل)', _total - _paid),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconsax.receipt_add_copy),
            label: Text('حفظ الفاتورة · ${Formatters.currency(_total)}'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;
  const _TotalRow(this.label, this.amount, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(Formatters.currency(amount), style: style),
        ],
      ),
    );
  }
}
