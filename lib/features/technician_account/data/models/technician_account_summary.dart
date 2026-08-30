import 'package:freezed_annotation/freezed_annotation.dart';

part 'technician_account_summary.freezed.dart';

@freezed
abstract class TechnicianAccountSummary with _$TechnicianAccountSummary {
  const factory TechnicianAccountSummary({
    required String technicianId,
    required String technicianName,
    required double bagValue,
    required double totalSales,
    required double totalCollected,
    required double amountDue,
  }) = _TechnicianAccountSummary;

  factory TechnicianAccountSummary.fromRow(Map<String, dynamic> row) => TechnicianAccountSummary(
        technicianId: row['technician_id'] as String,
        technicianName: row['technician_name'] as String,
        bagValue: (row['bag_value'] as num).toDouble(),
        totalSales: (row['total_sales'] as num).toDouble(),
        totalCollected: (row['total_collected'] as num).toDouble(),
        amountDue: (row['amount_due'] as num).toDouble(),
      );
}
