// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(salesRepository)
const salesRepositoryProvider = SalesRepositoryProvider._();

final class SalesRepositoryProvider
    extends
        $FunctionalProvider<SalesRepository, SalesRepository, SalesRepository>
    with $Provider<SalesRepository> {
  const SalesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesRepositoryHash();

  @$internal
  @override
  $ProviderElement<SalesRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SalesRepository create(Ref ref) {
    return salesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SalesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SalesRepository>(value),
    );
  }
}

String _$salesRepositoryHash() => r'536847a7a7bb853be98d835bf38d6ba025fb301a';

@ProviderFor(walkInSales)
const walkInSalesProvider = WalkInSalesProvider._();

final class WalkInSalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Sale>>,
          List<Sale>,
          Stream<List<Sale>>
        >
    with $FutureModifier<List<Sale>>, $StreamProvider<List<Sale>> {
  const WalkInSalesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walkInSalesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walkInSalesHash();

  @$internal
  @override
  $StreamProviderElement<List<Sale>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Sale>> create(Ref ref) {
    return walkInSales(ref);
  }
}

String _$walkInSalesHash() => r'4f5ae84113bdaab866773cf12a78112dbae44d05';

@ProviderFor(saleReturnItems)
const saleReturnItemsProvider = SaleReturnItemsFamily._();

final class SaleReturnItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SaleReturnItem>>,
          List<SaleReturnItem>,
          FutureOr<List<SaleReturnItem>>
        >
    with
        $FutureModifier<List<SaleReturnItem>>,
        $FutureProvider<List<SaleReturnItem>> {
  const SaleReturnItemsProvider._({
    required SaleReturnItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'saleReturnItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$saleReturnItemsHash();

  @override
  String toString() {
    return r'saleReturnItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SaleReturnItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SaleReturnItem>> create(Ref ref) {
    final argument = this.argument as String;
    return saleReturnItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SaleReturnItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$saleReturnItemsHash() => r'2da9bb41889946f8219c33f96c286111bcd45a7a';

final class SaleReturnItemsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SaleReturnItem>>, String> {
  const SaleReturnItemsFamily._()
    : super(
        retry: null,
        name: r'saleReturnItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SaleReturnItemsProvider call(String saleId) =>
      SaleReturnItemsProvider._(argument: saleId, from: this);

  @override
  String toString() => r'saleReturnItemsProvider';
}

@ProviderFor(saleById)
const saleByIdProvider = SaleByIdFamily._();

final class SaleByIdProvider
    extends $FunctionalProvider<AsyncValue<Sale>, Sale, FutureOr<Sale>>
    with $FutureModifier<Sale>, $FutureProvider<Sale> {
  const SaleByIdProvider._({
    required SaleByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'saleByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$saleByIdHash();

  @override
  String toString() {
    return r'saleByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Sale> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Sale> create(Ref ref) {
    final argument = this.argument as String;
    return saleById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SaleByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$saleByIdHash() => r'a756c3464a9b10803ae44eeff7b5037c67966389';

final class SaleByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Sale>, String> {
  const SaleByIdFamily._()
    : super(
        retry: null,
        name: r'saleByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SaleByIdProvider call(String saleId) =>
      SaleByIdProvider._(argument: saleId, from: this);

  @override
  String toString() => r'saleByIdProvider';
}
