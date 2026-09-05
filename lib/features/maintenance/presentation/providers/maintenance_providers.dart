import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/maintenance_image.dart';
import '../../data/models/maintenance_request.dart';
import '../../data/models/queue_position.dart';
import '../../data/models/technician_option.dart';
import '../../data/repositories/maintenance_repository.dart';

part 'maintenance_providers.g.dart';

@Riverpod(keepAlive: true)
MaintenanceRepository maintenanceRepository(Ref ref) {
  return SupabaseMaintenanceRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Stream<List<MaintenanceRequest>> myMaintenanceRequests(Ref ref, String customerId) {
  return ref.watch(maintenanceRepositoryProvider).watchMyRequests(customerId);
}

@riverpod
Stream<MaintenanceRequest?> maintenanceRequestDetail(Ref ref, String requestId) {
  return ref.watch(maintenanceRepositoryProvider).watchRequest(requestId);
}

/// Raw RLS-scoped stream every queue screen (technician/admin) derives its
/// sorted "active" list from client-side — see repository doc comment.
@Riverpod(keepAlive: true)
Stream<List<MaintenanceRequest>> visibleMaintenanceRequests(Ref ref) {
  return ref.watch(maintenanceRepositoryProvider).watchVisibleRequests();
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
  return ref.watch(maintenanceRepositoryProvider).signedImageUrl(storedPathOrUrl);
}

@riverpod
Future<List<TechnicianOption>> assignableTechnicians(Ref ref) {
  return ref.watch(maintenanceRepositoryProvider).listTechnicians();
}
