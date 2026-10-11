import 'package:flutter/material.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/input_formatters.dart';
import '../../state/walk_in_cart.dart';

/// Asks for the price per unit to charge on [line] — more or less than its
/// list price (0082). Null if cancelled; the list price is offered back.
Future<double?> showLinePriceDialog(BuildContext context, CartLine line) =>
    showDialog<double>(
      context: context,
      builder: (_) => _LinePriceDialog(line: line),
    );

/// A widget of its own so the text controller lives exactly as long as the
/// dialog, closing animation included.
class _LinePriceDialog extends StatefulWidget {
  final CartLine line;
  const _LinePriceDialog({required this.line});

  @override
  State<_LinePriceDialog> createState() => _LinePriceDialogState();
}

class _LinePriceDialogState extends State<_LinePriceDialog> {
  late final _ctrl = TextEditingController(
    text: widget.line.unitPrice.toStringAsFixed(2),
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
    final line = widget.line;
    return AlertDialog(
      title: Text(line.productName),
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
          Text('السعر الأصلي ${Formatters.currency(line.listPrice)}'),
        ],
      ),
      actions: [
        if (line.priceChanged)
          TextButton(
            onPressed: () => Navigator.of(context).pop(line.listPrice),
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
