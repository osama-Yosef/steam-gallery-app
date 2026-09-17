import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/wallet_models.dart';

abstract class WalletRepository {
  /// Creates the wallet on first call (server-side, lazy — 0040).
  Future<Wallet> getMyWallet();

  Future<List<WalletTransaction>> getMyTransactions();

  /// [clientRequestId] must stay the same across retries of the SAME
  /// submission attempt.
  Future<String> topupViaInstapay({
    required double amount,
    required String reference,
    required String proofPath,
    required String clientRequestId,
  });

  Future<void> payOrderFromWallet({
    required String orderId,
    required double amount,
    required String clientRequestId,
  });

  // Admin (Phase 15)
  Future<List<WalletSummary>> getAllWallets({String? search});
  Future<({double totalLiability, int walletCount})> getLiabilitySummary();
}

class SupabaseWalletRepository implements WalletRepository {
  final SupabaseClient _client;
  SupabaseWalletRepository(this._client);

  @override
  Future<Wallet> getMyWallet() async {
    try {
      final res = await _client.rpc('rpc_get_my_wallet');
      return Wallet.fromRpc(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<WalletTransaction>> getMyTransactions() async {
    try {
      final rows = await _client
          .from('wallet_transactions')
          .select()
          .order('created_at', ascending: false);
      return rows.map(WalletTransaction.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<String> topupViaInstapay({
    required double amount,
    required String reference,
    required String proofPath,
    required String clientRequestId,
  }) async {
    try {
      final id = await _client.rpc(
        'rpc_wallet_topup_via_instapay',
        params: {
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
  Future<void> payOrderFromWallet({
    required String orderId,
    required double amount,
    required String clientRequestId,
  }) async {
    try {
      await _client.rpc(
        'rpc_pay_order_from_wallet',
        params: {
          'p_order_id': orderId,
          'p_amount': amount,
          'p_client_request_id': clientRequestId,
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<WalletSummary>> getAllWallets({String? search}) async {
    try {
      var query = _client.from('wallet_summary').select();
      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('customer_name', '%${search.trim()}%');
      }
      final rows = await query;
      final wallets = rows.map(WalletSummary.fromRow).toList()
        ..sort((a, b) => b.balance.compareTo(a.balance));
      return wallets;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<({double totalLiability, int walletCount})>
  getLiabilitySummary() async {
    try {
      final row = await _client
          .from('wallet_liability_summary')
          .select()
          .maybeSingle();
      return (
        totalLiability: (row?['total_liability'] as num?)?.toDouble() ?? 0,
        walletCount: (row?['wallet_count'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
