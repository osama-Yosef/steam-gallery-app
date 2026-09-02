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
Future<SalesReport> salesReport(Ref ref, DateTime from, DateTime to) {
  return ref.watch(reportsRepositoryProvider).getSalesReport(from, to);
}

@riverpod
Future<ProfitReport> profitReport(Ref ref, DateTime from, DateTime to) {
  return ref.watch(reportsRepositoryProvider).getProfitReport(from, to);
}

@riverpod
Future<ExpensesReport> expensesReport(Ref ref, DateTime from, DateTime to) {
  return ref.watch(reportsRepositoryProvider).getExpensesReport(from, to);
}

@riverpod
Future<InventoryReport> inventoryReport(Ref ref, DateTime from, DateTime to) {
  return ref.watch(reportsRepositoryProvider).getInventoryReport(from, to);
}

typedef ReportRange = ({DateTime from, DateTime to});

/// Shared "من/إلى" filter across every report screen — defaults to
/// "this month so far". `to` is always exclusive (see repository's `.lt`).
@Riverpod(keepAlive: true)
class ReportDateRange extends _$ReportDateRange {
  @override
  ReportRange build() {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return (from: firstOfMonth, to: tomorrow);
  }

  void setRange(DateTime from, DateTime to) => state = (from: from, to: to);
}
