import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/input_formatters.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../state/walk_in_cart.dart';

/// How the customer pays for this sale (0084).
enum WalkInPayMode {
  /// All of it, now.
  full,

  /// Nothing now — all of it on the customer's account.
  credit,

  /// Part now, the rest on the customer's account.
  partial,
}

String walkInPayModeLabelAr(WalkInPayMode m) => switch (m) {
  WalkInPayMode.full => 'نقدي',
  WalkInPayMode.credit => 'آجل',
  WalkInPayMode.partial => 'جزئي',
};

/// The register's bottom bar: discount sits directly above the total/confirm
/// button, and the cart itself expands from here so the product grid never
/// gets pushed off screen.
class WalkInCheckoutBar extends StatelessWidget {
  final WalkInCart cart;
  final double total;
  final TextEditingController discountCtrl;
  final TextEditingController notesCtrl;
  final PaymentMethod paymentMethod;
  final WalkInPayMode payMode;

  /// What is paid now — shown for [WalkInPayMode.partial].
  final TextEditingController paidCtrl;
  final bool submitting;
  final VoidCallback onDiscountChanged;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final ValueChanged<WalkInPayMode> onPayModeChanged;
  final VoidCallback onPaidChanged;
  final void Function(CartLine line, int delta) onChangeQuantity;

  /// Tapping a line re-prices it (0082).
  final ValueChanged<CartLine> onEditPrice;
  final VoidCallback onSubmit;

  const WalkInCheckoutBar({
    super.key,
    required this.cart,
    required this.total,
    required this.discountCtrl,
    required this.notesCtrl,
    required this.paymentMethod,
    required this.payMode,
    required this.paidCtrl,
    required this.submitting,
    required this.onDiscountChanged,
    required this.onPaymentMethodChanged,
    required this.onPayModeChanged,
    required this.onPaidChanged,
    required this.onChangeQuantity,
    required this.onEditPrice,
    required this.onSubmit,
  });

  /// Where the money paid now goes; آجل is chosen as a [WalkInPayMode].
  static const _methods = offeredPaymentMethods;

  double get _paid => double.tryParse(paidCtrl.text) ?? 0;

  String get _confirmLabel => switch (payMode) {
    WalkInPayMode.full => 'تأكيد البيع · ${Formatters.currency(total)}',
    WalkInPayMode.credit => 'بيع آجل · ${Formatters.currency(total)}',
    WalkInPayMode.partial =>
      'مدفوع ${Formatters.currency(_paid)} · الباقي '
          '${Formatters.currency(total - _paid)}',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = cart.lines;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: Border(top: BorderSide(color: theme.colorScheme.outline)),
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
                        onTap: () => onEditPrice(line),
                        subtitle: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${line.quantity} × '
                                    '${Formatters.currency(line.unitPrice)}',
                                style: line.priceChanged
                                    ? TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      )
                                    : null,
                              ),
                              if (line.priceChanged)
                                TextSpan(
                                  text:
                                      ' (بدل ${Formatters.currency(line.listPrice)})',
                                ),
                              if (line.isService)
                                const TextSpan(text: ' · خدمة'),
                              const TextSpan(text: '  '),
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(Iconsax.edit_2_copy, size: 14),
                              ),
                            ],
                          ),
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
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<WalkInPayMode>(
                  segments: [
                    for (final m in WalkInPayMode.values)
                      ButtonSegment(
                        value: m,
                        label: Text(walkInPayModeLabelAr(m)),
                      ),
                  ],
                  selected: {payMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => onPayModeChanged(s.first),
                ),
              ),
              const SizedBox(height: 8),
              if (payMode == WalkInPayMode.partial) ...[
                TextField(
                  controller: paidCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [moneyInputFormatter],
                  decoration: const InputDecoration(
                    labelText: 'المدفوع الآن',
                    isDense: true,
                  ),
                  onChanged: (_) => onPaidChanged(),
                ),
                const SizedBox(height: 8),
              ],
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
                  if (payMode != WalkInPayMode.credit) ...[
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
                              _confirmLabel,
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
