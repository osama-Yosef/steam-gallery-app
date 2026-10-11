import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../technician_account/data/models/sale.dart';
import '../../data/models/cashbox_balance.dart';

IconData cashboxKindIcon(CashboxKind k) => switch (k) {
  CashboxKind.cash => Iconsax.money_copy,
  CashboxKind.main => Iconsax.safe_home_copy,
  CashboxKind.transfer => Iconsax.bank_copy,
  CashboxKind.wallet => Iconsax.mobile_copy,
};

/// Which of the four tills (0080) money goes into or comes out of. Chips
/// that wrap rather than a segmented bar: four Arabic names don't fit one
/// row on a phone.
class CashboxKindSelector extends StatelessWidget {
  final CashboxKind value;
  final ValueChanged<CashboxKind> onChanged;

  /// Tills not to offer (e.g. the source till when picking a destination).
  final Set<CashboxKind> exclude;

  const CashboxKindSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.exclude = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in CashboxKind.values)
          if (!exclude.contains(k))
            ChoiceChip(
              avatar: Icon(cashboxKindIcon(k), size: 18),
              label: Text(cashboxKindLabelAr(k)),
              selected: value == k,
              onSelected: (_) => onChanged(k),
            ),
      ],
    );
  }
}

/// نقدًا / تحويل بنكي / تحويل محفظة — how a customer paid.
class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in offeredPaymentMethods)
          ChoiceChip(
            avatar: Icon(cashboxKindIcon(cashboxKindForPayment(m)), size: 18),
            label: Text(paymentMethodLabelAr(m)),
            selected: value == m,
            onSelected: (_) => onChanged(m),
          ),
      ],
    );
  }
}
