import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/input_formatters.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../state/walk_in_cart.dart';

/// The register's bottom bar: discount sits directly above the total/confirm
/// button, and the cart itself expands from here so the product grid never
/// gets pushed off screen.
class WalkInCheckoutBar extends StatelessWidget {
  final WalkInCart cart;
  final double total;
  final TextEditingController discountCtrl;
  final TextEditingController notesCtrl;
  final PaymentMethod paymentMethod;
  final bool submitting;
  final VoidCallback onDiscountChanged;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final void Function(CartLine line, int delta) onChangeQuantity;
  final VoidCallback onSubmit;

  const WalkInCheckoutBar({
    super.key,
    required this.cart,
    required this.total,
    required this.discountCtrl,
    required this.notesCtrl,
    required this.paymentMethod,
    required this.submitting,
    required this.onDiscountChanged,
    required this.onPaymentMethodChanged,
    required this.onChangeQuantity,
    required this.onSubmit,
  });

  /// A walk-in customer pays in full on the spot — never "آجل".
  static const _methods = offeredPaymentMethods;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = cart.lines;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lines.isNotEmpty)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('السلة (${cart.itemCount} صنف)'),
                  subtitle: Text(
                    'المجموع ${Formatters.currency(cart.subtotal)}',
                  ),
                  children: [
                    for (final line in lines)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(line.productName),
                        subtitle: Text(
                          '${line.quantity} × '
                          '${Formatters.currency(line.unitPrice)}'
                          '${line.isService ? ' · خدمة' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Iconsax.minus_cirlce_copy),
                              onPressed: () => onChangeQuantity(line, -1),
                            ),
                            Text('${line.quantity}'),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Iconsax.add_circle_copy),
                              onPressed: () => onChangeQuantity(line, 1),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: discountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      // A hardware keyboard ignores keyboardType, so on
                      // desktop a stray letter used to sit in here silently
                      // parsing as 0 — found while testing the Windows build.
                      inputFormatters: [moneyInputFormatter],
                      decoration: const InputDecoration(
                        labelText: 'الخصم',
                        isDense: true,
                      ),
                      onChanged: (_) => onDiscountChanged(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<PaymentMethod>(
                      initialValue: paymentMethod,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'طريقة الدفع',
                        isDense: true,
                      ),
                      items: [
                        for (final m in _methods)
                          DropdownMenuItem(
                            value: m,
                            child: Text(paymentMethodLabelAr(m)),
                          ),
                      ],
                      onChanged: (m) => onPaymentMethodChanged(m!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: submitting || lines.isEmpty ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.card_pos_copy, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'تأكيد البيع · ${Formatters.currency(total)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
