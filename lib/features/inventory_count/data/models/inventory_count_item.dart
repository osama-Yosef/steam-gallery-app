import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_count_item.freezed.dart';

@freezed
abstract class InventoryCountItem with _$InventoryCountItem {
  const factory InventoryCountItem({
    required String id,
    required String productId,
    required String productName,
    required String sku,
    required int systemQuantity,
    int? actualQuantity,
    required int difference,
    String? reason,
    String? notes,

    /// Cost per unit (0096): what an approved count booked it at, today's
    /// cost price before that.
    @Default(0) double unitCost,
  }) = _InventoryCountItem;

  const InventoryCountItem._();

  bool get isCounted => actualQuantity != null;
  bool get hasDifference => difference != 0;

  /// The shortage (negative) or surplus at cost.
  double get differenceValue => difference * unitCost;

  factory InventoryCountItem.fromRow(Map<String, dynamic> row) {
    final product = row['products'] as Map<String, dynamic>;
    return InventoryCountItem(
      id: row['id'] as String,
      productId: product['id'] as String,
      productName: product['name'] as String,
      sku: product['sku'] as String,
      systemQuantity: row['system_quantity'] as int,
      actualQuantity: row['actual_quantity'] as int?,
      difference: row['difference'] as int,
      reason: row['reason'] as String?,
      notes: row['notes'] as String?,
    );
  }
}
