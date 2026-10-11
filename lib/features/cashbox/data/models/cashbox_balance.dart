import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../technician_account/data/models/sale.dart';

part 'cashbox_balance.freezed.dart';

/// The four tills (0080), in the order they are shown. `kind` is what every
/// RPC looks a till up by — one active till per kind:
///   * [cash]: خزنة الدرج — the counter drawer, where cash sales land
///   * [main]: الخزنة الرئيسية — the safe, filled by transfers/deposits
///   * [transfer]: حساب CIB — bank transfers and cards
///   * [wallet]: فودافون كاش — e-wallet transfers
enum CashboxKind { cash, main, transfer, wallet }

CashboxKind cashboxKindFromString(String v) => switch (v) {
  'main' => CashboxKind.main,
  'transfer' => CashboxKind.transfer,
  'wallet' => CashboxKind.wallet,
  _ => CashboxKind.cash,
};

String cashboxKindToString(CashboxKind k) => switch (k) {
  CashboxKind.cash => 'cash',
  CashboxKind.main => 'main',
  CashboxKind.transfer => 'transfer',
  CashboxKind.wallet => 'wallet',
};

String cashboxKindLabelAr(CashboxKind k) => switch (k) {
  CashboxKind.cash => 'خزنة الدرج',
  CashboxKind.main => 'الخزنة الرئيسية',
  CashboxKind.transfer => 'حساب CIB',
  CashboxKind.wallet => 'فودافون كاش',
};

/// The till a payment by [method] lands in — same mapping as
/// private.fn_till_kind() server-side.
CashboxKind cashboxKindForPayment(PaymentMethod method) => switch (method) {
  PaymentMethod.cash => CashboxKind.cash,
  PaymentMethod.wallet => CashboxKind.wallet,
  _ => CashboxKind.transfer,
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
