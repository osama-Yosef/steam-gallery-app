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

@ProviderFor(customerProducts)
const customerProductsProvider = CustomerProductsFamily._();

final class CustomerProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductPublic>>,
          List<ProductPublic>,
          FutureOr<List<ProductPublic>>
        >
    with
        $FutureModifier<List<ProductPublic>>,
        $FutureProvider<List<ProductPublic>> {
  const CustomerProductsProvider._({
    required CustomerProductsFamily super.from,
    required ({String? search, String? categoryId}) super.argument,
  }) : super(
         retry: null,
         name: r'customerProductsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerProductsHash();

  @override
  String toString() {
    return r'customerProductsProvider'
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
    final argument = this.argument as ({String? search, String? categoryId});
    return customerProducts(
      ref,
      search: argument.search,
      categoryId: argument.categoryId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerProductsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerProductsHash() => r'e2a474bed455595103ec442ae8867d65312b8fd5';

final class CustomerProductsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ProductPublic>>,
          ({String? search, String? categoryId})
        > {
  const CustomerProductsFamily._()
    : super(
        retry: null,
        name: r'customerProductsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomerProductsProvider call({String? search, String? categoryId}) =>
      CustomerProductsProvider._(
        argument: (search: search, categoryId: categoryId),
        from: this,
      );

  @override
  String toString() => r'customerProductsProvider';
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
