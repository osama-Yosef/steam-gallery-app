import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_models.freezed.dart';

/// The customer's own wallet — separate from customer_accounts (deferred
/// payment/debt), never merged (master prompt §5). Balance is always the
/// server's number; the app never computes or trusts its own total.
@freezed
abstract class Wallet with _$Wallet {
  const factory Wallet({
    required String id,
    required double balance,
    required String currency,
    required bool isActive,
  }) = _Wallet;

  static const empty = Wallet(
    id: '',
    balance: 0,
    currency: 'EGP',
    isActive: true,
  );

  factory Wallet.fromRpc(Map<String, dynamic> json) => Wallet(
    id: json['id'] as String,
    balance: (json['balance'] as num).toDouble(),
    currency: json['currency'] as String? ?? 'EGP',
    isActive: json['is_active'] as bool? ?? true,
  );
}

enum WalletTxnType { topup, debit, refundCredit, adjustment }

WalletTxnType walletTxnTypeFromString(String v) => switch (v) {
  'debit' => WalletTxnType.debit,
  'refund_credit' => WalletTxnType.refundCredit,
  'adjustment' => WalletTxnType.adjustment,
  _ => WalletTxnType.topup,
};

String walletTxnTypeLabelAr(WalletTxnType t) => switch (t) {
  WalletTxnType.topup => 'شحن رصيد',
  WalletTxnType.debit => 'دفع من المحفظة',
  WalletTxnType.refundCredit => 'استرداد إلى المحفظة',
  WalletTxnType.adjustment => 'تسوية',
};

/// One row of `wallet_summary` (0042) — the admin-only per-customer wallet
/// listing. Unlike [Wallet], this always carries whose wallet it is.
@freezed
abstract class WalletSummary with _$WalletSummary {
  const factory WalletSummary({
    required String walletId,
    required String customerId,
    required String customerName,
    required double balance,
    required String currency,
    required bool isActive,
  }) = _WalletSummary;

  factory WalletSummary.fromRow(Map<String, dynamic> row) => WalletSummary(
    walletId: row['wallet_id'] as String,
    customerId: row['customer_id'] as String,
    customerName: row['customer_name'] as String,
    balance: (row['balance'] as num).toDouble(),
    currency: row['currency'] as String? ?? 'EGP',
    isActive: row['is_active'] as bool? ?? true,
  );
}

/// One immutable row of `wallet_transactions` (0040).
@freezed
abstract class WalletTransaction with _$WalletTransaction {
  const factory WalletTransaction({
    required String id,
    required WalletTxnType type,
    required double amount,
    required double balanceBefore,
    required double balanceAfter,
    String? notes,
    required DateTime createdAt,
  }) = _WalletTransaction;

  factory WalletTransaction.fromRow(Map<String, dynamic> row) =>
      WalletTransaction(
        id: row['id'] as String,
        type: walletTxnTypeFromString(row['type'] as String),
        amount: (row['amount'] as num).toDouble(),
        balanceBefore: (row['balance_before'] as num).toDouble(),
        balanceAfter: (row['balance_after'] as num).toDouble(),
        notes: row['notes'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
}
