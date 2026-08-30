import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log_entry.freezed.dart';

@freezed
abstract class AuditLogEntry with _$AuditLogEntry {
  const factory AuditLogEntry({
    required String id,
    String? actorId,
    String? actorName,
    required String action,
    required String tableName,
    String? recordId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    required DateTime createdAt,
  }) = _AuditLogEntry;

  factory AuditLogEntry.fromRow(Map<String, dynamic> row) => AuditLogEntry(
        id: row['id'] as String,
        actorId: row['actor_id'] as String?,
        actorName: (row['users'] as Map?)?['full_name'] as String?,
        action: row['action'] as String,
        tableName: row['table_name'] as String,
        recordId: row['record_id'] as String?,
        oldData: (row['old_data'] as Map?)?.cast<String, dynamic>(),
        newData: (row['new_data'] as Map?)?.cast<String, dynamic>(),
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
