import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../sales/presentation/screens/admin/admin_sale_invoice_screen.dart';
import '../../data/models/cash_transaction.dart';
import '../providers/cashbox_providers.dart';
import '../screens/admin/admin_edit_expense_screen.dart';

/// Everything about one till movement, and a way to what it belongs to:
/// a sale opens its invoice, an expense its edit form, an online order its
/// page, a supplier payment the suppliers.
Future<void> showCashTransactionSheet(
  BuildContext context, {
  required CashTransaction txn,
  required String tillName,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _CashTransactionSheet(txn: txn, tillName: tillName),
);

class _CashTransactionSheet extends ConsumerWidget {
  final CashTransaction txn;
  final String tillName;
  const _CashTransactionSheet({required this.txn, required this.tillName});

  /// What the movement opens, if anything: (label, icon, action).
  (String, IconData, Future<void> Function())? _target(
    BuildContext context,
    WidgetRef ref,
  ) {
    final id = txn.referenceId;
    if (id == null) return null;
    final nav = Navigator.of(context);
    return switch (txn.referenceType) {
      'sale' => (
        'فتح الفاتورة',
        Iconsax.receipt_text_copy,
        () async {
          nav.pop();
          await nav.push(
            MaterialPageRoute<void>(
              builder: (_) => AdminSaleInvoiceScreen(saleId: id),
            ),
          );
        },
      ),
      'expense' => (
        'فتح المصروف وتعديله',
        Iconsax.receipt_minus_copy,
        () async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            final expense = await ref
                .read(cashboxRepositoryProvider)
                .getExpense(id);
            nav.pop();
            await nav.push(
              MaterialPageRoute<void>(
                builder: (_) => AdminEditExpenseScreen(expense: expense),
              ),
            );
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(content: Text(AppException.from(e).messageAr)),
            );
          }
        },
      ),
      'order' => (
        'فتح الطلب',
        Iconsax.bag_2_copy,
        () async {
          final router = GoRouter.of(context);
          nav.pop();
          await router.push(Routes.adminOrderDetail(id));
        },
      ),
      'supplier' => (
        'فتح الموردين',
        Iconsax.truck_copy,
        () async {
          final router = GoRouter.of(context);
          nav.pop();
          await router.push(Routes.adminSuppliers);
        },
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final target = _target(context, ref);

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              cashTxnLabelAr(txn),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            MoneyText(
              txn.amount,
              colorBySign: true,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            row('النوع', cashTxnTypeLabelAr(txn.type)),
            row('الخزنة', tillName),
            row('التاريخ', Formatters.dateTime(txn.createdAt)),
            if (txn.notes != null && txn.notes!.trim().isNotEmpty)
              row('ملاحظات', txn.notes!),
            if (target != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: target.$3,
                icon: Icon(target.$2),
                label: Text(target.$1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
