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

String _$productRepositoryHash() => r'189cbe017fdbea4da1912327ce7e3a75e81ff836';

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

String _$categoriesHash() => r'1ec0bb10a4c270d70e9d455f3ea6bdaf1dc17bbe';

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

String _$catalogProductsHash() => r'e8ada7fa054ee7f471d5f481272f33da0aae9d88';

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

String _$relatedProductsHash() => r'd385171930752152b033a04a87a22ae923045a99';

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

String _$productOffersHash() => r'3c59193a28bb56367c18a6dbbbc022d6c93c2c5f';

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
    r'353f5e32f44b68f85298aa0d1fbf86c8c2e1e42f';

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

String _$productImagesHash() => r'8ba6db65fd4e6b3a3bd0eab37fb83dbeda1ac300';

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

@ProviderFor(productOptions)
const productOptionsProvider = ProductOptionsFamily._();

final class ProductOptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductOption>>,
          List<ProductOption>,
          FutureOr<List<ProductOption>>
        >
    with
        $FutureModifier<List<ProductOption>>,
        $FutureProvider<List<ProductOption>> {
  const ProductOptionsProvider._({
    required ProductOptionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productOptionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productOptionsHash();

  @override
  String toString() {
    return r'productOptionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProductOption>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProductOption>> create(Ref ref) {
    final argument = this.argument as String;
    return productOptions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductOptionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productOptionsHash() => r'a24ebbfa4499fd809199c00aa88e6bf5b2fd797a';

final class ProductOptionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProductOption>>, String> {
  const ProductOptionsFamily._()
    : super(
        retry: null,
        name: r'productOptionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductOptionsProvider call(String productId) =>
      ProductOptionsProvider._(argument: productId, from: this);

  @override
  String toString() => r'productOptionsProvider';
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

String _$adminProductsHash() => r'0f4e1fa3cbdf42aa83c0bab63865cd246b209356';

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

String _$serviceProductsHash() => r'4fd43f46b31c18fb373e3d9042470154891d0287';

@ProviderFor(assemblyComponents)
const assemblyComponentsProvider = AssemblyComponentsFamily._();

final class AssemblyComponentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AssemblyComponent>>,
          List<AssemblyComponent>,
          FutureOr<List<AssemblyComponent>>
        >
    with
        $FutureModifier<List<AssemblyComponent>>,
        $FutureProvider<List<AssemblyComponent>> {
  const AssemblyComponentsProvider._({
    required AssemblyComponentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'assemblyComponentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$assemblyComponentsHash();

  @override
  String toString() {
    return r'assemblyComponentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AssemblyComponent>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AssemblyComponent>> create(Ref ref) {
    final argument = this.argument as String;
    return assemblyComponents(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AssemblyComponentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$assemblyComponentsHash() =>
    r'c1aa4e692a2e7e5955e33b0a8342fcf869b736bb';

final class AssemblyComponentsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AssemblyComponent>>, String> {
  const AssemblyComponentsFamily._()
    : super(
        retry: null,
        name: r'assemblyComponentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AssemblyComponentsProvider call(String productId) =>
      AssemblyComponentsProvider._(argument: productId, from: this);

  @override
  String toString() => r'assemblyComponentsProvider';
}

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
