import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';

part 'notification_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) {
  return SupabaseNotificationRepository(ref.watch(supabaseClientProvider));
}

@Riverpod(keepAlive: true)
Stream<List<AppNotification>> myNotifications(Ref ref) {
  return ref.watch(notificationRepositoryProvider).watchMyNotifications();
}

@riverpod
int unreadNotificationCount(Ref ref) {
  final list = ref.watch(myNotificationsProvider).value ?? const [];
  return list.where((n) => !n.isRead).length;
}
