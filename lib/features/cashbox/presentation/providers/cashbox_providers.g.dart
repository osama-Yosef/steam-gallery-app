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

@ProviderFor(cashboxBalance)
const cashboxBalanceProvider = CashboxBalanceProvider._();

final class CashboxBalanceProvider
    extends
        $FunctionalProvider<
          AsyncValue<CashboxBalance?>,
          CashboxBalance?,
          FutureOr<CashboxBalance?>
        >
    with $FutureModifier<CashboxBalance?>, $FutureProvider<CashboxBalance?> {
  const CashboxBalanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cashboxBalanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cashboxBalanceHash();

  @$internal
  @override
  $FutureProviderElement<CashboxBalance?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CashboxBalance?> create(Ref ref) {
    return cashboxBalance(ref);
  }
}

String _$cashboxBalanceHash() => r'77aadc9b968dd881282ce6cdc729e7ebd39bbec1';

@ProviderFor(cashTransactions)
const cashTransactionsProvider = CashTransactionsProvider._();

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
  const CashTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cashTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cashTransactionsHash();

  @$internal
  @override
  $FutureProviderElement<List<CashTransaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CashTransaction>> create(Ref ref) {
    return cashTransactions(ref);
  }
}

String _$cashTransactionsHash() => r'1150335f73fcb680e26533586baa3a597443fe11';

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
