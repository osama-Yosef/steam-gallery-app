import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/sale.dart';
import '../../data/models/sale_item.dart';
import '../../data/models/technician_account_summary.dart';
import '../../data/models/technician_account_transaction.dart';
import '../../data/repositories/technician_account_repository.dart';

part 'technician_account_providers.g.dart';

@Riverpod(keepAlive: true)
TechnicianAccountRepository technicianAccountRepository(Ref ref) {
  return SupabaseTechnicianAccountRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<TechnicianAccountSummary?> technicianAccountSummary(
  Ref ref,
  String technicianId,
) {
  return ref
      .watch(technicianAccountRepositoryProvider)
      .getAccountSummary(technicianId);
}

@riverpod
Future<List<TechnicianAccountSummary>> allTechnicianAccountSummaries(Ref ref) {
  return ref
      .watch(technicianAccountRepositoryProvider)
      .getAllAccountSummaries();
}

@riverpod
Future<List<TechnicianAccountTransaction>> technicianAccountTransactions(
  Ref ref,
  String technicianId,
) {
  return ref
      .watch(technicianAccountRepositoryProvider)
      .getAccountTransactions(technicianId);
}

@riverpod
Future<List<Sale>> technicianSales(Ref ref, String technicianId) {
  return ref.watch(technicianAccountRepositoryProvider).getSales(technicianId);
}

@riverpod
Future<Sale?> technicianSaleDetail(Ref ref, String saleId) {
  return ref.watch(technicianAccountRepositoryProvider).getSaleById(saleId);
}

@riverpod
Future<List<SaleItem>> saleItems(Ref ref, String saleId) {
  return ref.watch(technicianAccountRepositoryProvider).getSaleItems(saleId);
}
