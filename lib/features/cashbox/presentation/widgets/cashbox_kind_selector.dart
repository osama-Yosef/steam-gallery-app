import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../data/models/cashbox_balance.dart';

/// "كاش / تحويل" — which till (0059) money goes into or comes out of.
class CashboxKindSelector extends StatelessWidget {
  final CashboxKind value;
  final ValueChanged<CashboxKind> onChanged;

  const CashboxKindSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CashboxKind>(
      segments: const [
        ButtonSegment(
          value: CashboxKind.cash,
          icon: Icon(Iconsax.money_copy),
          label: Text('كاش'),
        ),
        ButtonSegment(
          value: CashboxKind.transfer,
          icon: Icon(Iconsax.card_copy),
          label: Text('تحويل'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
