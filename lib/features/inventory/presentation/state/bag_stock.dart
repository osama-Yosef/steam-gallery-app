import '../../../../core/offline/outbox.dart';
import '../../data/models/technician_bag_stock_item.dart';

/// [technicianId]'s bag as the server last reported it, minus his sales
/// still waiting to sync ([pendingSales]: `outbox.pendingOf('technician_sale')`)
/// — so selling offline can't oversell what the saved bag list shows.
/// Never below zero.
List<TechnicianBagStockItem> bagStockAfterPending(
  List<TechnicianBagStockItem> bag,
  List<OutboxEntry> pendingSales,
  String technicianId,
) {
  final reserved = <String, int>{};
  for (final entry in pendingSales) {
    if (entry.params['p_technician_id'] != technicianId) continue;
    final items = entry.params['p_items'];
    if (items is! List) continue;
    for (final item in items) {
      if (item is! Map) continue;
      final id = item['product_id'] as String?;
      final qty = (item['quantity'] as num?)?.toInt() ?? 0;
      if (id != null) reserved[id] = (reserved[id] ?? 0) + qty;
    }
  }
  if (reserved.isEmpty) return bag;
  return [
    for (final i in bag)
      if ((reserved[i.productId] ?? 0) == 0)
        i
      else
        i.copyWith(
          quantity: (i.quantity - reserved[i.productId]!).clamp(0, i.quantity),
        ),
  ];
}
