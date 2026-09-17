// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(productRepository)
const productRepositoryProvider = ProductRepositoryProvider._();

final class ProductRepositoryProvider
    extends
        $FunctionalProvider<
          ProductRepository,
          ProductRepository,
          ProductRepository
        >
    with $Provider<ProductRepository> {
  const ProductRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProductRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductRepository create(Ref ref) {
    return productRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductRepository>(value),
    );
  }
}

String _$productRepositoryHash() => r'6c09e39b585b5606eee4d06cb3d385e7176edfee';

@ProviderFor(categories)
const categoriesProvider = CategoriesFamily._();

final class CategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductCategory>>,
          List<ProductCategory>,
          FutureOr<List<ProductCategory>>
        >
    with
        $FutureModifier<List<ProductCategory>>,
        $FutureProvider<List<ProductCategory>> {
  const CategoriesProvider._({
    required CategoriesFamily super.from,
    required bool super.argument,
  }) : super(
         retry: null,
         name: r'categoriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @override
  String toString() {
    return r'categoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductCategory>> create(Ref ref) {
    final argument = this.argument as bool;
    return categories(ref, activeOnly: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoriesHash() => r'9fce36b999461df9e4107f38baaa993dbbf70e94';

final class CategoriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProductCategory>>, bool> {
  const CategoriesFamily._()
    : super(
        retry: null,
        name: r'categoriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CategoriesProvider call({bool activeOnly = false}) =>
      CategoriesProvider._(argument: activeOnly, from: this);

  @override
  String toString() => r'categoriesProvider';
}

/// Paginated store results for one [CatalogQuery]: the first page loads on
/// watch, [loadMore] appends the next one (infinite scroll).

@ProviderFor(CatalogProducts)
const catalogProductsProvider = CatalogProductsFamily._();

/// Paginated store results for one [CatalogQuery]: the first page loads on
/// watch, [loadMore] appends the next one (infinite scroll).
final class CatalogProductsProvider
    extends $AsyncNotifierProvider<CatalogProducts, CatalogPage> {
  /// Paginated store results for one [CatalogQuery]: the first page loads on
  /// watch, [loadMore] appends the next one (infinite scroll).
  const CatalogProductsProvider._({
    required CatalogProductsFamily super.from,
    required CatalogQuery super.argument,
  }) : super(
         retry: null,
         name: r'catalogProductsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$catalogProductsHash();

  @override
  String toString() {
    return r'catalogProductsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CatalogProducts create() => CatalogProducts();

  @override
  bool operator ==(Object other) {
    return other is CatalogProductsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$catalogProductsHash() => r'7a93a74f014e1469766d96b06b7e234be9b28952';

/// Paginated store results for one [CatalogQuery]: the first page loads on
/// watch, [loadMore] appends the next one (infinite scroll).

final class CatalogProductsFamily extends $Family
    with
        $ClassFamilyOverride<
          CatalogProducts,
          AsyncValue<CatalogPage>,
          CatalogPage,
          FutureOr<CatalogPage>,
          CatalogQuery
        > {
  const CatalogProductsFamily._()
    : super(
        retry: null,
        name: r'catalogProductsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Paginated store results for one [CatalogQuery]: the first page loads on
  /// watch, [loadMore] appends the next one (infinite scroll).

  CatalogProductsProvider call(CatalogQuery query) =>
      CatalogProductsProvider._(argument: query, from: this);

  @override
  String toString() => r'catalogProductsProvider';
}

/// Paginated store results for one [CatalogQuery]: the first page loads on
/// watch, [loadMore] appends the next one (infinite scroll).

abstract class _$CatalogProducts extends $AsyncNotifier<CatalogPage> {
  late final _$args = ref.$arg as CatalogQuery;
  CatalogQuery get query => _$args;

  FutureOr<CatalogPage> build(CatalogQuery query);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<CatalogPage>, CatalogPage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CatalogPage>, CatalogPage>,
              AsyncValue<CatalogPage>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// «منتجات مشابهة»: same category, the product itself excluded.

@ProviderFor(relatedProducts)
const relatedProductsProvider = RelatedProductsFamily._();

/// «منتجات مشابهة»: same category, the product itself excluded.

final class RelatedProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductPublic>>,
          List<ProductPublic>,
          FutureOr<List<ProductPublic>>
        >
    with
        $FutureModifier<List<ProductPublic>>,
        $FutureProvider<List<ProductPublic>> {
  /// «منتجات مشابهة»: same category, the product itself excluded.
  const RelatedProductsProvider._({
    required RelatedProductsFamily super.from,
    required ({String productId, String categoryId}) super.argument,
  }) : super(
         retry: null,
         name: r'relatedProductsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$relatedProductsHash();

  @override
  String toString() {
    return r'relatedProductsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductPublic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductPublic>> create(Ref ref) {
    final argument = this.argument as ({String productId, String categoryId});
    return relatedProducts(
      ref,
      productId: argument.productId,
      categoryId: argument.categoryId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RelatedProductsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$relatedProductsHash() => r'6af0c7d00f2b01ea2e67b9cfa85576cf1c0dda90';

/// «منتجات مشابهة»: same category, the product itself excluded.

final class RelatedProductsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ProductPublic>>,
          ({String productId, String categoryId})
        > {
  const RelatedProductsFamily._()
    : super(
        retry: null,
        name: r'relatedProductsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// «منتجات مشابهة»: same category, the product itself excluded.

  RelatedProductsProvider call({
    required String productId,
    required String categoryId,
  }) => RelatedProductsProvider._(
    argument: (productId: productId, categoryId: categoryId),
    from: this,
  );

  @override
  String toString() => r'relatedProductsProvider';
}

/// Live offers this product is part of (RLS already hides the others).

@ProviderFor(productOffers)
const productOffersProvider = ProductOffersFamily._();

/// Live offers this product is part of (RLS already hides the others).

final class ProductOffersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Offer>>,
          List<Offer>,
          FutureOr<List<Offer>>
        >
    with $FutureModifier<List<Offer>>, $FutureProvider<List<Offer>> {
  /// Live offers this product is part of (RLS already hides the others).
  const ProductOffersProvider._({
    required ProductOffersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productOffersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productOffersHash();

  @override
  String toString() {
    return r'productOffersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Offer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Offer>> create(Ref ref) {
    final argument = this.argument as String;
    return productOffers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductOffersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productOffersHash() => r'74e31e909319b7fbb49fddb7238cb339d7e29c9f';

/// Live offers this product is part of (RLS already hides the others).

final class ProductOffersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Offer>>, String> {
  const ProductOffersFamily._()
    : super(
        retry: null,
        name: r'productOffersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live offers this product is part of (RLS already hides the others).

  ProductOffersProvider call(String productId) =>
      ProductOffersProvider._(argument: productId, from: this);

  @override
  String toString() => r'productOffersProvider';
}

@ProviderFor(customerProductDetail)
const customerProductDetailProvider = CustomerProductDetailFamily._();

final class CustomerProductDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProductPublic?>,
          ProductPublic?,
          FutureOr<ProductPublic?>
        >
    with $FutureModifier<ProductPublic?>, $FutureProvider<ProductPublic?> {
  const CustomerProductDetailProvider._({
    required CustomerProductDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customerProductDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerProductDetailHash();

  @override
  String toString() {
    return r'customerProductDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ProductPublic?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProductPublic?> create(Ref ref) {
    final argument = this.argument as String;
    return customerProductDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerProductDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerProductDetailHash() =>
    r'803d50dde9a68049df2d30f2a33ab621997a0715';

final class CustomerProductDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ProductPublic?>, String> {
  const CustomerProductDetailFamily._()
    : super(
        retry: null,
        name: r'customerProductDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomerProductDetailProvider call(String productId) =>
      CustomerProductDetailProvider._(argument: productId, from: this);

  @override
  String toString() => r'customerProductDetailProvider';
}

@ProviderFor(productImages)
const productImagesProvider = ProductImagesFamily._();

final class ProductImagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductImage>>,
          List<ProductImage>,
          FutureOr<List<ProductImage>>
        >
    with
        $FutureModifier<List<ProductImage>>,
        $FutureProvider<List<ProductImage>> {
  const ProductImagesProvider._({
    required ProductImagesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productImagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productImagesHash();

  @override
  String toString() {
    return r'productImagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductImage>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductImage>> create(Ref ref) {
    final argument = this.argument as String;
    return productImages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductImagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productImagesHash() => r'f449b0989d2be994e2f922adda61fb53e62f7099';

final class ProductImagesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProductImage>>, String> {
  const ProductImagesFamily._()
    : super(
        retry: null,
        name: r'productImagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductImagesProvider call(String productId) =>
      ProductImagesProvider._(argument: productId, from: this);

  @override
  String toString() => r'productImagesProvider';
}

@ProviderFor(adminProducts)
const adminProductsProvider = AdminProductsFamily._();

final class AdminProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Product>>,
          List<Product>,
          FutureOr<List<Product>>
        >
    with $FutureModifier<List<Product>>, $FutureProvider<List<Product>> {
  const AdminProductsProvider._({
    required AdminProductsFamily super.from,
    required ({String? search, String? categoryId}) super.argument,
  }) : super(
         retry: null,
         name: r'adminProductsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminProductsHash();

  @override
  String toString() {
    return r'adminProductsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Product>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Product>> create(Ref ref) {
    final argument = this.argument as ({String? search, String? categoryId});
    return adminProducts(
      ref,
      search: argument.search,
      categoryId: argument.categoryId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminProductsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminProductsHash() => r'a7a8b68063e331a56f1c1997fbf5916fd5905f4c';

final class AdminProductsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Product>>,
          ({String? search, String? categoryId})
        > {
  const AdminProductsFamily._()
    : super(
        retry: null,
        name: r'adminProductsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AdminProductsProvider call({String? search, String? categoryId}) =>
      AdminProductsProvider._(
        argument: (search: search, categoryId: categoryId),
        from: this,
      );

  @override
  String toString() => r'adminProductsProvider';
}

/// Service lines available to add to a sale (labour, no stock).

@ProviderFor(serviceProducts)
const serviceProductsProvider = ServiceProductsProvider._();

/// Service lines available to add to a sale (labour, no stock).

final class ServiceProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Product>>,
          List<Product>,
          FutureOr<List<Product>>
        >
    with $FutureModifier<List<Product>>, $FutureProvider<List<Product>> {
  /// Service lines available to add to a sale (labour, no stock).
  const ServiceProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceProductsHash();

  @$internal
  @override
  $FutureProviderElement<List<Product>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Product>> create(Ref ref) {
    return serviceProducts(ref);
  }
}

String _$serviceProductsHash() => r'7e290ccd4612816fbeed5b119e0446e436175ca1';

@ProviderFor(adminProductDetail)
const adminProductDetailProvider = AdminProductDetailFamily._();

final class AdminProductDetailProvider
    extends
        $FunctionalProvider<AsyncValue<Product?>, Product?, FutureOr<Product?>>
    with $FutureModifier<Product?>, $FutureProvider<Product?> {
  const AdminProductDetailProvider._({
    required AdminProductDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'adminProductDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminProductDetailHash();

  @override
  String toString() {
    return r'adminProductDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Product?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Product?> create(Ref ref) {
    final argument = this.argument as String;
    return adminProductDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminProductDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminProductDetailHash() =>
    r'069cf0fddd07d35b1ac929b1627554cf722b5d47';

final class AdminProductDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Product?>, String> {
  const AdminProductDetailFamily._()
    : super(
        retry: null,
        name: r'adminProductDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AdminProductDetailProvider call(String productId) =>
      AdminProductDetailProvider._(argument: productId, from: this);

  @override
  String toString() => r'adminProductDetailProvider';
}
