import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/input_formatters.dart';
import '../../../../../core/widgets/amount_row.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../../data/models/invoice_line.dart';

/// Date, customer, payment and status of the invoice, plus a note when a
/// change to it is still waiting to be synced.
class InvoiceInfoCard extends StatelessWidget {
  final Sale sale;
  final bool pendingDelete;
  final bool fromPending;

  const InvoiceInfoCard({
    super.key,
    required this.sale,
    required this.pendingDelete,
    required this.fromPending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              Formatters.dateTime(sale.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            if (sale.customerName != null) Text('العميل: ${sale.customerName}'),
            if (sale.customerPhone != null)
              Text('التليفون: ${sale.customerPhone}'),
            Text('الدفع: ${paymentMethodLabelAr(sale.paymentMethod)}'),
            Text(
              'الحالة: ${saleStatusLabelAr(sale.status)}',
              style: TextStyle(
                color: sale.status == SaleStatus.completed
                    ? AppColors.success
                    : AppColors.danger,
              ),
            ),
            if (pendingDelete)
              const Text(
                'الفاتورة هتتحذف أول ما النت يرجع',
                style: TextStyle(color: AppColors.warning),
              )
            else if (fromPending)
              const Text(
                'بتعدل على آخر تعديل لسه مستني المزامنة',
                style: TextStyle(color: AppColors.warning),
              ),
          ],
        ),
      ),
    );
  }
}

/// The invoice's lines, with −/+/remove controls when it can be edited.
class InvoiceLinesCard extends StatelessWidget {
  final List<InvoiceLine> lines;
  final bool editable;
  final void Function(String productId, int delta) onChangeQuantity;
  final ValueChanged<String> onRemove;

  const InvoiceLinesCard({
    super.key,
    required this.lines,
    required this.editable,
    required this.onChangeQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (lines.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('لا توجد أصناف')),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final l in lines)
            ListTile(
              title: Text(l.productName),
              subtitle: Text(
                '${Formatters.currency(l.unitPrice)}'
                '${l.isService ? ' · خدمة' : ''}'
                '${l.isAssembly ? ' · صنف تجميع' : ''}'
                '  =  ${Formatters.currency(l.lineTotal)}',
              ),
              trailing: editable
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Iconsax.minus_cirlce_copy),
                          onPressed: () => onChangeQuantity(l.productId, -1),
                        ),
                        Text(
                          '${l.quantity}',
                          style: theme.textTheme.titleSmall,
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.add_circle_copy),
                          onPressed: () => onChangeQuantity(l.productId, 1),
                        ),
                        IconButton(
                          tooltip: 'حذف الصنف',
                          icon: const Icon(
                            Iconsax.trash_copy,
                            color: AppColors.danger,
                          ),
                          onPressed: () => onRemove(l.productId),
                        ),
                      ],
                    )
                  : Text('× ${l.quantity}'),
            ),
        ],
      ),
    );
  }
}

/// Subtotal, the discount (editable), the total, and how far it is from
/// what the customer already paid.
class InvoiceTotalsCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double total;

  /// The invoice's total as the server has it — what was paid.
  final double savedTotal;
  final bool editable;
  final TextEditingController discountCtrl;
  final VoidCallback onDiscountChanged;

  const InvoiceTotalsCard({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.savedTotal,
    required this.editable,
    required this.discountCtrl,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final diff = total - savedTotal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmountRow('المجموع', subtotal),
            if (editable)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: discountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [moneyInputFormatter],
                  decoration: const InputDecoration(
                    labelText: 'الخصم',
                    isDense: true,
                  ),
                  onChanged: (_) => onDiscountChanged(),
                ),
              )
            else
              AmountRow('الخصم', discount),
            AmountRow('الإجمالي', total, bold: true),
            if (editable && diff.abs() >= 0.005)
              Text(
                diff > 0
                    ? 'فرق مطلوب من العميل: ${Formatters.currency(diff)}'
                    : 'فرق يُرد للعميل: ${Formatters.currency(-diff)}',
                style: TextStyle(
                  color: diff > 0 ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
