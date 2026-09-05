// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_account_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(technicianAccountRepository)
const technicianAccountRepositoryProvider =
    TechnicianAccountRepositoryProvider._();

final class TechnicianAccountRepositoryProvider
    extends
        $FunctionalProvider<
          TechnicianAccountRepository,
          TechnicianAccountRepository,
          TechnicianAccountRepository
        >
    with $Provider<TechnicianAccountRepository> {
  const TechnicianAccountRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianAccountRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$technicianAccountRepositoryHash();

  @$internal
  @override
  $ProviderElement<TechnicianAccountRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TechnicianAccountRepository create(Ref ref) {
    return technicianAccountRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TechnicianAccountRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TechnicianAccountRepository>(value),
    );
  }
}

String _$technicianAccountRepositoryHash() =>
    r'4c7d0056d61a99402423b3d6158e280ac420fd16';

@ProviderFor(technicianAccountSummary)
const technicianAccountSummaryProvider = TechnicianAccountSummaryFamily._();

final class TechnicianAccountSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<TechnicianAccountSummary?>,
          TechnicianAccountSummary?,
          FutureOr<TechnicianAccountSummary?>
        >
    with
        $FutureModifier<TechnicianAccountSummary?>,
        $FutureProvider<TechnicianAccountSummary?> {
  const TechnicianAccountSummaryProvider._({
    required TechnicianAccountSummaryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'technicianAccountSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$technicianAccountSummaryHash();

  @override
  String toString() {
    return r'technicianAccountSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TechnicianAccountSummary?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TechnicianAccountSummary?> create(Ref ref) {
    final argument = this.argument as String;
    return technicianAccountSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TechnicianAccountSummaryProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$technicianAccountSummaryHash() =>
    r'096cbd94e62ce9dd1bc9ba84593f67dad711babc';

final class TechnicianAccountSummaryFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<TechnicianAccountSummary?>, String> {
  const TechnicianAccountSummaryFamily._()
    : super(
        retry: null,
        name: r'technicianAccountSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TechnicianAccountSummaryProvider call(String technicianId) =>
      TechnicianAccountSummaryProvider._(argument: technicianId, from: this);

  @override
  String toString() => r'technicianAccountSummaryProvider';
}

@ProviderFor(allTechnicianAccountSummaries)
const allTechnicianAccountSummariesProvider =
    AllTechnicianAccountSummariesProvider._();

final class AllTechnicianAccountSummariesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TechnicianAccountSummary>>,
          List<TechnicianAccountSummary>,
          FutureOr<List<TechnicianAccountSummary>>
        >
    with
        $FutureModifier<List<TechnicianAccountSummary>>,
        $FutureProvider<List<TechnicianAccountSummary>> {
  const AllTechnicianAccountSummariesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allTechnicianAccountSummariesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allTechnicianAccountSummariesHash();

  @$internal
  @override
  $FutureProviderElement<List<TechnicianAccountSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TechnicianAccountSummary>> create(Ref ref) {
    return allTechnicianAccountSummaries(ref);
  }
}

String _$allTechnicianAccountSummariesHash() =>
    r'0ef7bbfe72747fc5c1989aeef53ae06e0e08211f';

@ProviderFor(technicianAccountTransactions)
const technicianAccountTransactionsProvider =
    TechnicianAccountTransactionsFamily._();

final class TechnicianAccountTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TechnicianAccountTransaction>>,
          List<TechnicianAccountTransaction>,
          FutureOr<List<TechnicianAccountTransaction>>
        >
    with
        $FutureModifier<List<TechnicianAccountTransaction>>,
        $FutureProvider<List<TechnicianAccountTransaction>> {
  const TechnicianAccountTransactionsProvider._({
    required TechnicianAccountTransactionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'technicianAccountTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$technicianAccountTransactionsHash();

  @override
  String toString() {
    return r'technicianAccountTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TechnicianAccountTransaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TechnicianAccountTransaction>> create(Ref ref) {
    final argument = this.argument as String;
    return technicianAccountTransactions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TechnicianAccountTransactionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$technicianAccountTransactionsHash() =>
    r'fb50a1be87796e288c3fc9e4784942434aec2dac';

final class TechnicianAccountTransactionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<TechnicianAccountTransaction>>,
          String
        > {
  const TechnicianAccountTransactionsFamily._()
    : super(
        retry: null,
        name: r'technicianAccountTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TechnicianAccountTransactionsProvider call(String technicianId) =>
      TechnicianAccountTransactionsProvider._(
        argument: technicianId,
        from: this,
      );

  @override
  String toString() => r'technicianAccountTransactionsProvider';
}

@ProviderFor(technicianSales)
const technicianSalesProvider = TechnicianSalesFamily._();

final class TechnicianSalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Sale>>,
          List<Sale>,
          FutureOr<List<Sale>>
        >
    with $FutureModifier<List<Sale>>, $FutureProvider<List<Sale>> {
  const TechnicianSalesProvider._({
    required TechnicianSalesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'technicianSalesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$technicianSalesHash();

  @override
  String toString() {
    return r'technicianSalesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Sale>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Sale>> create(Ref ref) {
    final argument = this.argument as String;
    return technicianSales(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TechnicianSalesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$technicianSalesHash() => r'63c886bd628795827a16455cfe1ea126dc7eb6c2';

final class TechnicianSalesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Sale>>, String> {
  const TechnicianSalesFamily._()
    : super(
        retry: null,
        name: r'technicianSalesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TechnicianSalesProvider call(String technicianId) =>
      TechnicianSalesProvider._(argument: technicianId, from: this);

  @override
  String toString() => r'technicianSalesProvider';
}

@ProviderFor(technicianSaleDetail)
const technicianSaleDetailProvider = TechnicianSaleDetailFamily._();

final class TechnicianSaleDetailProvider
    extends $FunctionalProvider<AsyncValue<Sale?>, Sale?, FutureOr<Sale?>>
    with $FutureModifier<Sale?>, $FutureProvider<Sale?> {
  const TechnicianSaleDetailProvider._({
    required TechnicianSaleDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'technicianSaleDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$technicianSaleDetailHash();

  @override
  String toString() {
    return r'technicianSaleDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Sale?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Sale?> create(Ref ref) {
    final argument = this.argument as String;
    return technicianSaleDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TechnicianSaleDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$technicianSaleDetailHash() =>
    r'c5712c2f17763ab67404b49f7e2a1154af55dfbd';

final class TechnicianSaleDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Sale?>, String> {
  const TechnicianSaleDetailFamily._()
    : super(
        retry: null,
        name: r'technicianSaleDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TechnicianSaleDetailProvider call(String saleId) =>
      TechnicianSaleDetailProvider._(argument: saleId, from: this);

  @override
  String toString() => r'technicianSaleDetailProvider';
}

@ProviderFor(saleItems)
const saleItemsProvider = SaleItemsFamily._();

final class SaleItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SaleItem>>,
          List<SaleItem>,
          FutureOr<List<SaleItem>>
        >
    with $FutureModifier<List<SaleItem>>, $FutureProvider<List<SaleItem>> {
  const SaleItemsProvider._({
    required SaleItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'saleItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$saleItemsHash();

  @override
  String toString() {
    return r'saleItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SaleItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SaleItem>> create(Ref ref) {
    final argument = this.argument as String;
    return saleItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SaleItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$saleItemsHash() => r'9fccfebff1b626e042cacae2037c4496ab95591e';

final class SaleItemsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SaleItem>>, String> {
  const SaleItemsFamily._()
    : super(
        retry: null,
        name: r'saleItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SaleItemsProvider call(String saleId) =>
      SaleItemsProvider._(argument: saleId, from: this);

  @override
  String toString() => r'saleItemsProvider';
}

/// The invoice for a finished maintenance job — null until the technician
/// raises one.

@ProviderFor(maintenanceInvoice)
const maintenanceInvoiceProvider = MaintenanceInvoiceFamily._();

/// The invoice for a finished maintenance job — null until the technician
/// raises one.

final class MaintenanceInvoiceProvider
    extends $FunctionalProvider<AsyncValue<Sale?>, Sale?, FutureOr<Sale?>>
    with $FutureModifier<Sale?>, $FutureProvider<Sale?> {
  /// The invoice for a finished maintenance job — null until the technician
  /// raises one.
  const MaintenanceInvoiceProvider._({
    required MaintenanceInvoiceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'maintenanceInvoiceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$maintenanceInvoiceHash();

  @override
  String toString() {
    return r'maintenanceInvoiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Sale?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Sale?> create(Ref ref) {
    final argument = this.argument as String;
    return maintenanceInvoice(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MaintenanceInvoiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$maintenanceInvoiceHash() =>
    r'cfeadab15466b6b85d60d847e52e02b77157030d';

/// The invoice for a finished maintenance job — null until the technician
/// raises one.

final class MaintenanceInvoiceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Sale?>, String> {
  const MaintenanceInvoiceFamily._()
    : super(
        retry: null,
        name: r'maintenanceInvoiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The invoice for a finished maintenance job — null until the technician
  /// raises one.

  MaintenanceInvoiceProvider call(String maintenanceRequestId) =>
      MaintenanceInvoiceProvider._(argument: maintenanceRequestId, from: this);

  @override
  String toString() => r'maintenanceInvoiceProvider';
}
