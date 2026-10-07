// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_account_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(customerAccountRepository)
const customerAccountRepositoryProvider = CustomerAccountRepositoryProvider._();

final class CustomerAccountRepositoryProvider
    extends
        $FunctionalProvider<
          CustomerAccountRepository,
          CustomerAccountRepository,
          CustomerAccountRepository
        >
    with $Provider<CustomerAccountRepository> {
  const CustomerAccountRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customerAccountRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customerAccountRepositoryHash();

  @$internal
  @override
  $ProviderElement<CustomerAccountRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CustomerAccountRepository create(Ref ref) {
    return customerAccountRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomerAccountRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomerAccountRepository>(value),
    );
  }
}

String _$customerAccountRepositoryHash() =>
    r'9578ec23bd9b3afd66e00dc272ed82006ad8f760';

@ProviderFor(customerAccounts)
const customerAccountsProvider = CustomerAccountsFamily._();

final class CustomerAccountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CustomerAccountSummary>>,
          List<CustomerAccountSummary>,
          FutureOr<List<CustomerAccountSummary>>
        >
    with
        $FutureModifier<List<CustomerAccountSummary>>,
        $FutureProvider<List<CustomerAccountSummary>> {
  const CustomerAccountsProvider._({
    required CustomerAccountsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'customerAccountsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerAccountsHash();

  @override
  String toString() {
    return r'customerAccountsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CustomerAccountSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CustomerAccountSummary>> create(Ref ref) {
    final argument = this.argument as String?;
    return customerAccounts(ref, search: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerAccountsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerAccountsHash() => r'71271b4a780ca93503f06370fa2b23da95edefa8';

final class CustomerAccountsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<CustomerAccountSummary>>,
          String?
        > {
  const CustomerAccountsFamily._()
    : super(
        retry: null,
        name: r'customerAccountsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomerAccountsProvider call({String? search}) =>
      CustomerAccountsProvider._(argument: search, from: this);

  @override
  String toString() => r'customerAccountsProvider';
}

@ProviderFor(customerAccountSummary)
const customerAccountSummaryProvider = CustomerAccountSummaryFamily._();

final class CustomerAccountSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CustomerAccountSummary?>,
          CustomerAccountSummary?,
          FutureOr<CustomerAccountSummary?>
        >
    with
        $FutureModifier<CustomerAccountSummary?>,
        $FutureProvider<CustomerAccountSummary?> {
  const CustomerAccountSummaryProvider._({
    required CustomerAccountSummaryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customerAccountSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerAccountSummaryHash();

  @override
  String toString() {
    return r'customerAccountSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CustomerAccountSummary?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CustomerAccountSummary?> create(Ref ref) {
    final argument = this.argument as String;
    return customerAccountSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerAccountSummaryProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerAccountSummaryHash() =>
    r'623565ea5971094b9af4021e300d42250f20a388';

final class CustomerAccountSummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CustomerAccountSummary?>, String> {
  const CustomerAccountSummaryFamily._()
    : super(
        retry: null,
        name: r'customerAccountSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomerAccountSummaryProvider call(String customerId) =>
      CustomerAccountSummaryProvider._(argument: customerId, from: this);

  @override
  String toString() => r'customerAccountSummaryProvider';
}

@ProviderFor(customerAccountTransactions)
const customerAccountTransactionsProvider =
    CustomerAccountTransactionsFamily._();

final class CustomerAccountTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CustomerAccountTransaction>>,
          List<CustomerAccountTransaction>,
          FutureOr<List<CustomerAccountTransaction>>
        >
    with
        $FutureModifier<List<CustomerAccountTransaction>>,
        $FutureProvider<List<CustomerAccountTransaction>> {
  const CustomerAccountTransactionsProvider._({
    required CustomerAccountTransactionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customerAccountTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customerAccountTransactionsHash();

  @override
  String toString() {
    return r'customerAccountTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CustomerAccountTransaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CustomerAccountTransaction>> create(Ref ref) {
    final argument = this.argument as String;
    return customerAccountTransactions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerAccountTransactionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customerAccountTransactionsHash() =>
    r'a9f6077f87997682588f8de6d6f1af68f58e20c5';

final class CustomerAccountTransactionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<CustomerAccountTransaction>>,
          String
        > {
  const CustomerAccountTransactionsFamily._()
    : super(
        retry: null,
        name: r'customerAccountTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CustomerAccountTransactionsProvider call(String customerId) =>
      CustomerAccountTransactionsProvider._(argument: customerId, from: this);

  @override
  String toString() => r'customerAccountTransactionsProvider';
}
