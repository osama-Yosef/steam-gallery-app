import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../inventory/data/models/technician_bag_stock_item.dart';
import '../../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../../products/data/models/product.dart';
import '../../../../products/presentation/providers/product_providers.dart';
import '../../../../sales/data/models/sale_line_input.dart';
import '../../../data/models/sale.dart';
import '../../providers/technician_account_providers.dart';

class _SaleLine {
  final String productId;
  final String productName;

  /// For a service this is the price agreed with the customer for THIS sale,
  /// not a catalogue price.
  final double sellingPrice;
  final int available;
  final bool isService;
  int quantity;
  _SaleLine({
    required this.productId,
    required this.productName,
    required this.sellingPrice,
    required this.available,
    required this.quantity,
    this.isService = false,
  });

  double get lineTotal => quantity * sellingPrice;

  /// Only a service carries an explicit price to the server; for a stock
  /// product the catalogue price is authoritative (see SaleLineInput).
  double? get unitPrice => isService ? sellingPrice : null;
}

class TechnicianSaleScreen extends ConsumerStatefulWidget {
  /// When set, this sale is the invoice for a finished maintenance job: it is
  /// linked to that request so the customer can see what was done and what it
  /// cost. Otherwise it's an ordinary sale out of the bag.
  final String? maintenanceRequestId;
  final String? customerName;
  final String? customerPhone;

  const TechnicianSaleScreen({
    super.key,
    this.maintenanceRequestId,
    this.customerName,
    this.customerPhone,
  });

  bool get isMaintenanceInvoice => maintenanceRequestId != null;

  @override
  ConsumerState<TechnicianSaleScreen> createState() =>
      _TechnicianSaleScreenState();
}

class _TechnicianSaleScreenState extends ConsumerState<TechnicianSaleScreen> {
  final String _clientRequestId = const Uuid().v4();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _paidAmountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<_SaleLine> _lines = [];
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Invoicing a job: the customer is already known from the request.
    _customerNameCtrl.text = widget.customerName ?? '';
    _customerPhoneCtrl.text = widget.customerPhone ?? '';
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _discountCtrl.dispose();
    _paidAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _lines.fold<double>(0, (sum, l) => sum + l.lineTotal);
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _total => _subtotal - _discount;

  Future<void> _addLine(List<TechnicianBagStockItem> bag) async {
    final available = bag.where(
      (s) => s.quantity > 0 && !_lines.any((l) => l.productId == s.productId),
    );
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد منتجات متاحة بالشنطة')),
      );
      return;
    }
    TechnicianBagStockItem selected = available.first;
    final qtyCtrl = TextEditingController(text: '1');
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة منتج'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<TechnicianBagStockItem>(
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
        _SaleLine(
          productId: selected.productId,
          productName: selected.productName,
          sellingPrice: selected.sellingPrice,
          available: selected.quantity,
          quantity: qty,
        ),
      );
    });
  }

  /// Adds a labour line. Unlike a stock product the price isn't in the
  /// catalogue — it's agreed per job — so it's typed here and sent explicitly.
  Future<void> _addServiceLine() async {
    final services = await ref.read(serviceProductsProvider.future);
    if (!mounted) return;
    if (services.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد خدمات معرَّفة')));
      return;
    }
    Product selected = services.first;
    final priceCtrl = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة خدمة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Product>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'الخدمة'),
                items: services
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (s) => setDialogState(() => selected = s!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'سعر الخدمة'),
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
    final price = double.tryParse(priceCtrl.text) ?? 0;
    if (price <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('أدخل سعرًا صحيحًا')));
      }
      return;
    }
    setState(() {
      _lines.add(
        _SaleLine(
          productId: selected.id,
          productName: selected.name,
          sellingPrice: price,
          available: 1,
          quantity: 1,
          isService: true,
        ),
      );
    });
  }

  Future<void> _submit(String technicianId) async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف منتجًا واحدًا على الأقل')),
      );
      return;
    }
    final paidAmount = double.tryParse(_paidAmountCtrl.text) ?? 0;
    setState(() => _submitting = true);
    try {
      await ref
          .read(technicianAccountRepositoryProvider)
          .recordSale(
            technicianId: technicianId,
            customerName: _customerNameCtrl.text.trim().isEmpty
                ? null
                : _customerNameCtrl.text.trim(),
            customerPhone: _customerPhoneCtrl.text.trim().isEmpty
                ? null
                : _customerPhoneCtrl.text.trim(),
            items: _lines
                .map(
                  (l) => SaleLineInput(
                    productId: l.productId,
                    quantity: l.quantity,
                    unitPrice: l.unitPrice,
                  ),
                )
                .toList(),
            paymentMethod: _paymentMethod,
            discount: _discount,
            paidAmount: paidAmount,
            clientRequestId: _clientRequestId,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            maintenanceRequestId: widget.maintenanceRequestId,
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
    final technicianId = ref.watch(currentUserProfileProvider).value?.id;
    if (technicianId == null) {
      return const Scaffold(body: LoadingView());
    }
    final bagAsync = ref.watch(technicianBagStockProvider(technicianId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isMaintenanceInvoice ? 'فاتورة الصيانة' : 'بيع من الشنطة',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الأصناف', style: Theme.of(context).textTheme.titleMedium),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _addServiceLine,
                    icon: const Icon(Icons.handyman_outlined),
                    label: const Text('خدمة'),
                  ),
                  bagAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (bag) => TextButton.icon(
                      onPressed: () => _addLine(bag),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة'),
                    ),
                  ),
                ],
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
              subtitle: Text(
                '${line.quantity} × ${Formatters.currency(line.sellingPrice)}',
              ),
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
          Text(
            'بيانات العميل (اختياري)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
            items:
                const [
                      PaymentMethod.cash,
                      PaymentMethod.card,
                      PaymentMethod.transfer,
                    ]
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(paymentMethodLabelAr(m)),
                      ),
                    )
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
              Text('الإجمالي', style: Theme.of(context).textTheme.titleMedium),
              Text(
                Formatters.currency(_total),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _paidAmountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'المبلغ المحصَّل',
              suffixIcon: TextButton(
                onPressed: () => setState(
                  () => _paidAmountCtrl.text = _total.toStringAsFixed(2),
                ),
                child: const Text('دفع الكل'),
              ),
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
            onPressed: _submitting ? null : () => _submit(technicianId),
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('تأكيد البيع'),
          ),
        ],
      ),
    );
  }
}
