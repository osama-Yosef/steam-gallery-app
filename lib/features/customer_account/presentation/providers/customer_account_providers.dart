import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/customer_account_summary.dart';
import '../../data/models/customer_account_transaction.dart';
import '../../data/repositories/customer_account_repository.dart';

part 'customer_account_providers.g.dart';

@Riverpod(keepAlive: true)
CustomerAccountRepository customerAccountRepository(Ref ref) {
  return SupabaseCustomerAccountRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<List<CustomerAccountSummary>> customerAccounts(Ref ref, {String? search}) {
  return ref.watch(customerAccountRepositoryProvider).getAllAccounts(search: search);
}

@riverpod
Future<CustomerAccountSummary?> customerAccountSummary(Ref ref, String customerId) {
  return ref.watch(customerAccountRepositoryProvider).getAccountSummary(customerId);
}

@riverpod
Future<List<CustomerAccountTransaction>> customerAccountTransactions(Ref ref, String customerId) {
  return ref.watch(customerAccountRepositoryProvider).getTransactions(customerId);
}
