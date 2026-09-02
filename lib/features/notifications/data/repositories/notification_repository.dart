import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/app_notification.dart';

abstract class NotificationRepository {
  /// RLS already scopes this to `user_id = auth.uid()` — see
  /// 0011_rls_policies.sql — so every role gets only their own notifications
  /// through the exact same query.
  Stream<List<AppNotification>> watchMyNotifications();

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead(String userId);
}

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _client;
  SupabaseNotificationRepository(this._client);

  @override
  Stream<List<AppNotification>> watchMyNotifications() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(AppNotification.fromRow).toList());
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
