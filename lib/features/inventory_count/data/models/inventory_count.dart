import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_count.freezed.dart';

enum InventoryCountStatus { draft, completed }

InventoryCountStatus inventoryCountStatusFromString(String v) => switch (v) {
      'draft' => InventoryCountStatus.draft,
      'completed' => InventoryCountStatus.completed,
      _ => InventoryCountStatus.draft,
    };

String inventoryCountStatusLabelAr(InventoryCountStatus s) => switch (s) {
      InventoryCountStatus.draft => 'مسودة',
      InventoryCountStatus.completed => 'مُعتمَد',
    };

@freezed
abstract class InventoryCount with _$InventoryCount {
  const factory InventoryCount({
    required String id,
    required int countNumber,
    required InventoryCountStatus status,
    required DateTime startedAt,
    DateTime? completedAt,
    String? notes,
  }) = _InventoryCount;

  factory InventoryCount.fromRow(Map<String, dynamic> row) => InventoryCount(
        id: row['id'] as String,
        countNumber: row['count_number'] as int,
        status: inventoryCountStatusFromString(row['status'] as String),
        startedAt: DateTime.parse(row['started_at'] as String),
        completedAt: row['completed_at'] == null ? null : DateTime.parse(row['completed_at'] as String),
        notes: row['notes'] as String?,
      );
}
