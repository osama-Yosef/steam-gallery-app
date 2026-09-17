import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/payment_models.dart';

abstract class PaymentRepository {
  Future<InstapayDetails> getInstapayDetails();

  /// Customer's own payment history (any channel), newest first.
  Future<List<PaymentRecord>> getMyPayments();

  /// Uploads the screenshot to the customer's own folder in the private
  /// `payment_proofs` bucket and returns the object PATH (never a public
  /// URL — the bucket is private; see [signedProofUrl]).
  Future<String> uploadProof(Uint8List bytes, String ext);

  Future<String> signedProofUrl(String path);

  /// [clientRequestId] must stay the same across retries of the SAME
  /// submission attempt (idempotency, same convention as checkout).
  Future<String> submitInstapayPayment({
    required String orderId,
    required double amount,
    required String reference,
    required String proofPath,
    required String clientRequestId,
  });

  // Admin
  Future<List<PaymentRecord>> getPendingInstapaySubmissions();
  Future<void> verifyInstapayPayment({
    required String paymentId,
    required bool approve,
    String? rejectionReason,
  });
  Future<void> setInstapaySettings({
    required String ipaAddress,
    required String beneficiaryName,
  });
}

class SupabasePaymentRepository implements PaymentRepository {
  final SupabaseClient _client;
  SupabasePaymentRepository(this._client);

  static const _bucket = 'payment_proofs';

  @override
  Future<InstapayDetails> getInstapayDetails() async {
    try {
      final res = await _client.rpc('rpc_get_instapay_details');
      return InstapayDetails.fromRpc(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<PaymentRecord>> getMyPayments() async {
    try {
      final rows = await _client
          .from('payments')
          .select()
          .order('created_at', ascending: false);
      return rows.map(PaymentRecord.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<String> uploadProof(Uint8List bytes, String ext) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw const AppException('لازم تسجّل الدخول الأول');
      final path = '$uid/${const Uuid().v4()}.$ext';
      await _client.storage.from(_bucket).uploadBinary(path, bytes);
      return path;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<String> signedProofUrl(String path) async {
    try {
      return await _client.storage
          .from(_bucket)
          .createSignedUrl(path, const Duration(hours: 1).inSeconds);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<String> submitInstapayPayment({
    required String orderId,
    required double amount,
    required String reference,
    required String proofPath,
    required String clientRequestId,
  }) async {
    try {
      final id = await _client.rpc(
        'rpc_submit_instapay_payment',
        params: {
          'p_order_id': orderId,
          'p_amount': amount,
          'p_reference': reference,
          'p_proof_path': proofPath,
          'p_client_request_id': clientRequestId,
        },
      );
      return id as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<PaymentRecord>> getPendingInstapaySubmissions() async {
    try {
      final rows = await _client
          .from('payments')
          .select()
          .eq('channel', 'instapay')
          .eq('status', 'pending_verification')
          .order('created_at');
      return rows.map(PaymentRecord.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> verifyInstapayPayment({
    required String paymentId,
    required bool approve,
    String? rejectionReason,
  }) async {
    try {
      await _client.rpc(
        'rpc_admin_verify_instapay',
        params: {
          'p_payment_id': paymentId,
          'p_approve': approve,
          'p_rejection_reason': rejectionReason,
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> setInstapaySettings({
    required String ipaAddress,
    required String beneficiaryName,
  }) async {
    try {
      await _client.rpc(
        'rpc_admin_set_text_setting',
        params: {'p_key': 'instapay_ipa_address', 'p_value': ipaAddress},
      );
      await _client.rpc(
        'rpc_admin_set_text_setting',
        params: {
          'p_key': 'instapay_beneficiary_name',
          'p_value': beneficiaryName,
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
