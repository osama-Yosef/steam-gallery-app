import 'package:flutter/material.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../data/models/order.dart';
import '../../../data/models/order_item.dart';

/// The order's products: price × quantity (and chosen options), line total.
class OrderItemsCard extends StatelessWidget {
  final List<OrderItem> items;
  const OrderItemsCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final it in items)
            ListTile(
              title: Text(it.productNameSnapshot),
              subtitle: Text(
                '${Formatters.currency(it.unitPriceSnapshot)} × ${it.quantity}'
                '${it.selectedOptions.isEmpty ? '' : ' — ${it.selectedOptions.map((o) => o.name).join('، ')}'}',
              ),
              trailing: Text(Formatters.currency(it.lineTotal)),
            ),
        ],
      ),
    );
  }
}

/// Total, paid so far, and what is still owed.
class OrderTotalsCard extends StatelessWidget {
  final Order order;
  const OrderTotalsCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(context, 'الإجمالي', Formatters.currency(order.total)),
            _row(context, 'المدفوع', Formatters.currency(order.paidAmount)),
            _row(
              context,
              'المتبقي',
              Formatters.currency(order.remaining),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final style = bold
        ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
