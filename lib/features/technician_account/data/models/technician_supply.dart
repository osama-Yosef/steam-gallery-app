import 'package:freezed_annotation/freezed_annotation.dart';

part 'technician_supply.freezed.dart';

/// A technician's own supply entry waits as [pending] until an admin confirms
/// the cash actually arrived; only then does it touch either ledger (see
/// 0030_finance_and_workflow_fixes_p1.sql). Supplies an admin records are
/// [confirmed] from the start.
enum SupplyStatus { pending, confirmed, rejected }

SupplyStatus supplyStatusFromString(String v) => switch (v) {
  'pending' => SupplyStatus.pending,
  'rejected' => SupplyStatus.rejected,
  _ => SupplyStatus.confirmed,
};

String supplyStatusLabelAr(SupplyStatus s) => switch (s) {
  SupplyStatus.pending => 'بانتظار تأكيد الإدارة',
  SupplyStatus.confirmed => 'مؤكَّد',
  SupplyStatus.rejected => 'مرفوض',
};

@freezed
abstract class TechnicianSupply with _$TechnicianSupply {
  const factory TechnicianSupply({
    required String id,
    required int supplyNumber,
    required String technicianId,
    required double amount,
    required SupplyStatus status,
    String? notes,
    String? rejectionReason,
    required DateTime createdAt,
  }) = _TechnicianSupply;

  factory TechnicianSupply.fromRow(Map<String, dynamic> row) =>
      TechnicianSupply(
        id: row['id'] as String,
        supplyNumber: row['supply_number'] as int,
        technicianId: row['technician_id'] as String,
        amount: (row['amount'] as num).toDouble(),
        status: supplyStatusFromString(row['status'] as String),
        notes: row['notes'] as String?,
        rejectionReason: row['rejection_reason'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
