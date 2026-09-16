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

/// Admin category form payload (insert when [id] is null).
class CategoryInput {
  final String? id;
  final String name;
  final String? parentId;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;

  const CategoryInput({
    this.id,
    required this.name,
    this.parentId,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  static const maxNameLength = 60;

  /// Mirrors the table CHECKs added in 0034.
  String? get error {
    final n = name.trim();
    if (n.isEmpty) return 'اكتب اسم القسم';
    if (n.length > maxNameLength) return 'اسم القسم طويل جدًا';
    if (id != null && parentId == id) {
      return 'القسم لا يمكن أن يكون تابعًا لنفسه';
    }
    return null;
  }
}

/// Top-level categories, and the children of each, in display order.
({List<ProductCategory> roots, Map<String, List<ProductCategory>> children})
groupCategories(List<ProductCategory> all) {
  final ids = {for (final c in all) c.id};
  final roots = <ProductCategory>[];
  final children = <String, List<ProductCategory>>{};
  for (final c in all) {
    // A child whose parent is hidden (inactive) is shown as a root instead.
    if (c.parentId == null || !ids.contains(c.parentId)) {
      roots.add(c);
    } else {
      children.putIfAbsent(c.parentId!, () => []).add(c);
    }
  }
  return (roots: roots, children: children);
}
