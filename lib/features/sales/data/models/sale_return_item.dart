import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale_return_item.freezed.dart';

/// A sale_items row plus how much of it has already been returned (0058) —
/// reads sale_items_with_returns, not the raw immutable ledger table.
@freezed
abstract class SaleReturnItem with _$SaleReturnItem {
  const SaleReturnItem._();

  const factory SaleReturnItem({
    required String id,
    required String productNameSnapshot,
    required int quantity,
    required double unitPriceSnapshot,
    required double discount,
    required double lineTotal,
    required int returnedQuantity,
  }) = _SaleReturnItem;

  factory SaleReturnItem.fromRow(Map<String, dynamic> row) => SaleReturnItem(
    id: row['id'] as String,
    productNameSnapshot: row['product_name_snapshot'] as String,
    quantity: row['quantity'] as int,
    unitPriceSnapshot: (row['unit_price_snapshot'] as num).toDouble(),
    discount: (row['discount'] as num).toDouble(),
    lineTotal: (row['line_total'] as num).toDouble(),
    returnedQuantity: row['returned_quantity'] as int,
  );

  int get remainingQuantity => quantity - returnedQuantity;
}
