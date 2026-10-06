import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/offline_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../../cashbox/data/models/cashbox_balance.dart';
import '../providers/purchases_providers.dart';
import '../../../../features/cashbox/presentation/widgets/cashbox_kind_selector.dart';

/// Pays [maxAmount] or less to a supplier, out of the cash or transfer till.
/// With [invoiceId] the payment goes against that invoice; without it, the
/// server settles the supplier's oldest unpaid invoices first.
Future<void> showPaySupplierDialog(
  BuildContext context,
  WidgetRef ref, {
  required String supplierId,
  required String supplierName,
  required double maxAmount,
  String? invoiceId,
}) async {
  final amountCtrl = TextEditingController(text: maxAmount.toStringAsFixed(2));
  final notesCtrl = TextEditingController();
  var kind = CashboxKind.cash;
  // One key per dialog: pressing "سداد" twice on a flaky connection must not
  // pay twice.
  final requestId = const Uuid().v4();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('سداد للمورد $supplierName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('المستحق: ${Formatters.currency(maxAmount)}'),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(labelText: 'المبلغ'),
              ),
              const SizedBox(height: 12),
              CashboxKindSelector(
                value: kind,
                onChanged: (k) => setState(() => kind = k),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('سداد'),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final amount = double.tryParse(amountCtrl.text) ?? 0;
  if (amount <= 0 || amount > maxAmount + 0.001) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('المبلغ لازم يكون أكبر من صفر ومش أكبر من المستحق'),
      ),
    );
    return;
  }
  try {
    final result = await ref
        .read(purchasesRepositoryProvider)
        .paySupplier(
          supplierId: supplierId,
          supplierName: supplierName,
          amount: double.parse(amount.toStringAsFixed(2)),
          kind: kind,
          invoiceId: invoiceId,
          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          clientRequestId: requestId,
        );
    if (!context.mounted) return;
    if (result.queued) {
      showSavedOfflineSnack(context, 'السداد اتسجل');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تسجيل السداد')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
    }
  }
}
