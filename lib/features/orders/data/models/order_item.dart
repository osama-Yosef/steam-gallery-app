import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_item.freezed.dart';

/// Mirrors order_items_display (NOT the raw order_items table) — no
/// unit_cost_snapshot here, this is shown to customers too.
@freezed
abstract class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    required String orderId,
    required String productId,
    required String productNameSnapshot,
    required int quantity,
    required double unitPriceSnapshot,
    required double discount,
    required double lineTotal,
  }) = _OrderItem;

  factory OrderItem.fromRow(Map<String, dynamic> row) => OrderItem(
    id: row['id'] as String,
    orderId: row['order_id'] as String,
    productId: row['product_id'] as String,
    productNameSnapshot: row['product_name_snapshot'] as String,
    quantity: row['quantity'] as int,
    unitPriceSnapshot: (row['unit_price_snapshot'] as num).toDouble(),
    discount: (row['discount'] as num).toDouble(),
    lineTotal: (row['line_total'] as num).toDouble(),
  );
}
