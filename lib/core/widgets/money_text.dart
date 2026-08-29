import 'package:flutter/material.dart';
import '../utils/formatters.dart';

/// Consistent EGP money rendering everywhere (cashbox, accounts, reports).
class MoneyText extends StatelessWidget {
  final num amount;
  final TextStyle? style;
  final bool colorBySign;

  const MoneyText(this.amount, {super.key, this.style, this.colorBySign = false});

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge;
    Color? color;
    if (colorBySign) {
      final scheme = Theme.of(context).colorScheme;
      if (amount > 0) color = Colors.green.shade700;
      if (amount < 0) color = scheme.error;
    }
    return Text(Formatters.currency(amount), style: base?.copyWith(color: color));
  }
}
