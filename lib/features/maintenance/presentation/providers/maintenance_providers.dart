import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/maintenance_image.dart';
import '../../data/models/maintenance_request.dart';
import '../../data/models/queue_position.dart';
import '../../data/models/technician_option.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../../../core/utils/provider_cache.dart';

import '../../../../core/utils/history_query.dart';
part 'maintenance_providers.g.dart';

@Riverpod(keepAlive: true)
MaintenanceRepository maintenanceRepository(Ref ref) {
  return SupabaseMaintenanceRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Stream<List<MaintenanceRequest>> myMaintenanceRequests(
  Ref ref,
  String customerId,
) {
  return ref.watch(maintenanceRepositoryProvider).watchMyRequests(customerId);
}

@riverpod
Stream<MaintenanceRequest?> maintenanceRequestDetail(
  Ref ref,
  String requestId,
) {
  return ref.watch(maintenanceRepositoryProvider).watchRequest(requestId);
}

/// The open maintenance requests (plus today's), live, RLS-scoped — every
/// queue screen (technician/admin) derives its sorted "active" list from it
/// client-side; see the repository doc comment.
@Riverpod(keepAlive: true)
Stream<List<MaintenanceRequest>> openMaintenanceRequests(Ref ref) {
  return ref.watch(maintenanceRepositoryProvider).watchOpenRequests();
}

/// The maintenance history screen's results for one [HistoryQuery]: the
/// first page loads on watch, [loadMore] appends the next.
@riverpod
class MaintenanceHistory extends _$MaintenanceHistory {
  @override
  Future<HistoryPage<MaintenanceRequest>> build(HistoryQuery query) async {
    final items = await ref
        .watch(maintenanceRepositoryProvider)
        .searchRequests(query, limit: historyPageSize, offset: 0);
    return HistoryPage(items: items, hasMore: items.length == historyPageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final next = await ref
          .read(maintenanceRepositoryProvider)
          .searchRequests(
            query,
            limit: historyPageSize,
            offset: current.items.length,
          );
      if (ref.mounted) state = AsyncData(current.append(next, historyPageSize));
    } catch (_) {
      if (ref.mounted) {
        state = AsyncData(
          current.copyWith(loadingMore: false, loadMoreFailed: true),
        );
      }
    }
  }
}

@riverpod
Future<QueuePosition> myQueuePosition(Ref ref, String requestId) {
  return ref.watch(maintenanceRepositoryProvider).myQueuePosition(requestId);
}

@riverpod
Future<List<MaintenanceImage>> maintenanceImages(Ref ref, String requestId) {
  return ref.watch(maintenanceRepositoryProvider).getImages(requestId);
}

/// Signed, time-limited URL for one stored maintenance image. The bucket is
/// private, so this is the only way the image can actually render.
@riverpod
Future<String> maintenanceImageUrl(Ref ref, String storedPathOrUrl) {
  ref.cacheFor(
    keep: const Duration(minutes: 30),
    staleAfter: const Duration(minutes: 30),
  );
  return ref
      .watch(maintenanceRepositoryProvider)
      .signedImageUrl(storedPathOrUrl);
}

@riverpod
Future<List<TechnicianOption>> assignableTechnicians(Ref ref) {
  ref.cacheFor();
  return ref.watch(maintenanceRepositoryProvider).listTechnicians();
}
