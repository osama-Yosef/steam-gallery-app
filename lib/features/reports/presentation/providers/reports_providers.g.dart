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

@ProviderFor(salesReport)
const salesReportProvider = SalesReportFamily._();

final class SalesReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<SalesReport>,
          SalesReport,
          FutureOr<SalesReport>
        >
    with $FutureModifier<SalesReport>, $FutureProvider<SalesReport> {
  const SalesReportProvider._({
    required SalesReportFamily super.from,
    required (DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'salesReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$salesReportHash();

  @override
  String toString() {
    return r'salesReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<SalesReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SalesReport> create(Ref ref) {
    final argument = this.argument as (DateTime, DateTime);
    return salesReport(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SalesReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$salesReportHash() => r'1f73c6a1fa41c10d1bafd19dc665acced8934b63';

final class SalesReportFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<SalesReport>, (DateTime, DateTime)> {
  const SalesReportFamily._()
    : super(
        retry: null,
        name: r'salesReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SalesReportProvider call(DateTime from, DateTime to) =>
      SalesReportProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'salesReportProvider';
}

@ProviderFor(profitReport)
const profitReportProvider = ProfitReportFamily._();

final class ProfitReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProfitReport>,
          ProfitReport,
          FutureOr<ProfitReport>
        >
    with $FutureModifier<ProfitReport>, $FutureProvider<ProfitReport> {
  const ProfitReportProvider._({
    required ProfitReportFamily super.from,
    required (DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'profitReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$profitReportHash();

  @override
  String toString() {
    return r'profitReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ProfitReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProfitReport> create(Ref ref) {
    final argument = this.argument as (DateTime, DateTime);
    return profitReport(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfitReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$profitReportHash() => r'9c316b21f1878b3dede5e0e5c9120197cc1c8d74';

final class ProfitReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ProfitReport>,
          (DateTime, DateTime)
        > {
  const ProfitReportFamily._()
    : super(
        retry: null,
        name: r'profitReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProfitReportProvider call(DateTime from, DateTime to) =>
      ProfitReportProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'profitReportProvider';
}

@ProviderFor(ordersProfitReport)
const ordersProfitReportProvider = OrdersProfitReportFamily._();

final class OrdersProfitReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrdersProfitReport>,
          OrdersProfitReport,
          FutureOr<OrdersProfitReport>
        >
    with
        $FutureModifier<OrdersProfitReport>,
        $FutureProvider<OrdersProfitReport> {
  const OrdersProfitReportProvider._({
    required OrdersProfitReportFamily super.from,
    required (DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'ordersProfitReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ordersProfitReportHash();

  @override
  String toString() {
    return r'ordersProfitReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<OrdersProfitReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OrdersProfitReport> create(Ref ref) {
    final argument = this.argument as (DateTime, DateTime);
    return ordersProfitReport(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is OrdersProfitReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ordersProfitReportHash() =>
    r'f76c0366c5b95265832657a774c01c282f922150';

final class OrdersProfitReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<OrdersProfitReport>,
          (DateTime, DateTime)
        > {
  const OrdersProfitReportFamily._()
    : super(
        retry: null,
        name: r'ordersProfitReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrdersProfitReportProvider call(DateTime from, DateTime to) =>
      OrdersProfitReportProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'ordersProfitReportProvider';
}

@ProviderFor(expensesReport)
const expensesReportProvider = ExpensesReportFamily._();

final class ExpensesReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExpensesReport>,
          ExpensesReport,
          FutureOr<ExpensesReport>
        >
    with $FutureModifier<ExpensesReport>, $FutureProvider<ExpensesReport> {
  const ExpensesReportProvider._({
    required ExpensesReportFamily super.from,
    required (DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'expensesReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expensesReportHash();

  @override
  String toString() {
    return r'expensesReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ExpensesReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExpensesReport> create(Ref ref) {
    final argument = this.argument as (DateTime, DateTime);
    return expensesReport(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpensesReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expensesReportHash() => r'ee7fee842d898ec486c515039ae436e25324ee7d';

final class ExpensesReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ExpensesReport>,
          (DateTime, DateTime)
        > {
  const ExpensesReportFamily._()
    : super(
        retry: null,
        name: r'expensesReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExpensesReportProvider call(DateTime from, DateTime to) =>
      ExpensesReportProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'expensesReportProvider';
}

@ProviderFor(inventoryReport)
const inventoryReportProvider = InventoryReportFamily._();

final class InventoryReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<InventoryReport>,
          InventoryReport,
          FutureOr<InventoryReport>
        >
    with $FutureModifier<InventoryReport>, $FutureProvider<InventoryReport> {
  const InventoryReportProvider._({
    required InventoryReportFamily super.from,
    required (DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'inventoryReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inventoryReportHash();

  @override
  String toString() {
    return r'inventoryReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<InventoryReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InventoryReport> create(Ref ref) {
    final argument = this.argument as (DateTime, DateTime);
    return inventoryReport(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inventoryReportHash() => r'f018f0deb5fc552f16060bdae32b84db80dd8485';

final class InventoryReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<InventoryReport>,
          (DateTime, DateTime)
        > {
  const InventoryReportFamily._()
    : super(
        retry: null,
        name: r'inventoryReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InventoryReportProvider call(DateTime from, DateTime to) =>
      InventoryReportProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'inventoryReportProvider';
}

/// Shared "من/إلى" filter across every report screen — defaults to
/// "this month so far". `to` is always exclusive (see repository's `.lt`).

@ProviderFor(ReportDateRange)
const reportDateRangeProvider = ReportDateRangeProvider._();

/// Shared "من/إلى" filter across every report screen — defaults to
/// "this month so far". `to` is always exclusive (see repository's `.lt`).
final class ReportDateRangeProvider
    extends $NotifierProvider<ReportDateRange, ReportRange> {
  /// Shared "من/إلى" filter across every report screen — defaults to
  /// "this month so far". `to` is always exclusive (see repository's `.lt`).
  const ReportDateRangeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportDateRangeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportDateRangeHash();

  @$internal
  @override
  ReportDateRange create() => ReportDateRange();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportRange value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportRange>(value),
    );
  }
}

String _$reportDateRangeHash() => r'f60043f2a7dbd48e899df256e7af84981370ca72';

/// Shared "من/إلى" filter across every report screen — defaults to
/// "this month so far". `to` is always exclusive (see repository's `.lt`).

abstract class _$ReportDateRange extends $Notifier<ReportRange> {
  ReportRange build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ReportRange, ReportRange>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReportRange, ReportRange>,
              ReportRange,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
