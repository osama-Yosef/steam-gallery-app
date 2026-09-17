import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_models.freezed.dart';

enum PaymentChannel { cashOnDelivery, gateway, instapay, wallet }

PaymentChannel paymentChannelFromString(String v) => switch (v) {
  'gateway' => PaymentChannel.gateway,
  'instapay' => PaymentChannel.instapay,
  'wallet' => PaymentChannel.wallet,
  _ => PaymentChannel.cashOnDelivery,
};

String paymentChannelLabelAr(PaymentChannel c) => switch (c) {
  PaymentChannel.cashOnDelivery => 'الدفع عند الاستلام',
  PaymentChannel.gateway => 'بطاقة / بوابة دفع',
  PaymentChannel.instapay => 'تحويل InstaPay',
  PaymentChannel.wallet => 'المحفظة',
};

/// Mirrors `payment_txn_status` (0038/0039). `pendingVerification` is
/// InstaPay-only: the customer says they paid, nobody has checked yet.
enum PaymentTxnStatus {
  pending,
  pendingVerification,
  processing,
  succeeded,
  failed,
  cancelled,
  refunded,
}

PaymentTxnStatus paymentTxnStatusFromString(String v) => switch (v) {
  'pending_verification' => PaymentTxnStatus.pendingVerification,
  'processing' => PaymentTxnStatus.processing,
  'succeeded' => PaymentTxnStatus.succeeded,
  'failed' => PaymentTxnStatus.failed,
  'cancelled' => PaymentTxnStatus.cancelled,
  'refunded' => PaymentTxnStatus.refunded,
  _ => PaymentTxnStatus.pending,
};

String paymentTxnStatusLabelAr(PaymentTxnStatus s) => switch (s) {
  PaymentTxnStatus.pending => 'قيد الإنشاء',
  PaymentTxnStatus.pendingVerification => 'بانتظار المراجعة',
  PaymentTxnStatus.processing => 'جاري التنفيذ',
  PaymentTxnStatus.succeeded => 'تم بنجاح',
  PaymentTxnStatus.failed => 'فشلت',
  PaymentTxnStatus.cancelled => 'ملغاة',
  PaymentTxnStatus.refunded => 'تم الاسترداد',
};

/// One row of `public.payments` (0038) — never a cost column, and the
/// customer only ever sees their own (RLS).
@freezed
abstract class PaymentRecord with _$PaymentRecord {
  const PaymentRecord._();

  const factory PaymentRecord({
    required String id,
    required String customerId,
    String? orderId,
    required PaymentChannel channel,
    String? provider,
    required double amount,
    required String currency,
    required PaymentTxnStatus status,
    String? providerReference,
    required Map<String, dynamic> metadata,
    required DateTime createdAt,
    DateTime? paidAt,
  }) = _PaymentRecord;

  factory PaymentRecord.fromRow(Map<String, dynamic> row) => PaymentRecord(
    id: row['id'] as String,
    customerId: row['customer_id'] as String,
    orderId: row['order_id'] as String?,
    channel: paymentChannelFromString(row['channel'] as String),
    provider: row['provider'] as String?,
    amount: (row['amount'] as num).toDouble(),
    currency: row['currency'] as String? ?? 'EGP',
    status: paymentTxnStatusFromString(row['status'] as String),
    providerReference: row['provider_reference'] as String?,
    metadata: Map<String, dynamic>.from(
      row['metadata'] as Map? ?? const {},
    ),
    createdAt: DateTime.parse(row['created_at'] as String),
    paidAt: row['paid_at'] == null
        ? null
        : DateTime.parse(row['paid_at'] as String),
  );

  /// Storage path of the uploaded proof screenshot (InstaPay only).
  String? get proofPath => metadata['proof_path'] as String?;
  String? get rejectionReason => metadata['rejection_reason'] as String?;
}

/// The business's own InstaPay handle, admin-configurable
/// (rpc_get_instapay_details / rpc_admin_set_text_setting, 0039).
@freezed
abstract class InstapayDetails with _$InstapayDetails {
  const factory InstapayDetails({
    required bool configured,
    String? ipaAddress,
    String? beneficiaryName,
  }) = _InstapayDetails;

  factory InstapayDetails.fromRpc(Map<String, dynamic> json) =>
      InstapayDetails(
        configured: json['configured'] as bool? ?? false,
        ipaAddress: json['ipa_address'] as String?,
        beneficiaryName: json['beneficiary_name'] as String?,
      );
}
