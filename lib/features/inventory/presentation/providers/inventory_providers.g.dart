// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inventoryRepository)
const inventoryRepositoryProvider = InventoryRepositoryProvider._();

final class InventoryRepositoryProvider
    extends
        $FunctionalProvider<
          InventoryRepository,
          InventoryRepository,
          InventoryRepository
        >
    with $Provider<InventoryRepository> {
  const InventoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<InventoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryRepository create(Ref ref) {
    return inventoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryRepository>(value),
    );
  }
}

String _$inventoryRepositoryHash() =>
    r'8a4df661d9d86576f4fd8393d9e3a4d7482cbdea';

@ProviderFor(warehouseStock)
const warehouseStockProvider = WarehouseStockFamily._();

final class WarehouseStockProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WarehouseStockItem>>,
          List<WarehouseStockItem>,
          FutureOr<List<WarehouseStockItem>>
        >
    with
        $FutureModifier<List<WarehouseStockItem>>,
        $FutureProvider<List<WarehouseStockItem>> {
  const WarehouseStockProvider._({
    required WarehouseStockFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'warehouseStockProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$warehouseStockHash();

  @override
  String toString() {
    return r'warehouseStockProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<WarehouseStockItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WarehouseStockItem>> create(Ref ref) {
    final argument = this.argument as String?;
    return warehouseStock(ref, search: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WarehouseStockProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$warehouseStockHash() => r'1f28239225ed35c90a7e8034573b3f2e2ca05fbb';

final class WarehouseStockFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<WarehouseStockItem>>, String?> {
  const WarehouseStockFamily._()
    : super(
        retry: null,
        name: r'warehouseStockProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WarehouseStockProvider call({String? search}) =>
      WarehouseStockProvider._(argument: search, from: this);

  @override
  String toString() => r'warehouseStockProvider';
}

@ProviderFor(technicianBagStock)
const technicianBagStockProvider = TechnicianBagStockFamily._();

final class TechnicianBagStockProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TechnicianBagStockItem>>,
          List<TechnicianBagStockItem>,
          FutureOr<List<TechnicianBagStockItem>>
        >
    with
        $FutureModifier<List<TechnicianBagStockItem>>,
        $FutureProvider<List<TechnicianBagStockItem>> {
  const TechnicianBagStockProvider._({
    required TechnicianBagStockFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'technicianBagStockProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$technicianBagStockHash();

  @override
  String toString() {
    return r'technicianBagStockProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TechnicianBagStockItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TechnicianBagStockItem>> create(Ref ref) {
    final argument = this.argument as String;
    return technicianBagStock(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TechnicianBagStockProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$technicianBagStockHash() =>
    r'bca5ddf78eedd875d303c3e02f67035ad56613d9';

final class TechnicianBagStockFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<TechnicianBagStockItem>>,
          String
        > {
  const TechnicianBagStockFamily._()
    : super(
        retry: null,
        name: r'technicianBagStockProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TechnicianBagStockProvider call(String technicianId) =>
      TechnicianBagStockProvider._(argument: technicianId, from: this);

  @override
  String toString() => r'technicianBagStockProvider';
}

@ProviderFor(stockMovements)
const stockMovementsProvider = StockMovementsFamily._();

final class StockMovementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StockMovement>>,
          List<StockMovement>,
          FutureOr<List<StockMovement>>
        >
    with
        $FutureModifier<List<StockMovement>>,
        $FutureProvider<List<StockMovement>> {
  const StockMovementsProvider._({
    required StockMovementsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'stockMovementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stockMovementsHash();

  @override
  String toString() {
    return r'stockMovementsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<StockMovement>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StockMovement>> create(Ref ref) {
    final argument = this.argument as String?;
    return stockMovements(ref, productId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StockMovementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stockMovementsHash() => r'f4bfa9808eb6b4e223050bbd9e9b0b5cc98a7425';

final class StockMovementsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<StockMovement>>, String?> {
  const StockMovementsFamily._()
    : super(
        retry: null,
        name: r'stockMovementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StockMovementsProvider call({String? productId}) =>
      StockMovementsProvider._(argument: productId, from: this);

  @override
  String toString() => r'stockMovementsProvider';
}
