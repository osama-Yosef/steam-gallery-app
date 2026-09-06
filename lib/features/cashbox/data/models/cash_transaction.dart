import 'package:freezed_annotation/freezed_annotation.dart';

part 'cash_transaction.freezed.dart';

enum CashTxnType {
  sale,
  technicianDeposit,
  expense,
  refund,
  adjustment,
  purchase,
  otherIncome,
  otherExpense,
}

CashTxnType cashTxnTypeFromString(String v) => switch (v) {
  'sale' => CashTxnType.sale,
  'technician_deposit' => CashTxnType.technicianDeposit,
  'expense' => CashTxnType.expense,
  'refund' => CashTxnType.refund,
  'adjustment' => CashTxnType.adjustment,
  'purchase' => CashTxnType.purchase,
  'other_income' => CashTxnType.otherIncome,
  'other_expense' => CashTxnType.otherExpense,
  _ => CashTxnType.adjustment,
};

String cashTxnTypeLabelAr(CashTxnType t) => switch (t) {
  CashTxnType.sale => 'بيع',
  CashTxnType.technicianDeposit => 'توريد صنايعي',
  CashTxnType.expense => 'مصروف',
  CashTxnType.refund => 'استرداد',
  CashTxnType.adjustment => 'تسوية',
  CashTxnType.purchase => 'شراء',
  // These two are what rpc_cashbox_deposit / rpc_cashbox_withdraw record;
  // they move the till balance only and never reach the profit reports.
  CashTxnType.otherIncome => 'إيداع نقدي',
  CashTxnType.otherExpense => 'سحب نقدي',
};

@freezed
abstract class CashTransaction with _$CashTransaction {
  const factory CashTransaction({
    required String id,
    required CashTxnType type,
    required double amount,
    String? referenceType,
    String? notes,
    required DateTime createdAt,
  }) = _CashTransaction;

  factory CashTransaction.fromRow(Map<String, dynamic> row) => CashTransaction(
    id: row['id'] as String,
    type: cashTxnTypeFromString(row['transaction_type'] as String),
    amount: (row['amount'] as num).toDouble(),
    referenceType: row['reference_type'] as String?,
    notes: row['notes'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
