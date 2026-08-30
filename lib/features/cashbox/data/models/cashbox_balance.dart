import 'package:freezed_annotation/freezed_annotation.dart';

part 'cashbox_balance.freezed.dart';

@freezed
abstract class CashboxBalance with _$CashboxBalance {
  const factory CashboxBalance({
    required String cashboxId,
    required String name,
    required double balance,
  }) = _CashboxBalance;

  factory CashboxBalance.fromRow(Map<String, dynamic> row) => CashboxBalance(
        cashboxId: row['cashbox_id'] as String,
        name: row['name'] as String,
        balance: (row['balance'] as num).toDouble(),
      );
}
