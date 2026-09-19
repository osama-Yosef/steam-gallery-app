import 'package:freezed_annotation/freezed_annotation.dart';

part 'cashbox_balance.freezed.dart';

/// 'cash' (physical till) or 'transfer' (bank/card money) — 0059 split the
/// single cashbox into these two so every money movement can say which one
/// it actually touched.
enum CashboxKind { cash, transfer }

CashboxKind cashboxKindFromString(String v) => switch (v) {
  'transfer' => CashboxKind.transfer,
  _ => CashboxKind.cash,
};

String cashboxKindToString(CashboxKind k) => switch (k) {
  CashboxKind.cash => 'cash',
  CashboxKind.transfer => 'transfer',
};

String cashboxKindLabelAr(CashboxKind k) => switch (k) {
  CashboxKind.cash => 'الخزنة النقدية',
  CashboxKind.transfer => 'خزنة التحويلات',
};

@freezed
abstract class CashboxBalance with _$CashboxBalance {
  const factory CashboxBalance({
    required String cashboxId,
    required String name,
    required double balance,
    required CashboxKind kind,
  }) = _CashboxBalance;

  factory CashboxBalance.fromRow(Map<String, dynamic> row) => CashboxBalance(
    cashboxId: row['cashbox_id'] as String,
    name: row['name'] as String,
    balance: (row['balance'] as num).toDouble(),
    kind: cashboxKindFromString(row['kind'] as String),
  );
}
