import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/dashboard_summary.dart';
import '../../data/repositories/dashboard_repository.dart';

part 'dashboard_providers.g.dart';

@Riverpod(keepAlive: true)
DashboardRepository dashboardRepository(Ref ref) {
  return SupabaseDashboardRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref) {
  return ref.watch(dashboardRepositoryProvider).getSummary();
}

@riverpod
Future<List<DailyRevenuePoint>> dashboardRevenueTrend(Ref ref) {
  return ref.watch(dashboardRepositoryProvider).getRevenueTrend();
}
