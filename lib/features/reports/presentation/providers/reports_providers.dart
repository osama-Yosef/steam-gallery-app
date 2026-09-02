import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/report_models.dart';
import '../../data/repositories/reports_repository.dart';

part 'reports_providers.g.dart';

@Riverpod(keepAlive: true)
ReportsRepository reportsRepository(Ref ref) {
  return SupabaseReportsRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<List<SalesPeriodSummary>> dailySales(Ref ref) {
  return ref.watch(reportsRepositoryProvider).getDailySales();
}

@riverpod
Future<List<SalesPeriodSummary>> monthlySales(Ref ref) {
  return ref.watch(reportsRepositoryProvider).getMonthlySales();
}

@riverpod
Future<double> warehouseStockValue(Ref ref) {
  return ref.watch(reportsRepositoryProvider).getWarehouseStockValue();
}

@riverpod
Future<List<LowStockProduct>> lowStockProducts(Ref ref) {
  return ref.watch(reportsRepositoryProvider).getLowStockProducts();
}

@riverpod
Future<List<TechnicianAccountReportRow>> technicianAccountsReport(Ref ref) {
  return ref.watch(reportsRepositoryProvider).getTechnicianAccounts();
}

@riverpod
Future<List<CustomerAccountReportRow>> customerAccountsReport(Ref ref) {
  return ref.watch(reportsRepositoryProvider).getCustomerAccounts();
}
