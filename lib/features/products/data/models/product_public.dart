import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_public.freezed.dart';

/// What the customer app is allowed to see (from the `products_public` view)
/// — deliberately has no cost_price field at all.
@freezed
abstract class ProductPublic with _$ProductPublic {
  const factory ProductPublic({
    required String id,
    required String sku,
    String? barcode,
    String? categoryId,
    required String name,
    String? description,
    required Map<String, String> specs,
    required double sellingPrice,
    required bool isAvailable,
    required DateTime createdAt,
    String? primaryImageUrl,
  }) = _ProductPublic;

  factory ProductPublic.fromRow(Map<String, dynamic> row) => ProductPublic(
    id: row['id'] as String,
    sku: row['sku'] as String,
    barcode: row['barcode'] as String?,
    categoryId: row['category_id'] as String?,
    name: row['name'] as String,
    description: row['description'] as String?,
    specs: Map<String, String>.from(
      (row['specs'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          {},
    ),
    sellingPrice: (row['selling_price'] as num).toDouble(),
    isAvailable: row['is_available'] as bool? ?? false,
    createdAt: DateTime.parse(row['created_at'] as String),
    primaryImageUrl: row['primary_image_url'] as String?,
  );
}
