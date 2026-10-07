// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(orderRepository)
const orderRepositoryProvider = OrderRepositoryProvider._();

final class OrderRepositoryProvider
    extends
        $FunctionalProvider<OrderRepository, OrderRepository, OrderRepository>
    with $Provider<OrderRepository> {
  const OrderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderRepositoryHash();

  @$internal
  @override
  $ProviderElement<OrderRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OrderRepository create(Ref ref) {
    return orderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrderRepository>(value),
    );
  }
}

String _$orderRepositoryHash() => r'963a53c6ae00377d96d97e32280043b1311eab57';

@ProviderFor(customerOrders)
const customerOrdersProvider = CustomerOrdersFamily._();

final class CustomerOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Order>>,
          List<Order>,
          Stream<List<Order>>
        >
    with $FutureModifier<List<Order>>, $StreamProvider<List<Order>> {
  const CustomerOrdersProvider._({
    required CustomerOrdersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customerOrdersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerOrdersHash();

  @override
  String toString() {
    return r'customerOrdersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Order>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Order>> create(Ref ref) {
    final argument = this.argument as String;
    return customerOrders(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerOrdersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerOrdersHash() => r'22d3a4abfa8997819045b95f6b521f328ebb3e86';

final class CustomerOrdersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Order>>, String> {
  const CustomerOrdersFamily._()
    : super(
        retry: null,
        name: r'customerOrdersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomerOrdersProvider call(String customerId) =>
      CustomerOrdersProvider._(argument: customerId, from: this);

  @override
  String toString() => r'customerOrdersProvider';
}

@ProviderFor(orderDetail)
const orderDetailProvider = OrderDetailFamily._();

final class OrderDetailProvider
    extends $FunctionalProvider<AsyncValue<Order?>, Order?, Stream<Order?>>
    with $FutureModifier<Order?>, $StreamProvider<Order?> {
  const OrderDetailProvider._({
    required OrderDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderDetailHash();

  @override
  String toString() {
    return r'orderDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Order?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Order?> create(Ref ref) {
    final argument = this.argument as String;
    return orderDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderDetailHash() => r'883b0c26433d1c7962cdcd057d1d9e2320e9b4c7';

final class OrderDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Order?>, String> {
  const OrderDetailFamily._()
    : super(
        retry: null,
        name: r'orderDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderDetailProvider call(String orderId) =>
      OrderDetailProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderDetailProvider';
}

@ProviderFor(orderItems)
const orderItemsProvider = OrderItemsFamily._();

final class OrderItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OrderItem>>,
          List<OrderItem>,
          FutureOr<List<OrderItem>>
        >
    with $FutureModifier<List<OrderItem>>, $FutureProvider<List<OrderItem>> {
  const OrderItemsProvider._({
    required OrderItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'orderItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderItemsHash();

  @override
  String toString() {
    return r'orderItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<OrderItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OrderItem>> create(Ref ref) {
    final argument = this.argument as String;
    return orderItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderItemsHash() => r'7288947f69ea35c82a6630cd7ab2609b6e756328';

final class OrderItemsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<OrderItem>>, String> {
  const OrderItemsFamily._()
    : super(
        retry: null,
        name: r'orderItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OrderItemsProvider call(String orderId) =>
      OrderItemsProvider._(argument: orderId, from: this);

  @override
  String toString() => r'orderItemsProvider';
}

@ProviderFor(openOrders)
const openOrdersProvider = OpenOrdersProvider._();

final class OpenOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Order>>,
          List<Order>,
          Stream<List<Order>>
        >
    with $FutureModifier<List<Order>>, $StreamProvider<List<Order>> {
  const OpenOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openOrdersHash();

  @$internal
  @override
  $StreamProviderElement<List<Order>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Order>> create(Ref ref) {
    return openOrders(ref);
  }
}

String _$openOrdersHash() => r'5c77f356a65fc1a087cb3684ca4beec80d7673b0';

/// The orders history screen's results for one [HistoryQuery]: the first
/// page loads on watch, [loadMore] appends the next (infinite scroll).

@ProviderFor(OrderHistory)
const orderHistoryProvider = OrderHistoryFamily._();

/// The orders history screen's results for one [HistoryQuery]: the first
/// page loads on watch, [loadMore] appends the next (infinite scroll).
final class OrderHistoryProvider
    extends $AsyncNotifierProvider<OrderHistory, HistoryPage<Order>> {
  /// The orders history screen's results for one [HistoryQuery]: the first
  /// page loads on watch, [loadMore] appends the next (infinite scroll).
  const OrderHistoryProvider._({
    required OrderHistoryFamily super.from,
    required HistoryQuery super.argument,
  }) : super(
         retry: null,
         name: r'orderHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$orderHistoryHash();

  @override
  String toString() {
    return r'orderHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OrderHistory create() => OrderHistory();

  @override
  bool operator ==(Object other) {
    return other is OrderHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$orderHistoryHash() => r'139142feb5f47263516989e67c444bdcb1276efd';

/// The orders history screen's results for one [HistoryQuery]: the first
/// page loads on watch, [loadMore] appends the next (infinite scroll).

final class OrderHistoryFamily extends $Family
    with
        $ClassFamilyOverride<
          OrderHistory,
          AsyncValue<HistoryPage<Order>>,
          HistoryPage<Order>,
          FutureOr<HistoryPage<Order>>,
          HistoryQuery
        > {
  const OrderHistoryFamily._()
    : super(
        retry: null,
        name: r'orderHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The orders history screen's results for one [HistoryQuery]: the first
  /// page loads on watch, [loadMore] appends the next (infinite scroll).

  OrderHistoryProvider call(HistoryQuery query) =>
      OrderHistoryProvider._(argument: query, from: this);

  @override
  String toString() => r'orderHistoryProvider';
}

/// The orders history screen's results for one [HistoryQuery]: the first
/// page loads on watch, [loadMore] appends the next (infinite scroll).

abstract class _$OrderHistory extends $AsyncNotifier<HistoryPage<Order>> {
  late final _$args = ref.$arg as HistoryQuery;
  HistoryQuery get query => _$args;

  FutureOr<HistoryPage<Order>> build(HistoryQuery query);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<HistoryPage<Order>>, HistoryPage<Order>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HistoryPage<Order>>, HistoryPage<Order>>,
              AsyncValue<HistoryPage<Order>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
