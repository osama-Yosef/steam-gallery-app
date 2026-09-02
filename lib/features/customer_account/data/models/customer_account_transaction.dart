import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_account_transaction.freezed.dart';

enum CustAccountTxnType { orderCharge, payment, returnCredit, adjustment }

CustAccountTxnType custAccountTxnTypeFromString(String v) => switch (v) {
      'order_charge' => CustAccountTxnType.orderCharge,
      'payment' => CustAccountTxnType.payment,
      'return_credit' => CustAccountTxnType.returnCredit,
      'adjustment' => CustAccountTxnType.adjustment,
      _ => CustAccountTxnType.adjustment,
    };

String custAccountTxnTypeLabelAr(CustAccountTxnType t) => switch (t) {
      CustAccountTxnType.orderCharge => 'قيمة طلب',
      CustAccountTxnType.payment => 'دفعة',
      CustAccountTxnType.returnCredit => 'مرتجع',
      CustAccountTxnType.adjustment => 'تسوية',
    };

@freezed
abstract class CustomerAccountTransaction with _$CustomerAccountTransaction {
  const factory CustomerAccountTransaction({
    required String id,
    required CustAccountTxnType type,
    required double amount,
    String? orderId,
    String? notes,
    required DateTime createdAt,
  }) = _CustomerAccountTransaction;

  factory CustomerAccountTransaction.fromRow(Map<String, dynamic> row) => CustomerAccountTransaction(
        id: row['id'] as String,
        type: custAccountTxnTypeFromString(row['transaction_type'] as String),
        amount: (row['amount'] as num).toDouble(),
        orderId: row['order_id'] as String?,
        notes: row['notes'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
