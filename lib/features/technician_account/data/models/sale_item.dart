import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale_item.freezed.dart';

@freezed
abstract class SaleItem with _$SaleItem {
  const factory SaleItem({
    required String id,
    required String productNameSnapshot,
    required int quantity,
    required double unitPriceSnapshot,
    required double discount,
    required double lineTotal,
  }) = _SaleItem;

  factory SaleItem.fromRow(Map<String, dynamic> row) => SaleItem(
        id: row['id'] as String,
        productNameSnapshot: row['product_name_snapshot'] as String,
        quantity: row['quantity'] as int,
        unitPriceSnapshot: (row['unit_price_snapshot'] as num).toDouble(),
        discount: (row['discount'] as num).toDouble(),
        lineTotal: (row['line_total'] as num).toDouble(),
      );
}
