import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_category.freezed.dart';

@freezed
abstract class ProductCategory with _$ProductCategory {
  const factory ProductCategory({
    required String id,
    String? parentId,
    required String name,
    String? imageUrl,
    required int sortOrder,
    required bool isActive,
  }) = _ProductCategory;

  factory ProductCategory.fromRow(Map<String, dynamic> row) => ProductCategory(
        id: row['id'] as String,
        parentId: row['parent_id'] as String?,
        name: row['name'] as String,
        imageUrl: row['image_url'] as String?,
        sortOrder: row['sort_order'] as int? ?? 0,
        isActive: row['is_active'] as bool? ?? true,
      );
}
