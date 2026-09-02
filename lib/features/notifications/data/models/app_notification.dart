import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String type,
    required String title,
    String? body,
    required Map<String, dynamic> data,
    required bool isRead,
    required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromRow(Map<String, dynamic> row) => AppNotification(
        id: row['id'] as String,
        type: row['type'] as String,
        title: row['title'] as String,
        body: row['body'] as String?,
        data: Map<String, dynamic>.from(row['data'] as Map? ?? {}),
        isRead: row['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}

/// Maps a notification `type` (see notify_user()/notify_all_admins() calls
/// in 0010_functions_triggers.sql) to an icon for the list UI.
const Map<String, String> notificationTypeIcons = {
  'order_status': 'receipt_long',
  'maintenance_new': 'build',
  'maintenance_completed': 'check_circle',
  'low_stock': 'inventory_2',
};
