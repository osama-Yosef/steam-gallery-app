import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/customer_account_summary.dart';
import '../models/customer_account_transaction.dart';

abstract class CustomerAccountRepository {
  Future<List<CustomerAccountSummary>> getAllAccounts({String? search});

  Future<CustomerAccountSummary?> getAccountSummary(String customerId);

  Future<List<CustomerAccountTransaction>> getTransactions(String customerId);

  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? notes,
  });
}

class SupabaseCustomerAccountRepository implements CustomerAccountRepository {
  final SupabaseClient _client;
  SupabaseCustomerAccountRepository(this._client);

  @override
  Future<List<CustomerAccountSummary>> getAllAccounts({String? search}) async {
    try {
      var query = _client.from('customer_account_summary').select();
      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('customer_name', '%${search.trim()}%');
      }
      final rows = await query;
      final accounts = rows.map(CustomerAccountSummary.fromRow).toList()
        ..sort((a, b) => b.remainingBalance.compareTo(a.remainingBalance));
      return accounts;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<CustomerAccountSummary?> getAccountSummary(String customerId) async {
    try {
      final row = await _client
          .from('customer_account_summary')
          .select()
          .eq('customer_id', customerId)
          .maybeSingle();
      return row == null ? null : CustomerAccountSummary.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<CustomerAccountTransaction>> getTransactions(
    String customerId,
  ) async {
    try {
      final rows = await _client
          .from('customer_account_transactions')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      return rows.map(CustomerAccountTransaction.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? notes,
  }) async {
    try {
      await _client.rpc(
        'rpc_record_customer_payment',
        params: {
          'p_customer_id': customerId,
          'p_amount': amount,
          'p_order_id': null,
          'p_notes': notes,
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
