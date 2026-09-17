import 'package:freezed_annotation/freezed_annotation.dart';

import 'product_public.dart';

part 'catalog_query.freezed.dart';

/// Sort orders accepted by `rpc_browse_products` (0034). Anything else is
/// refused server-side with INVALID_SORT.
enum CatalogSort {
  newest('newest', 'الأحدث'),
  priceAsc('price_asc', 'السعر: من الأقل'),
  priceDesc('price_desc', 'السعر: من الأعلى'),
  name('name', 'الاسم');

  const CatalogSort(this.rpcValue, this.labelAr);
  final String rpcValue;
  final String labelAr;
}

/// Everything the store screen can filter by. Value-equal, so it is a stable
/// provider family key: the same query reuses the already-loaded pages.
@freezed
abstract class CatalogQuery with _$CatalogQuery {
  const CatalogQuery._();

  const factory CatalogQuery({
    String? search,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    @Default(false) bool availableOnly,
    @Default(CatalogSort.newest) CatalogSort sort,
  }) = _CatalogQuery;

  /// Filters behind the «فلترة» sheet (search, category and sort are shown
  /// on the screen itself).
  int get sheetFilterCount =>
      (minPrice != null || maxPrice != null ? 1 : 0) + (availableOnly ? 1 : 0);

  bool get hasAnyFilter =>
      (search?.trim().isNotEmpty ?? false) ||
      categoryId != null ||
      sheetFilterCount > 0;

  Map<String, dynamic> toRpcParams({required int limit, required int offset}) {
    final term = search?.trim();
    return {
      'p_search': term == null || term.isEmpty ? null : term,
      'p_category_id': categoryId,
      'p_min_price': minPrice,
      'p_max_price': maxPrice,
      'p_available_only': availableOnly,
      'p_sort': sort.rpcValue,
      'p_limit': limit,
      'p_offset': offset,
    };
  }
}

/// Mirrors the RPC's INVALID_PRICE_RANGE check so the sheet can say so before
/// sending anything.
String? priceRangeError(double? min, double? max) {
  if ((min != null && min < 0) || (max != null && max < 0)) {
    return 'السعر لا يمكن أن يكون سالبًا';
  }
  if (min != null && max != null && min > max) {
    return 'أقل سعر يجب ألا يتجاوز أعلى سعر';
  }
  return null;
}

/// Loaded pages of one [CatalogQuery].
@freezed
abstract class CatalogPage with _$CatalogPage {
  const factory CatalogPage({
    required List<ProductPublic> items,
    required bool hasMore,
    @Default(false) bool loadingMore,
    @Default(false) bool loadMoreFailed,
  }) = _CatalogPage;
}
