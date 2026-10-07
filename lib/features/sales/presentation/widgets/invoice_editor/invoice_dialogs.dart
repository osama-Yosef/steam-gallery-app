import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../cashbox/data/models/cashbox_balance.dart';
import '../../../../cashbox/presentation/widgets/cashbox_kind_selector.dart';
import '../../../../technician_account/data/models/sale.dart';

/// Confirms saving an edited invoice: shows the old and new totals and what
/// that means in money, and — when money moves — which till it moves
/// through. Returns that till, or null when the admin backs out.
Future<CashboxKind?> confirmInvoiceSave(
  BuildContext context, {
  required double oldTotal,
  required double newTotal,
  required CashboxKind defaultKind,
}) async {
  final diff = newTotal - oldTotal;
  final moneyMoves = diff.abs() >= 0.005;
  var kind = defaultKind;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: const Text('حفظ التعديلات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('الإجمالي القديم: ${Formatters.currency(oldTotal)}'),
            Text('الإجمالي الجديد: ${Formatters.currency(newTotal)}'),
            const SizedBox(height: 8),
            Text(
              !moneyMoves
                  ? 'لا يوجد فرق في الفلوس'
                  : diff > 0
                  ? 'هيتم تحصيل ${Formatters.currency(diff)} من العميل'
                  : 'هيتم رد ${Formatters.currency(-diff)} للعميل',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: diff < 0 ? AppColors.danger : AppColors.success,
              ),
            ),
            if (moneyMoves) ...[
              const SizedBox(height: 12),
              CashboxKindSelector(
                value: kind,
                onChanged: (k) => setDialog(() => kind = k),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    ),
  );
  return ok == true ? kind : null;
}

/// Confirms deleting (cancelling) a whole invoice: everything goes back to
/// the warehouse and its total is refunded from the chosen till. Returns
/// the reason typed (possibly empty) and the till, or null when the admin
/// backs out.
Future<({String reason, CashboxKind kind})?> confirmInvoiceDelete(
  BuildContext context, {
  required Sale sale,
  required CashboxKind defaultKind,
}) async {
  // Not disposed here: the dialog's field is still on screen during the
  // closing animation, after this function has its answer.
  final reasonCtrl = TextEditingController();
  var kind = defaultKind;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: Text('حذف فاتورة #${sale.saleNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'كل الأصناف هترجع المخزن، وهيتم رد ${Formatters.currency(sale.total)} للعميل.',
            ),
            const SizedBox(height: 12),
            if (sale.total > 0)
              CashboxKindSelector(
                value: kind,
                onChanged: (k) => setDialog(() => kind = k),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'السبب'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return null;
  return (reason: reasonCtrl.text.trim(), kind: kind);
}
