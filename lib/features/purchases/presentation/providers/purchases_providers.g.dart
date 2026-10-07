// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchases_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(purchasesRepository)
const purchasesRepositoryProvider = PurchasesRepositoryProvider._();

final class PurchasesRepositoryProvider
    extends
        $FunctionalProvider<
          PurchasesRepository,
          PurchasesRepository,
          PurchasesRepository
        >
    with $Provider<PurchasesRepository> {
  const PurchasesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchasesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchasesRepositoryHash();

  @$internal
  @override
  $ProviderElement<PurchasesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PurchasesRepository create(Ref ref) {
    return purchasesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurchasesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurchasesRepository>(value),
    );
  }
}

String _$purchasesRepositoryHash() =>
    r'6fcd59acf26f00bb44d43f2327afd45b8ba11559';

@ProviderFor(suppliers)
const suppliersProvider = SuppliersProvider._();

final class SuppliersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SupplierBalance>>,
          List<SupplierBalance>,
          FutureOr<List<SupplierBalance>>
        >
    with
        $FutureModifier<List<SupplierBalance>>,
        $FutureProvider<List<SupplierBalance>> {
  const SuppliersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'suppliersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$suppliersHash();

  @$internal
  @override
  $FutureProviderElement<List<SupplierBalance>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SupplierBalance>> create(Ref ref) {
    return suppliers(ref);
  }
}

String _$suppliersHash() => r'c99c96749fbcd03da11088dc1207fc62ed077423';

@ProviderFor(purchaseInvoices)
const purchaseInvoicesProvider = PurchaseInvoicesFamily._();

final class PurchaseInvoicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PurchaseInvoice>>,
          List<PurchaseInvoice>,
          FutureOr<List<PurchaseInvoice>>
        >
    with
        $FutureModifier<List<PurchaseInvoice>>,
        $FutureProvider<List<PurchaseInvoice>> {
  const PurchaseInvoicesProvider._({
    required PurchaseInvoicesFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'purchaseInvoicesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$purchaseInvoicesHash();

  @override
  String toString() {
    return r'purchaseInvoicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PurchaseInvoice>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PurchaseInvoice>> create(Ref ref) {
    final argument = this.argument as String?;
    return purchaseInvoices(ref, supplierId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PurchaseInvoicesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$purchaseInvoicesHash() => r'fda6463b9075fc6ba5f7900036cd61b2889bef59';

final class PurchaseInvoicesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PurchaseInvoice>>, String?> {
  const PurchaseInvoicesFamily._()
    : super(
        retry: null,
        name: r'purchaseInvoicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PurchaseInvoicesProvider call({String? supplierId}) =>
      PurchaseInvoicesProvider._(argument: supplierId, from: this);

  @override
  String toString() => r'purchaseInvoicesProvider';
}

@ProviderFor(purchaseInvoice)
const purchaseInvoiceProvider = PurchaseInvoiceFamily._();

final class PurchaseInvoiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<PurchaseInvoice>,
          PurchaseInvoice,
          FutureOr<PurchaseInvoice>
        >
    with $FutureModifier<PurchaseInvoice>, $FutureProvider<PurchaseInvoice> {
  const PurchaseInvoiceProvider._({
    required PurchaseInvoiceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'purchaseInvoiceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$purchaseInvoiceHash();

  @override
  String toString() {
    return r'purchaseInvoiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PurchaseInvoice> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PurchaseInvoice> create(Ref ref) {
    final argument = this.argument as String;
    return purchaseInvoice(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PurchaseInvoiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$purchaseInvoiceHash() => r'fba6440c12698508604048012b676eddd595f4e6';

final class PurchaseInvoiceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PurchaseInvoice>, String> {
  const PurchaseInvoiceFamily._()
    : super(
        retry: null,
        name: r'purchaseInvoiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PurchaseInvoiceProvider call(String id) =>
      PurchaseInvoiceProvider._(argument: id, from: this);

  @override
  String toString() => r'purchaseInvoiceProvider';
}

@ProviderFor(purchaseInvoiceItems)
const purchaseInvoiceItemsProvider = PurchaseInvoiceItemsFamily._();

final class PurchaseInvoiceItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PurchaseInvoiceItem>>,
          List<PurchaseInvoiceItem>,
          FutureOr<List<PurchaseInvoiceItem>>
        >
    with
        $FutureModifier<List<PurchaseInvoiceItem>>,
        $FutureProvider<List<PurchaseInvoiceItem>> {
  const PurchaseInvoiceItemsProvider._({
    required PurchaseInvoiceItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'purchaseInvoiceItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$purchaseInvoiceItemsHash();

  @override
  String toString() {
    return r'purchaseInvoiceItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PurchaseInvoiceItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PurchaseInvoiceItem>> create(Ref ref) {
    final argument = this.argument as String;
    return purchaseInvoiceItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PurchaseInvoiceItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$purchaseInvoiceItemsHash() =>
    r'6c69cb2c2ac5fabc6f9aa903019b7e0ded1ce2c5';

final class PurchaseInvoiceItemsFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<PurchaseInvoiceItem>>, String> {
  const PurchaseInvoiceItemsFamily._()
    : super(
        retry: null,
        name: r'purchaseInvoiceItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PurchaseInvoiceItemsProvider call(String id) =>
      PurchaseInvoiceItemsProvider._(argument: id, from: this);

  @override
  String toString() => r'purchaseInvoiceItemsProvider';
}

@ProviderFor(purchaseInvoicePayments)
const purchaseInvoicePaymentsProvider = PurchaseInvoicePaymentsFamily._();

final class PurchaseInvoicePaymentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SupplierPayment>>,
          List<SupplierPayment>,
          FutureOr<List<SupplierPayment>>
        >
    with
        $FutureModifier<List<SupplierPayment>>,
        $FutureProvider<List<SupplierPayment>> {
  const PurchaseInvoicePaymentsProvider._({
    required PurchaseInvoicePaymentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'purchaseInvoicePaymentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$purchaseInvoicePaymentsHash();

  @override
  String toString() {
    return r'purchaseInvoicePaymentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SupplierPayment>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SupplierPayment>> create(Ref ref) {
    final argument = this.argument as String;
    return purchaseInvoicePayments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PurchaseInvoicePaymentsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$purchaseInvoicePaymentsHash() =>
    r'c5cdfa920c9597a70aba21480223e05c2cd65e47';

final class PurchaseInvoicePaymentsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SupplierPayment>>, String> {
  const PurchaseInvoicePaymentsFamily._()
    : super(
        retry: null,
        name: r'purchaseInvoicePaymentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PurchaseInvoicePaymentsProvider call(String id) =>
      PurchaseInvoicePaymentsProvider._(argument: id, from: this);

  @override
  String toString() => r'purchaseInvoicePaymentsProvider';
}
