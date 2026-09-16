import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/catalog_query.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/product_image.dart';
import '../models/product_public.dart';

abstract class ProductRepository {
  // Categories (shared by admin + customer)
  Future<List<ProductCategory>> getCategories({bool activeOnly = false});
  Future<void> saveCategory(CategoryInput input);
  Future<String> uploadCategoryImage(Uint8List bytes, String fileExt);

  // Customer-facing catalog — products_public columns only (no cost_price).
  /// One page of the store (rpc_browse_products, 0034).
  Future<List<ProductPublic>> browseCatalog(
    CatalogQuery query, {
    required int limit,
    required int offset,
  });
  Future<ProductPublic?> getProductPublicById(String id);

  // Shared
  Future<List<ProductImage>> getProductImages(String productId);

  // Admin catalog management — full Product model incl. cost_price.
  Future<List<Product>> listProductsAdmin({String? search, String? categoryId});

  /// Active service (labour) lines — sellable at a price agreed per sale,
  /// with no stock behind them. See 0027.
  Future<List<Product>> listServices();

  Future<Product?> getProductByIdAdmin(String id);
  Future<String> createProduct({
    required String sku,
    String? barcode,
    String? categoryId,
    required String name,
    String? description,
    required Map<String, String> specs,
    required double costPrice,
    required double sellingPrice,
    required int minStock,
  });
  Future<void> updateProduct(
    String id, {
    required String sku,
    String? barcode,
    String? categoryId,
    required String name,
    String? description,
    required Map<String, String> specs,
    required double costPrice,
    required double sellingPrice,
    required int minStock,
  });
  Future<void> setProductActive(String id, bool isActive);

  /// Shows the product in the home screen's "مختارات مكوجي" (0033).
  Future<void> setProductFeatured(String id, bool isFeatured);
  Future<ProductImage> uploadProductImage(
    String productId,
    Uint8List bytes,
    String fileExt,
  );
  Future<void> deleteProductImage(ProductImage image);
  Future<void> setPrimaryImage(String productId, String imageId);
}

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _client;
  SupabaseProductRepository(this._client);

  @override
  Future<List<ProductCategory>> getCategories({bool activeOnly = false}) async {
    try {
      var query = _client.from('product_categories').select();
      if (activeOnly) query = query.eq('is_active', true);
      final rows = await query.order('sort_order');
      return rows.map(ProductCategory.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> saveCategory(CategoryInput input) async {
    try {
      final row = {
        'name': input.name.trim(),
        'parent_id': input.parentId,
        'image_url': input.imageUrl,
        'sort_order': input.sortOrder,
        'is_active': input.isActive,
      };
      if (input.id == null) {
        await _client.from('product_categories').insert(row);
      } else {
        await _client
            .from('product_categories')
            .update(row)
            .eq('id', input.id!);
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<String> uploadCategoryImage(Uint8List bytes, String fileExt) async {
    try {
      // Same public-read, admin-write bucket as product photos (0012).
      final path = 'categories/${const Uuid().v4()}.$fileExt';
      await _client.storage.from('products').uploadBinary(path, bytes);
      return _client.storage.from('products').getPublicUrl(path);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<ProductPublic>> browseCatalog(
    CatalogQuery query, {
    required int limit,
    required int offset,
  }) async {
    try {
      final rows = await _client.rpc(
        'rpc_browse_products',
        params: query.toRpcParams(limit: limit, offset: offset),
      );
      return (rows as List)
          .map(
            (r) => ProductPublic.fromRow(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<ProductPublic?> getProductPublicById(String id) async {
    try {
      final row = await _client
          .from('products_public')
          .select()
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : ProductPublic.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<ProductImage>> getProductImages(String productId) async {
    try {
      final rows = await _client
          .from('product_images')
          .select()
          .eq('product_id', productId)
          .order('sort_order');
      return rows.map(ProductImage.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<Product>> listProductsAdmin({
    String? search,
    String? categoryId,
  }) async {
    try {
      var query = _client
          .from('products')
          .select('*, product_images(image_url, is_primary, sort_order)');
      if (categoryId != null) query = query.eq('category_id', categoryId);
      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('name', '%${search.trim()}%');
      }
      final rows = await query.order('created_at', ascending: false);
      return rows.map(Product.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<Product>> listServices() async {
    try {
      final rows = await _client
          .from('products')
          .select()
          .eq('is_service', true)
          .eq('is_active', true)
          .order('name');
      return rows.map(Product.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<Product?> getProductByIdAdmin(String id) async {
    try {
      final row = await _client
          .from('products')
          .select()
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : Product.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<String> createProduct({
    required String sku,
    String? barcode,
    String? categoryId,
    required String name,
    String? description,
    required Map<String, String> specs,
    required double costPrice,
    required double sellingPrice,
    required int minStock,
  }) async {
    try {
      final row = await _client
          .from('products')
          .insert({
            'sku': sku,
            'barcode': barcode,
            'category_id': categoryId,
            'name': name,
            'description': description,
            'specs': specs,
            'cost_price': costPrice,
            'selling_price': sellingPrice,
            'min_stock': minStock,
            'created_by': _client.auth.currentUser?.id,
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> updateProduct(
    String id, {
    required String sku,
    String? barcode,
    String? categoryId,
    required String name,
    String? description,
    required Map<String, String> specs,
    required double costPrice,
    required double sellingPrice,
    required int minStock,
  }) async {
    try {
      await _client
          .from('products')
          .update({
            'sku': sku,
            'barcode': barcode,
            'category_id': categoryId,
            'name': name,
            'description': description,
            'specs': specs,
            'cost_price': costPrice,
            'selling_price': sellingPrice,
            'min_stock': minStock,
          })
          .eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> setProductFeatured(String id, bool isFeatured) async {
    try {
      await _client
          .from('products')
          .update({'is_featured': isFeatured})
          .eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> setProductActive(String id, bool isActive) async {
    try {
      await _client
          .from('products')
          .update({'is_active': isActive})
          .eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<ProductImage> uploadProductImage(
    String productId,
    Uint8List bytes,
    String fileExt,
  ) async {
    try {
      final path = '$productId/${const Uuid().v4()}.$fileExt';
      await _client.storage
          .from('products')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      final url = _client.storage.from('products').getPublicUrl(path);

      final existingCount = (await getProductImages(productId)).length;

      final row = await _client
          .from('product_images')
          .insert({
            'product_id': productId,
            'image_url': url,
            'sort_order': existingCount,
            'is_primary': existingCount == 0,
          })
          .select()
          .single();
      return ProductImage.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> deleteProductImage(ProductImage image) async {
    try {
      final uri = Uri.parse(image.imageUrl);
      final marker = '/products/';
      final idx = uri.path.indexOf(marker);
      if (idx != -1) {
        final storagePath = uri.path.substring(idx + marker.length);
        await _client.storage.from('products').remove([storagePath]);
      }
      await _client.from('product_images').delete().eq('id', image.id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> setPrimaryImage(String productId, String imageId) async {
    try {
      await _client
          .from('product_images')
          .update({'is_primary': false})
          .eq('product_id', productId);
      await _client
          .from('product_images')
          .update({'is_primary': true})
          .eq('id', imageId);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
