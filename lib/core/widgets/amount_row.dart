import 'package:flutter/material.dart';
import '../utils/formatters.dart';

/// "label ............ 1,234.00 ج.م" — one line of an invoice's totals.
class AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;

  const AmountRow(this.label, this.amount, {super.key, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = bold
        ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(Formatters.currency(amount), style: style),
        ],
      ),
    );
  }
}
