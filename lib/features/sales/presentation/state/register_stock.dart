import '../../../../core/offline/outbox.dart';
import '../../../inventory/data/models/warehouse_stock_item.dart';

/// What the register can sell: warehouse stock plus assembly products, with
/// walk-in sales still waiting in the offline queue ([queuedSales], i.e.
/// `outbox.pendingOf('walk_in_sale')`) already taken off — so selling
/// offline can't oversell what the cached stock list shows.
List<WarehouseStockItem> registerStock(
  List<WarehouseStockItem> warehouse,
  List<WarehouseStockItem> assemblies, {
  required List<OutboxEntry> queuedSales,
}) {
  final reserved = <String, int>{};
  for (final entry in queuedSales) {
    final items = entry.params['p_items'];
    if (items is! List) continue;
    for (final item in items) {
      if (item is! Map) continue;
      final id = item['product_id'] as String?;
      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
      if (id != null) reserved[id] = (reserved[id] ?? 0) + qty;
    }
  }
  WarehouseStockItem net(WarehouseStockItem i) {
    final r = reserved[i.productId] ?? 0;
    if (r == 0) return i;
    final left = i.quantity - r;
    return i.copyWith(quantity: left < 0 ? 0 : left);
  }

  return [...warehouse.map(net), ...assemblies.map(net)]
    ..sort((a, b) => a.productName.compareTo(b.productName));
}

/// What the register's grid shows for [query]: products with something
/// left to sell whose name or SKU contains it (case-insensitive). Filtering
/// the loaded list instead of re-querying per keystroke keeps typing instant
/// — the warehouse is small.
List<WarehouseStockItem> sellableMatching(
  List<WarehouseStockItem> stock,
  String query,
) {
  final q = query.trim().toLowerCase();
  return [
    for (final s in stock)
      if (s.quantity > 0 &&
          (q.isEmpty ||
              s.productName.toLowerCase().contains(q) ||
              s.sku.toLowerCase().contains(q)))
        s,
  ];
}
