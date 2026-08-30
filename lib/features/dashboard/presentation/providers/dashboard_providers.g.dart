// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dashboardRepository)
const dashboardRepositoryProvider = DashboardRepositoryProvider._();

final class DashboardRepositoryProvider
    extends
        $FunctionalProvider<
          DashboardRepository,
          DashboardRepository,
          DashboardRepository
        >
    with $Provider<DashboardRepository> {
  const DashboardRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardRepositoryHash();

  @$internal
  @override
  $ProviderElement<DashboardRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DashboardRepository create(Ref ref) {
    return dashboardRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DashboardRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DashboardRepository>(value),
    );
  }
}

String _$dashboardRepositoryHash() =>
    r'8eb9740021022918b37063e42c2299ed01cd41e5';

@ProviderFor(dashboardSummary)
const dashboardSummaryProvider = DashboardSummaryProvider._();

final class DashboardSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DashboardSummary>,
          DashboardSummary,
          FutureOr<DashboardSummary>
        >
    with $FutureModifier<DashboardSummary>, $FutureProvider<DashboardSummary> {
  const DashboardSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardSummaryHash();

  @$internal
  @override
  $FutureProviderElement<DashboardSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DashboardSummary> create(Ref ref) {
    return dashboardSummary(ref);
  }
}

String _$dashboardSummaryHash() => r'fa2db08bcae0a1ff992d5d463c0b793642e231cb';

@ProviderFor(dashboardRevenueTrend)
const dashboardRevenueTrendProvider = DashboardRevenueTrendProvider._();

final class DashboardRevenueTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DailyRevenuePoint>>,
          List<DailyRevenuePoint>,
          FutureOr<List<DailyRevenuePoint>>
        >
    with
        $FutureModifier<List<DailyRevenuePoint>>,
        $FutureProvider<List<DailyRevenuePoint>> {
  const DashboardRevenueTrendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardRevenueTrendProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardRevenueTrendHash();

  @$internal
  @override
  $FutureProviderElement<List<DailyRevenuePoint>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DailyRevenuePoint>> create(Ref ref) {
    return dashboardRevenueTrend(ref);
  }
}

String _$dashboardRevenueTrendHash() =>
    r'6cad5ce716440d7791b0201b9babc39b9ea4bb8b';
