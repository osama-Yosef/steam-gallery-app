import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/cash_transaction.dart';
import '../../data/models/cashbox_balance.dart';
import '../../data/models/expense.dart';
import '../../data/models/expense_category.dart';
import '../../data/repositories/cashbox_repository.dart';

part 'cashbox_providers.g.dart';

@Riverpod(keepAlive: true)
CashboxRepository cashboxRepository(Ref ref) {
  return SupabaseCashboxRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<CashboxBalance?> cashboxBalance(Ref ref) {
  return ref.watch(cashboxRepositoryProvider).getBalance();
}

@riverpod
Future<List<CashTransaction>> cashTransactions(Ref ref) {
  return ref.watch(cashboxRepositoryProvider).getCashTransactions();
}

@riverpod
Future<List<ExpenseCategory>> expenseCategories(Ref ref) {
  return ref.watch(cashboxRepositoryProvider).getExpenseCategories();
}

@riverpod
Future<List<Expense>> expenses(Ref ref) {
  return ref.watch(cashboxRepositoryProvider).getExpenses();
}
