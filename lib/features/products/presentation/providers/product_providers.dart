import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../storefront/data/models/storefront_models.dart';
import '../../../storefront/presentation/providers/storefront_providers.dart';
import '../../data/models/catalog_query.dart';
import '../../data/models/product.dart';
import '../../data/models/product_category.dart';
import '../../data/models/product_image.dart';
import '../../data/models/product_option.dart';
import '../../data/models/product_public.dart';
import '../../data/repositories/product_repository.dart';

part 'product_providers.g.dart';

@Riverpod(keepAlive: true)
ProductRepository productRepository(Ref ref) {
  return SupabaseProductRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<List<ProductCategory>> categories(Ref ref, {bool activeOnly = false}) {
  return ref
      .watch(productRepositoryProvider)
      .getCategories(activeOnly: activeOnly);
}

/// Store page size. The RPC caps it at 50.
const catalogPageSize = 20;

/// Paginated store results for one [CatalogQuery]: the first page loads on
/// watch, [loadMore] appends the next one (infinite scroll).
@riverpod
class CatalogProducts extends _$CatalogProducts {
  @override
  Future<CatalogPage> build(CatalogQuery query) async {
    final items = await ref
        .watch(productRepositoryProvider)
        .browseCatalog(query, limit: catalogPageSize, offset: 0);
    return CatalogPage(items: items, hasMore: items.length == catalogPageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final next = await ref
          .read(productRepositoryProvider)
          .browseCatalog(
            query,
            limit: catalogPageSize,
            offset: current.items.length,
          );
      if (!ref.mounted) return;
      state = AsyncData(
        CatalogPage(
          items: [...current.items, ...next],
          hasMore: next.length == catalogPageSize,
        ),
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(loadingMore: false, loadMoreFailed: true),
      );
    }
  }
}

/// «منتجات مشابهة»: same category, the product itself excluded.
@riverpod
Future<List<ProductPublic>> relatedProducts(
  Ref ref, {
  required String productId,
  required String categoryId,
}) async {
  final items = await ref
      .watch(productRepositoryProvider)
      .browseCatalog(CatalogQuery(categoryId: categoryId), limit: 7, offset: 0);
  return items.where((p) => p.id != productId).take(6).toList();
}

/// Live offers this product is part of (RLS already hides the others).
@riverpod
Future<List<Offer>> productOffers(Ref ref, String productId) {
  return ref.watch(storefrontRepositoryProvider).getOffersForProduct(productId);
}

@riverpod
Future<ProductPublic?> customerProductDetail(Ref ref, String productId) {
  return ref.watch(productRepositoryProvider).getProductPublicById(productId);
}

@riverpod
Future<List<ProductImage>> productImages(Ref ref, String productId) {
  return ref.watch(productRepositoryProvider).getProductImages(productId);
}

@riverpod
Future<List<ProductOption>> productOptions(Ref ref, String productId) {
  return ref.watch(productRepositoryProvider).getProductOptions(productId);
}

@riverpod
Future<List<Product>> adminProducts(
  Ref ref, {
  String? search,
  String? categoryId,
}) {
  return ref
      .watch(productRepositoryProvider)
      .listProductsAdmin(search: search, categoryId: categoryId);
}

/// Service lines available to add to a sale (labour, no stock).
@riverpod
Future<List<Product>> serviceProducts(Ref ref) {
  return ref.watch(productRepositoryProvider).listServices();
}

@riverpod
Future<Product?> adminProductDetail(Ref ref, String productId) {
  return ref.watch(productRepositoryProvider).getProductByIdAdmin(productId);
}
