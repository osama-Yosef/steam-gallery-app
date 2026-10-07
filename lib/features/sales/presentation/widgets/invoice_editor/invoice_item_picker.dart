import 'package:flutter/material.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/input_formatters.dart';
import '../../../../../core/widgets/search_picker_sheet.dart';
import '../../../../inventory/data/models/warehouse_stock_item.dart';
import '../../../../products/data/models/product.dart';
import '../../../data/models/invoice_line.dart';

/// A thing that can be added to the invoice from the picker.
class _Pickable {
  final String productId;
  final String name;
  final double price;
  final int available;
  final bool isService;
  final bool isAssembly;
  const _Pickable({
    required this.productId,
    required this.name,
    required this.price,
    required this.available,
    this.isService = false,
    this.isAssembly = false,
  });
}

/// Lets the admin pick a product (from [stock]) or a service to add to an
/// invoice. A service then asks for the price agreed for it. Returns the
/// line to add with quantity 1, or null when cancelled or the service price
/// was invalid (which is reported with a snack bar).
Future<InvoiceLine?> pickInvoiceItem(
  BuildContext context, {
  required List<WarehouseStockItem> stock,
  required List<Product> services,
}) async {
  final pickables = [
    for (final s in stock)
      _Pickable(
        productId: s.productId,
        name: s.productName,
        price: s.displayPrice,
        available: s.quantity,
        isAssembly: s.isAssembly,
      ),
    for (final s in services)
      _Pickable(
        productId: s.id,
        name: s.name,
        price: s.sellingPrice,
        available: 999,
        isService: true,
      ),
  ];
  final picked = await showSearchPickerSheet<_Pickable>(
    context,
    title: 'إضافة صنف للفاتورة',
    items: pickables,
    label: (p) => p.name,
    subtitle: (p) => p.isService
        ? 'خدمة'
        : '${Formatters.currency(p.price)} · متاح ${p.available}'
              '${p.isAssembly ? ' · صنف تجميع' : ''}',
    enabled: (p) => p.isService || p.available > 0,
  );
  if (picked == null || !context.mounted) return null;

  var price = picked.price;
  if (picked.isService) {
    final typed = await _askServicePrice(context, picked.name);
    if (typed == null || !context.mounted) return null;
    if (typed <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('أدخل سعرًا صحيحًا')));
      return null;
    }
    price = typed;
  }
  return InvoiceLine(
    productId: picked.productId,
    productName: picked.name,
    quantity: 1,
    unitPrice: price,
    isService: picked.isService,
    isAssembly: picked.isAssembly,
  );
}

/// The price typed for a service, 0 when left empty, null when cancelled.
Future<double?> _askServicePrice(BuildContext context, String name) async {
  // Not disposed here: the dialog's field is still on screen during the
  // closing animation, after this function has its answer.
  final ctrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(name),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [moneyInputFormatter],
        decoration: const InputDecoration(labelText: 'سعر الخدمة'),
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
  );
  if (ok != true) return null;
  return double.tryParse(ctrl.text) ?? 0;
}
