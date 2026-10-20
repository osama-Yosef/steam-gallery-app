import 'package:flutter/material.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/input_formatters.dart';
import '../../state/walk_in_cart.dart';

/// Asks for the price per unit to charge on [line] — more or less than its
/// list price (0082). Null if cancelled; the list price is offered back.
Future<double?> showLinePriceDialog(BuildContext context, CartLine line) =>
    showPriceDialog(
      context,
      name: line.productName,
      price: line.unitPrice,
      listPrice: line.listPrice,
      canReset: line.priceChanged,
    );

/// The same question for any line: [price] is what it is charged now,
/// [listPrice] the product's own price. Used by the register and by a
/// technician selling from his bag (0086).
Future<double?> showPriceDialog(
  BuildContext context, {
  required String name,
  required double price,
  required double listPrice,
  bool? canReset,
}) => showDialog<double>(
  context: context,
  builder: (_) => _LinePriceDialog(
    name: name,
    price: price,
    listPrice: listPrice,
    canReset: canReset ?? price != listPrice,
  ),
);

/// A widget of its own so the text controller lives exactly as long as the
/// dialog, closing animation included.
class _LinePriceDialog extends StatefulWidget {
  final String name;
  final double price;
  final double listPrice;
  final bool canReset;
  const _LinePriceDialog({
    required this.name,
    required this.price,
    required this.listPrice,
    required this.canReset,
  });

  @override
  State<_LinePriceDialog> createState() => _LinePriceDialogState();
}

class _LinePriceDialogState extends State<_LinePriceDialog> {
  late final _ctrl = TextEditingController(
    text: Formatters.plain(widget.price),
  );
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final price = double.tryParse(_ctrl.text);
    if (price == null || price <= 0) {
      setState(() => _error = 'أدخل سعرًا صحيحًا');
      return;
    }
    Navigator.of(context).pop(price);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [moneyInputFormatter],
            decoration: InputDecoration(
              labelText: 'سعر القطعة',
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Text('السعر الأصلي ${Formatters.currency(widget.listPrice)}'),
        ],
      ),
      actions: [
        if (widget.canReset)
          TextButton(
            onPressed: () => Navigator.of(context).pop(widget.listPrice),
            child: const Text('رجّع السعر الأصلي'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }
}
