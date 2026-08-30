import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/product.dart';
import '../../data/models/product_category.dart';
import '../../data/models/product_image.dart';
import '../../data/models/product_public.dart';
import '../../data/repositories/product_repository.dart';

part 'product_providers.g.dart';

@Riverpod(keepAlive: true)
ProductRepository productRepository(Ref ref) {
  return SupabaseProductRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<List<ProductCategory>> categories(Ref ref, {bool activeOnly = false}) {
  return ref.watch(productRepositoryProvider).getCategories(activeOnly: activeOnly);
}

@riverpod
Future<List<ProductPublic>> customerProducts(Ref ref, {String? search, String? categoryId}) {
  return ref.watch(productRepositoryProvider).browseProducts(search: search, categoryId: categoryId);
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
Future<List<Product>> adminProducts(Ref ref, {String? search, String? categoryId}) {
  return ref.watch(productRepositoryProvider).listProductsAdmin(search: search, categoryId: categoryId);
}

@riverpod
Future<Product?> adminProductDetail(Ref ref, String productId) {
  return ref.watch(productRepositoryProvider).getProductByIdAdmin(productId);
}
