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

String _$salesRepositoryHash() => r'8358dc0e78148cc534546e9c452e381bc33c4855';

@ProviderFor(walkInSales)
const walkInSalesProvider = WalkInSalesProvider._();

final class WalkInSalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Sale>>,
          List<Sale>,
          FutureOr<List<Sale>>
        >
    with $FutureModifier<List<Sale>>, $FutureProvider<List<Sale>> {
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
  $FutureProviderElement<List<Sale>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Sale>> create(Ref ref) {
    return walkInSales(ref);
  }
}

String _$walkInSalesHash() => r'899f077d9d9feedad6c87e0faf64f23a7ada2268';

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
         isAutoDispose: false,
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

String _$saleReturnItemsHash() => r'3532f6eaf17036a2fd97d34cdf65afa9800dd88e';

final class SaleReturnItemsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SaleReturnItem>>, String> {
  const SaleReturnItemsFamily._()
    : super(
        retry: null,
        name: r'saleReturnItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
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
         isAutoDispose: false,
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

String _$saleByIdHash() => r'80bfb72764bc294b83cacb912f7582447446ab29';

final class SaleByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Sale>, String> {
  const SaleByIdFamily._()
    : super(
        retry: null,
        name: r'saleByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  SaleByIdProvider call(String saleId) =>
      SaleByIdProvider._(argument: saleId, from: this);

  @override
  String toString() => r'saleByIdProvider';
}

@ProviderFor(invoiceLines)
const invoiceLinesProvider = InvoiceLinesFamily._();

final class InvoiceLinesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InvoiceLine>>,
          List<InvoiceLine>,
          FutureOr<List<InvoiceLine>>
        >
    with
        $FutureModifier<List<InvoiceLine>>,
        $FutureProvider<List<InvoiceLine>> {
  const InvoiceLinesProvider._({
    required InvoiceLinesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'invoiceLinesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$invoiceLinesHash();

  @override
  String toString() {
    return r'invoiceLinesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<InvoiceLine>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InvoiceLine>> create(Ref ref) {
    final argument = this.argument as String;
    return invoiceLines(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InvoiceLinesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invoiceLinesHash() => r'a58802454874d5ecc3bd565c39a1cf6d98cf4702';

final class InvoiceLinesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<InvoiceLine>>, String> {
  const InvoiceLinesFamily._()
    : super(
        retry: null,
        name: r'invoiceLinesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InvoiceLinesProvider call(String saleId) =>
      InvoiceLinesProvider._(argument: saleId, from: this);

  @override
  String toString() => r'invoiceLinesProvider';
}
