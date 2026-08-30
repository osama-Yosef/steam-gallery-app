import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_account_summary.freezed.dart';

@freezed
abstract class CustomerAccountSummary with _$CustomerAccountSummary {
  const factory CustomerAccountSummary({
    required String customerId,
    required String customerName,
    required double totalPurchases,
    required double totalPaid,
    required double remainingBalance,
  }) = _CustomerAccountSummary;

  factory CustomerAccountSummary.fromRow(Map<String, dynamic> row) => CustomerAccountSummary(
        customerId: row['customer_id'] as String,
        customerName: row['customer_name'] as String,
        totalPurchases: (row['total_purchases'] as num).toDouble(),
        totalPaid: (row['total_paid'] as num).toDouble(),
        remainingBalance: (row['remaining_balance'] as num).toDouble(),
      );
}
