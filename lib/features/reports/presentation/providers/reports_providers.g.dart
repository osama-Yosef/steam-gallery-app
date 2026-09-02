// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reportsRepository)
const reportsRepositoryProvider = ReportsRepositoryProvider._();

final class ReportsRepositoryProvider
    extends
        $FunctionalProvider<
          ReportsRepository,
          ReportsRepository,
          ReportsRepository
        >
    with $Provider<ReportsRepository> {
  const ReportsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReportsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReportsRepository create(Ref ref) {
    return reportsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportsRepository>(value),
    );
  }
}

String _$reportsRepositoryHash() => r'a197dd69425ba8c5e3eb02c5904164861d94e75e';

@ProviderFor(dailySales)
const dailySalesProvider = DailySalesProvider._();

final class DailySalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SalesPeriodSummary>>,
          List<SalesPeriodSummary>,
          FutureOr<List<SalesPeriodSummary>>
        >
    with
        $FutureModifier<List<SalesPeriodSummary>>,
        $FutureProvider<List<SalesPeriodSummary>> {
  const DailySalesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailySalesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailySalesHash();

  @$internal
  @override
  $FutureProviderElement<List<SalesPeriodSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SalesPeriodSummary>> create(Ref ref) {
    return dailySales(ref);
  }
}

String _$dailySalesHash() => r'09bd27f625ec2cfd702926c8b2e21ed4da74790c';

@ProviderFor(monthlySales)
const monthlySalesProvider = MonthlySalesProvider._();

final class MonthlySalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SalesPeriodSummary>>,
          List<SalesPeriodSummary>,
          FutureOr<List<SalesPeriodSummary>>
        >
    with
        $FutureModifier<List<SalesPeriodSummary>>,
        $FutureProvider<List<SalesPeriodSummary>> {
  const MonthlySalesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlySalesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlySalesHash();

  @$internal
  @override
  $FutureProviderElement<List<SalesPeriodSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SalesPeriodSummary>> create(Ref ref) {
    return monthlySales(ref);
  }
}

String _$monthlySalesHash() => r'29eb7390c64bc952496c33a9130a4d914a1d8cd2';

@ProviderFor(warehouseStockValue)
const warehouseStockValueProvider = WarehouseStockValueProvider._();

final class WarehouseStockValueProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  const WarehouseStockValueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'warehouseStockValueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$warehouseStockValueHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return warehouseStockValue(ref);
  }
}

String _$warehouseStockValueHash() =>
    r'af08a5395b09429791667872dfea26d5b48c4035';

@ProviderFor(lowStockProducts)
const lowStockProductsProvider = LowStockProductsProvider._();

final class LowStockProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LowStockProduct>>,
          List<LowStockProduct>,
          FutureOr<List<LowStockProduct>>
        >
    with
        $FutureModifier<List<LowStockProduct>>,
        $FutureProvider<List<LowStockProduct>> {
  const LowStockProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lowStockProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lowStockProductsHash();

  @$internal
  @override
  $FutureProviderElement<List<LowStockProduct>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LowStockProduct>> create(Ref ref) {
    return lowStockProducts(ref);
  }
}

String _$lowStockProductsHash() => r'f74d182437b74c4948dbc66f0661556bd9b2cac2';

@ProviderFor(technicianAccountsReport)
const technicianAccountsReportProvider = TechnicianAccountsReportProvider._();

final class TechnicianAccountsReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TechnicianAccountReportRow>>,
          List<TechnicianAccountReportRow>,
          FutureOr<List<TechnicianAccountReportRow>>
        >
    with
        $FutureModifier<List<TechnicianAccountReportRow>>,
        $FutureProvider<List<TechnicianAccountReportRow>> {
  const TechnicianAccountsReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technicianAccountsReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$technicianAccountsReportHash();

  @$internal
  @override
  $FutureProviderElement<List<TechnicianAccountReportRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TechnicianAccountReportRow>> create(Ref ref) {
    return technicianAccountsReport(ref);
  }
}

String _$technicianAccountsReportHash() =>
    r'2ab4f70a368479a24c03ae4f7ee623d8f6cb8fb6';

@ProviderFor(customerAccountsReport)
const customerAccountsReportProvider = CustomerAccountsReportProvider._();

final class CustomerAccountsReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CustomerAccountReportRow>>,
          List<CustomerAccountReportRow>,
          FutureOr<List<CustomerAccountReportRow>>
        >
    with
        $FutureModifier<List<CustomerAccountReportRow>>,
        $FutureProvider<List<CustomerAccountReportRow>> {
  const CustomerAccountsReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerAccountsReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerAccountsReportHash();

  @$internal
  @override
  $FutureProviderElement<List<CustomerAccountReportRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CustomerAccountReportRow>> create(Ref ref) {
    return customerAccountsReport(ref);
  }
}

String _$customerAccountsReportHash() =>
    r'0b0abde2cb025535f064c9aa9c9b4ba3401bf687';
