import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/cash_transaction.dart';
import '../../data/models/cashbox_balance.dart';
import '../../data/models/expense.dart';
import '../../data/models/expense_category.dart';
import '../../data/repositories/cashbox_repository.dart';
import '../../../../core/utils/provider_cache.dart';
import '../../../../core/offline/outbox.dart';

part 'cashbox_providers.g.dart';

@Riverpod(keepAlive: true)
CashboxRepository cashboxRepository(Ref ref) {
  return SupabaseCashboxRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(outboxProvider),
  );
}

@riverpod
Future<List<CashboxBalance>> cashboxBalances(Ref ref) {
  ref.cacheFor();
  ref.refreshOnServerChange();
  return ref.watch(cashboxRepositoryProvider).getBalances();
}

@riverpod
Future<List<CashTransaction>> cashTransactions(Ref ref, String? cashboxId) {
  ref.cacheFor();
  ref.refreshOnServerChange();
  return ref
      .watch(cashboxRepositoryProvider)
      .getCashTransactions(cashboxId: cashboxId);
}

@riverpod
Future<List<ExpenseCategory>> expenseCategories(Ref ref) {
  ref.cacheFor();
  return ref.watch(cashboxRepositoryProvider).getExpenseCategories();
}

@riverpod
Future<List<Expense>> expenses(Ref ref) {
  ref.cacheFor();
  ref.refreshOnServerChange();
  return ref.watch(cashboxRepositoryProvider).getExpenses();
}
