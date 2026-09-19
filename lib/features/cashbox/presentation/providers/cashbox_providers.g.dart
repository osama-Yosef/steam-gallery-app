// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cashbox_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cashboxRepository)
const cashboxRepositoryProvider = CashboxRepositoryProvider._();

final class CashboxRepositoryProvider
    extends
        $FunctionalProvider<
          CashboxRepository,
          CashboxRepository,
          CashboxRepository
        >
    with $Provider<CashboxRepository> {
  const CashboxRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cashboxRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cashboxRepositoryHash();

  @$internal
  @override
  $ProviderElement<CashboxRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CashboxRepository create(Ref ref) {
    return cashboxRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CashboxRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CashboxRepository>(value),
    );
  }
}

String _$cashboxRepositoryHash() => r'27bce8e0f5544a2f992815c34dafa1411ce65bc8';

@ProviderFor(cashboxBalances)
const cashboxBalancesProvider = CashboxBalancesProvider._();

final class CashboxBalancesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CashboxBalance>>,
          List<CashboxBalance>,
          FutureOr<List<CashboxBalance>>
        >
    with
        $FutureModifier<List<CashboxBalance>>,
        $FutureProvider<List<CashboxBalance>> {
  const CashboxBalancesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cashboxBalancesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cashboxBalancesHash();

  @$internal
  @override
  $FutureProviderElement<List<CashboxBalance>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CashboxBalance>> create(Ref ref) {
    return cashboxBalances(ref);
  }
}

String _$cashboxBalancesHash() => r'de31c58e5d9dbfe3df51d92a3c36fc99949e7076';

@ProviderFor(cashTransactions)
const cashTransactionsProvider = CashTransactionsFamily._();

final class CashTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CashTransaction>>,
          List<CashTransaction>,
          FutureOr<List<CashTransaction>>
        >
    with
        $FutureModifier<List<CashTransaction>>,
        $FutureProvider<List<CashTransaction>> {
  const CashTransactionsProvider._({
    required CashTransactionsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'cashTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cashTransactionsHash();

  @override
  String toString() {
    return r'cashTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CashTransaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CashTransaction>> create(Ref ref) {
    final argument = this.argument as String?;
    return cashTransactions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CashTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cashTransactionsHash() => r'9600b6babf27e9574a3e025bd1b1d0bcb6c67e57';

final class CashTransactionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CashTransaction>>, String?> {
  const CashTransactionsFamily._()
    : super(
        retry: null,
        name: r'cashTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CashTransactionsProvider call(String? cashboxId) =>
      CashTransactionsProvider._(argument: cashboxId, from: this);

  @override
  String toString() => r'cashTransactionsProvider';
}

@ProviderFor(expenseCategories)
const expenseCategoriesProvider = ExpenseCategoriesProvider._();

final class ExpenseCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ExpenseCategory>>,
          List<ExpenseCategory>,
          FutureOr<List<ExpenseCategory>>
        >
    with
        $FutureModifier<List<ExpenseCategory>>,
        $FutureProvider<List<ExpenseCategory>> {
  const ExpenseCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseCategoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<ExpenseCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ExpenseCategory>> create(Ref ref) {
    return expenseCategories(ref);
  }
}

String _$expenseCategoriesHash() => r'5b2d941c6de00b13b6b2b66b17779d93fea8717d';

@ProviderFor(expenses)
const expensesProvider = ExpensesProvider._();

final class ExpensesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Expense>>,
          List<Expense>,
          FutureOr<List<Expense>>
        >
    with $FutureModifier<List<Expense>>, $FutureProvider<List<Expense>> {
  const ExpensesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expensesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expensesHash();

  @$internal
  @override
  $FutureProviderElement<List<Expense>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Expense>> create(Ref ref) {
    return expenses(ref);
  }
}

String _$expensesHash() => r'59185a67c979f3839f0bbe3f89b338191a85842f';
