import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_image.freezed.dart';

@freezed
abstract class ProductImage with _$ProductImage {
  const factory ProductImage({
    required String id,
    required String productId,
    required String imageUrl,
    required int sortOrder,
    required bool isPrimary,
  }) = _ProductImage;

  factory ProductImage.fromRow(Map<String, dynamic> row) => ProductImage(
        id: row['id'] as String,
        productId: row['product_id'] as String,
        imageUrl: row['image_url'] as String,
        sortOrder: row['sort_order'] as int? ?? 0,
        isPrimary: row['is_primary'] as bool? ?? false,
      );
}
