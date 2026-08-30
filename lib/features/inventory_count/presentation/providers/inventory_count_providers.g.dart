// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_count_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inventoryCountRepository)
const inventoryCountRepositoryProvider = InventoryCountRepositoryProvider._();

final class InventoryCountRepositoryProvider
    extends
        $FunctionalProvider<
          InventoryCountRepository,
          InventoryCountRepository,
          InventoryCountRepository
        >
    with $Provider<InventoryCountRepository> {
  const InventoryCountRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryCountRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryCountRepositoryHash();

  @$internal
  @override
  $ProviderElement<InventoryCountRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryCountRepository create(Ref ref) {
    return inventoryCountRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryCountRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryCountRepository>(value),
    );
  }
}

String _$inventoryCountRepositoryHash() =>
    r'8d48f673eba5704e2dded6193c744daa347de343';

@ProviderFor(inventoryCounts)
const inventoryCountsProvider = InventoryCountsProvider._();

final class InventoryCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryCount>>,
          List<InventoryCount>,
          FutureOr<List<InventoryCount>>
        >
    with
        $FutureModifier<List<InventoryCount>>,
        $FutureProvider<List<InventoryCount>> {
  const InventoryCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryCountsHash();

  @$internal
  @override
  $FutureProviderElement<List<InventoryCount>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InventoryCount>> create(Ref ref) {
    return inventoryCounts(ref);
  }
}

String _$inventoryCountsHash() => r'a5f13ffd8c7c24977321962ec087cca7824ef8a4';

@ProviderFor(inventoryCountDetail)
const inventoryCountDetailProvider = InventoryCountDetailFamily._();

final class InventoryCountDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<InventoryCount?>,
          InventoryCount?,
          FutureOr<InventoryCount?>
        >
    with $FutureModifier<InventoryCount?>, $FutureProvider<InventoryCount?> {
  const InventoryCountDetailProvider._({
    required InventoryCountDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inventoryCountDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inventoryCountDetailHash();

  @override
  String toString() {
    return r'inventoryCountDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<InventoryCount?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InventoryCount?> create(Ref ref) {
    final argument = this.argument as String;
    return inventoryCountDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryCountDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inventoryCountDetailHash() =>
    r'cf6e89d3dfaa818493fa982b2860f77e4ac0c845';

final class InventoryCountDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<InventoryCount?>, String> {
  const InventoryCountDetailFamily._()
    : super(
        retry: null,
        name: r'inventoryCountDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InventoryCountDetailProvider call(String countId) =>
      InventoryCountDetailProvider._(argument: countId, from: this);

  @override
  String toString() => r'inventoryCountDetailProvider';
}

@ProviderFor(inventoryCountItems)
const inventoryCountItemsProvider = InventoryCountItemsFamily._();

final class InventoryCountItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryCountItem>>,
          List<InventoryCountItem>,
          FutureOr<List<InventoryCountItem>>
        >
    with
        $FutureModifier<List<InventoryCountItem>>,
        $FutureProvider<List<InventoryCountItem>> {
  const InventoryCountItemsProvider._({
    required InventoryCountItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inventoryCountItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inventoryCountItemsHash();

  @override
  String toString() {
    return r'inventoryCountItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<InventoryCountItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InventoryCountItem>> create(Ref ref) {
    final argument = this.argument as String;
    return inventoryCountItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryCountItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inventoryCountItemsHash() =>
    r'2ffee495656cf5b5aea0d9769b9e11cf42c7b4e1';

final class InventoryCountItemsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<InventoryCountItem>>, String> {
  const InventoryCountItemsFamily._()
    : super(
        retry: null,
        name: r'inventoryCountItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InventoryCountItemsProvider call(String countId) =>
      InventoryCountItemsProvider._(argument: countId, from: this);

  @override
  String toString() => r'inventoryCountItemsProvider';
}
