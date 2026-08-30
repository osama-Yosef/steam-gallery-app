import 'package:freezed_annotation/freezed_annotation.dart';

part 'technician_bag_stock_item.freezed.dart';

@freezed
abstract class TechnicianBagStockItem with _$TechnicianBagStockItem {
  const factory TechnicianBagStockItem({
    required String productId,
    required String productName,
    required String sku,
    required int quantity,
    required double costPrice,
    required double sellingPrice,
  }) = _TechnicianBagStockItem;

  const TechnicianBagStockItem._();

  double get value => quantity * costPrice;

  factory TechnicianBagStockItem.fromRow(Map<String, dynamic> row) {
    final product = row['products'] as Map<String, dynamic>;
    return TechnicianBagStockItem(
      productId: product['id'] as String,
      productName: product['name'] as String,
      sku: product['sku'] as String,
      quantity: row['quantity'] as int,
      costPrice: (product['cost_price'] as num).toDouble(),
      sellingPrice: (product['selling_price'] as num).toDouble(),
    );
  }
}
