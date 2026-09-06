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
    String? imageUrl,
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
      imageUrl: _primaryImageFrom(product['product_images']),
    );
  }

  /// Same rule as Product.fromRow: the image flagged primary if there is one,
  /// otherwise whichever came back first.
  static String? _primaryImageFrom(Object? embedded) {
    if (embedded is! List || embedded.isEmpty) return null;
    final images = embedded.cast<Map<String, dynamic>>();
    final primary = images.where((i) => i['is_primary'] == true);
    final chosen = primary.isNotEmpty ? primary.first : images.first;
    return chosen['image_url'] as String?;
  }
}
