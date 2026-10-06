import '../../../core/offline/outbox.dart';
import '../../inventory/data/models/warehouse_stock_item.dart';

/// What the register can sell: warehouse stock plus assembly products, with
/// walk-in sales still waiting in the offline queue already taken off — so
/// selling offline can't oversell what the cached stock list shows.
List<WarehouseStockItem> registerStock(
  List<WarehouseStockItem> warehouse,
  List<WarehouseStockItem> assemblies,
) {
  final reserved = <String, int>{};
  for (final entry in Outbox.instance.pendingOf('walk_in_sale')) {
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
