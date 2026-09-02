import 'package:freezed_annotation/freezed_annotation.dart';

part 'warehouse_stock_item.freezed.dart';

/// One row of the main warehouse's stock — a product joined with its
/// current quantity there.
@freezed
abstract class WarehouseStockItem with _$WarehouseStockItem {
  const factory WarehouseStockItem({
    required String productId,
    required String productName,
    required String sku,
    required int quantity,
    required double costPrice,
    required double sellingPrice,
    required int minStock,
  }) = _WarehouseStockItem;

  const WarehouseStockItem._();

  double get value => quantity * costPrice;
  bool get isLow => quantity <= minStock;

  factory WarehouseStockItem.fromRow(Map<String, dynamic> row) {
    final product = row['products'] as Map<String, dynamic>;
    return WarehouseStockItem(
      productId: product['id'] as String,
      productName: product['name'] as String,
      sku: product['sku'] as String,
      quantity: row['quantity'] as int,
      costPrice: (product['cost_price'] as num).toDouble(),
      sellingPrice: (product['selling_price'] as num).toDouble(),
      minStock: product['min_stock'] as int,
    );
  }
}
