import 'package:flutter/material.dart';
import '../../../../technician_account/data/models/sale.dart';

/// Asks for the shipping fee to propose to the customer (0065). Returns the
/// amount, or null when cancelled; an empty or negative entry keeps the
/// dialog open.
Future<double?> askShippingFee(BuildContext context, double? currentFee) {
  // Not disposed here: the dialog's field is still on screen during the
  // closing animation, after this function has its answer.
  final amountCtrl = TextEditingController(
    text: currentFee == null ? '' : currentFee.toStringAsFixed(2),
  );
  return showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('تحديد سعر الشحن'),
      content: TextField(
        controller: amountCtrl,
        decoration: const InputDecoration(labelText: 'سعر الشحن'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final a = double.tryParse(amountCtrl.text);
            if (a == null || a < 0) return;
            Navigator.of(ctx).pop(a);
          },
          child: const Text('إرسال للعميل'),
        ),
      ],
    ),
  );
}

/// Asks why an order is being cancelled or returned. Returns the reason,
/// or null when the admin backs out or leaves it empty — neither action
/// goes ahead without one.
Future<String?> askOrderReason(
  BuildContext context, {
  required String title,
  required String fieldLabel,
  required String confirmLabel,
}) async {
  final reasonCtrl = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: reasonCtrl,
        decoration: InputDecoration(labelText: fieldLabel),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('تراجع'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.of(ctx).pop(reasonCtrl.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return reason == null || reason.isEmpty ? null : reason;
}

/// Asks how much the customer paid towards the order and how it came in.
/// Starts at what is still owed. Returns null when cancelled or the amount
/// isn't positive.
Future<({double amount, PaymentMethod method})?> askOrderPayment(
  BuildContext context, {
  required double remaining,
}) async {
  final amountCtrl = TextEditingController(
    text: remaining > 0 ? remaining.toStringAsFixed(2) : '',
  );
  var method = PaymentMethod.cash;
  final result = await showDialog<({double amount, PaymentMethod method})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('تسجيل دفعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'المبلغ'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('استُلم الفلوس إزاي؟'),
            const SizedBox(height: 8),
            SegmentedButton<PaymentMethod>(
              segments: const [
                ButtonSegment(value: PaymentMethod.cash, label: Text('نقدًا')),
                ButtonSegment(
                  value: PaymentMethod.transfer,
                  label: Text('تحويل'),
                ),
              ],
              selected: {method},
              onSelectionChanged: (s) => setDialogState(() => method = s.first),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text);
              if (amount == null) return;
              Navigator.of(ctx).pop((amount: amount, method: method));
            },
            child: const Text('تسجيل'),
          ),
        ],
      ),
    ),
  );
  if (result == null || result.amount <= 0) return null;
  return result;
}
