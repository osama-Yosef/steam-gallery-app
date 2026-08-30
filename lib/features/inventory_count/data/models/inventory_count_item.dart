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
  }) = _InventoryCountItem;

  const InventoryCountItem._();

  bool get isCounted => actualQuantity != null;
  bool get hasDifference => difference != 0;

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
