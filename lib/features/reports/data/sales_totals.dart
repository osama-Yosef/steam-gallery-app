/// Sales in a date range as the invoices stand after their last edit — the
/// same rule as the month report (0092), so the two always agree.
///
/// An edit or a return never rewrites a sale line: units taken off become
/// rows in sale_item_returns, and a re-price returns the old units and adds
/// a line at the new price. So a line's `quantity` is what was first
/// invoiced; what stayed sold is `quantity - returned_quantity`. The
/// invoice's own `total` (subtotal - discount) is kept current by every
/// edit, which makes it the figure to count.
class SalesTotals {
  /// Before discounts, of what is on the invoices now.
  final double gross;

  /// Line and invoice discounts on what is on the invoices now.
  final double discounts;

  /// What the invoices add up to: [gross] - [discounts].
  final double net;

  /// Cost price of what stayed sold.
  final double cost;

  /// Value taken off invoices in range by edits and returns — already left
  /// out of every figure above; shown for information only.
  final double removed;

  const SalesTotals({
    required this.gross,
    required this.discounts,
    required this.net,
    required this.cost,
    required this.removed,
  });

  /// [sales]: completed sales rows (`id`, `total`, `discount`).
  /// [saleLines]: their sale_items_with_returns rows (`sale_id`, `quantity`,
  /// `returned_quantity`, `unit_price_snapshot`, `unit_cost_snapshot`,
  /// `discount`).
  /// [orders]: counted online orders (`total`, `discount`, and
  /// `order_items` with `quantity`, `unit_cost_snapshot`, `discount`) —
  /// an order is never edited line by line; a returned one leaves the
  /// counted statuses altogether.
  factory SalesTotals.from({
    required List<Map<String, dynamic>> sales,
    required List<Map<String, dynamic>> saleLines,
    required List<Map<String, dynamic>> orders,
  }) {
    double num_(Object? v) => (v as num?)?.toDouble() ?? 0;

    var net = 0.0, discounts = 0.0, cost = 0.0, removed = 0.0;

    final counted = <String>{};
    for (final s in sales) {
      counted.add(s['id'] as String);
      net += num_(s['total']);
      discounts += num_(s['discount']);
    }
    for (final l in saleLines) {
      if (!counted.contains(l['sale_id'])) continue;
      final qty = num_(l['quantity']);
      final returned = num_(l['returned_quantity']);
      final kept = qty - returned;
      cost += kept * num_(l['unit_cost_snapshot']);
      removed += returned * num_(l['unit_price_snapshot']);
      if (qty > 0) discounts += num_(l['discount']) * kept / qty;
    }

    for (final o in orders) {
      net += num_(o['total']);
      discounts += num_(o['discount']);
      for (final i in (o['order_items'] as List?) ?? const []) {
        final item = (i as Map).cast<String, dynamic>();
        cost += num_(item['quantity']) * num_(item['unit_cost_snapshot']);
        discounts += num_(item['discount']);
      }
    }

    double r(double v) => (v * 100).roundToDouble() / 100;
    return SalesTotals(
      gross: r(net + discounts),
      discounts: r(discounts),
      net: r(net),
      cost: r(cost),
      removed: r(removed),
    );
  }
}
