import 'package:freezed_annotation/freezed_annotation.dart';

part 'queue_position.freezed.dart';

/// Mirrors the row shape of rpc_my_maintenance_position().
@freezed
abstract class QueuePosition with _$QueuePosition {
  const factory QueuePosition({
    required int position,
    required int peopleAhead,
    required int totalActive,
  }) = _QueuePosition;

  factory QueuePosition.fromRow(Map<String, dynamic> row) => QueuePosition(
        position: row['queue_position'] as int,
        peopleAhead: row['people_ahead'] as int,
        totalActive: row['total_active'] as int,
      );
}
