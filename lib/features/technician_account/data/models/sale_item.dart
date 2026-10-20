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

    /// How much of the line was taken back — returned, or replaced by a
    /// re-priced line when the invoice was edited (0087).
    @Default(0) int returnedQuantity,
  }) = _SaleItem;

  const SaleItem._();

  /// What is still on the invoice.
  int get remainingQuantity => quantity - returnedQuantity;

  double get remainingTotal => quantity == 0
      ? 0
      : remainingQuantity * unitPriceSnapshot -
            discount * remainingQuantity / quantity;

  factory SaleItem.fromRow(Map<String, dynamic> row) => SaleItem(
    id: row['id'] as String,
    productNameSnapshot: row['product_name_snapshot'] as String,
    quantity: row['quantity'] as int,
    unitPriceSnapshot: (row['unit_price_snapshot'] as num).toDouble(),
    discount: (row['discount'] as num).toDouble(),
    lineTotal: (row['line_total'] as num).toDouble(),
    // Absent before 0087.
    returnedQuantity: (row['returned_quantity'] as num?)?.toInt() ?? 0,
  );
}
