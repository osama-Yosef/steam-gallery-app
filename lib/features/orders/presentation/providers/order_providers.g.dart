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

String _$orderRepositoryHash() => r'6d6ca501b010e879682a74fca8f685b1637aabba';

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

@ProviderFor(allOrders)
const allOrdersProvider = AllOrdersProvider._();

final class AllOrdersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Order>>,
          List<Order>,
          Stream<List<Order>>
        >
    with $FutureModifier<List<Order>>, $StreamProvider<List<Order>> {
  const AllOrdersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allOrdersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allOrdersHash();

  @$internal
  @override
  $StreamProviderElement<List<Order>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Order>> create(Ref ref) {
    return allOrders(ref);
  }
}

String _$allOrdersHash() => r'15b319f65faac08c662acf379e10d2b127c62cae';
