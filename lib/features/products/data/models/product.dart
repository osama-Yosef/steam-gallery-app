import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';

/// Admin-facing product — includes cost_price. NEVER expose this model or
/// its JSON to the customer app; customers must read `products_public`
/// instead (see ProductPublic + docs/04-security-architecture.md).
@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String sku,
    String? barcode,
    String? categoryId,
    required String name,
    String? description,
    required Map<String, String> specs,
    required double costPrice,
    required double sellingPrice,
    required int minStock,
    required bool isActive,
    required DateTime createdAt,
  }) = _Product;

  factory Product.fromRow(Map<String, dynamic> row) => Product(
        id: row['id'] as String,
        sku: row['sku'] as String,
        barcode: row['barcode'] as String?,
        categoryId: row['category_id'] as String?,
        name: row['name'] as String,
        description: row['description'] as String?,
        specs: Map<String, String>.from(
          (row['specs'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
        ),
        costPrice: (row['cost_price'] as num).toDouble(),
        sellingPrice: (row['selling_price'] as num).toDouble(),
        minStock: row['min_stock'] as int? ?? 0,
        isActive: row['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
