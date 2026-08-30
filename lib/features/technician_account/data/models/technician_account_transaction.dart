import 'package:freezed_annotation/freezed_annotation.dart';

part 'technician_account_transaction.freezed.dart';

enum TechAccountTxnType { saleCredit, supplyDebit, adjustment }

TechAccountTxnType techAccountTxnTypeFromString(String v) => switch (v) {
      'sale_credit' => TechAccountTxnType.saleCredit,
      'supply_debit' => TechAccountTxnType.supplyDebit,
      'adjustment' => TechAccountTxnType.adjustment,
      _ => TechAccountTxnType.adjustment,
    };

String techAccountTxnTypeLabelAr(TechAccountTxnType t) => switch (t) {
      TechAccountTxnType.saleCredit => 'تحصيل بيع (مطلوب توريده)',
      TechAccountTxnType.supplyDebit => 'توريد للخزنة',
      TechAccountTxnType.adjustment => 'تسوية',
    };

/// Whether this transaction increases (true) or decreases (false) what the
/// technician owes — drives the +/- sign and color in the history list.
bool techAccountTxnIncreasesDue(TechAccountTxnType t) => t != TechAccountTxnType.supplyDebit;

@freezed
abstract class TechnicianAccountTransaction with _$TechnicianAccountTransaction {
  const factory TechnicianAccountTransaction({
    required String id,
    required TechAccountTxnType type,
    required double amount,
    String? notes,
    required DateTime createdAt,
  }) = _TechnicianAccountTransaction;

  factory TechnicianAccountTransaction.fromRow(Map<String, dynamic> row) => TechnicianAccountTransaction(
        id: row['id'] as String,
        type: techAccountTxnTypeFromString(row['transaction_type'] as String),
        amount: (row['amount'] as num).toDouble(),
        notes: row['notes'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
