import 'package:flutter/material.dart';
import '../../../../../core/utils/input_formatters.dart';
import '../../../../products/data/models/product.dart';

/// Asks which service (labour) to add and at what price. Unlike a stock
/// product the price isn't in the catalogue — it's agreed per job — so it's
/// typed here. Returns null when cancelled; the price may be 0 or missing
/// (the caller refuses that with a message).
Future<({Product service, double price})?> showAddServiceDialog(
  BuildContext context,
  List<Product> services,
) async {
  var selected = services.first;
  // Not disposed here: the dialog's field is still on screen during the
  // closing animation, after this function has its answer.
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
              items: [
                for (final s in services)
                  DropdownMenuItem(
                    value: s,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (s) => setDialogState(() => selected = s!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [moneyInputFormatter],
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
  if (added != true) return null;
  return (service: selected, price: double.tryParse(priceCtrl.text) ?? 0);
}
