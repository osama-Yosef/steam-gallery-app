import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/technician_account_summary.dart';
import '../models/technician_account_transaction.dart';

abstract class TechnicianAccountRepository {
  /// All technicians' summaries at once — used by the admin Technicians
  /// report (Module 11). Admin sees every row via RLS on the underlying
  /// tables the view joins.
  Future<List<TechnicianAccountSummary>> getAllAccountSummaries();

  Future<TechnicianAccountSummary?> getAccountSummary(String technicianId);

  Future<List<TechnicianAccountTransaction>> getAccountTransactions(String technicianId);

  Future<List<Sale>> getSales(String technicianId);

  Future<Sale?> getSaleById(String saleId);

  Future<List<SaleItem>> getSaleItems(String saleId);

  Future<String> recordSale({
    required String technicianId,
    String? customerName,
    String? customerPhone,
    required List<({String productId, int quantity})> items,
    required PaymentMethod paymentMethod,
    required double discount,
    required double paidAmount,
    required String clientRequestId,
    String? notes,
  });

  Future<void> recordSupply({required String technicianId, required double amount, String? notes});
}

class SupabaseTechnicianAccountRepository implements TechnicianAccountRepository {
  final SupabaseClient _client;
  SupabaseTechnicianAccountRepository(this._client);

  @override
  Future<List<TechnicianAccountSummary>> getAllAccountSummaries() async {
    try {
      final rows = await _client.from('technician_account_summary').select();
      return rows.map(TechnicianAccountSummary.fromRow).toList()
        ..sort((a, b) => b.amountDue.compareTo(a.amountDue));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<TechnicianAccountSummary?> getAccountSummary(String technicianId) async {
    try {
      final row = await _client
          .from('technician_account_summary')
          .select()
          .eq('technician_id', technicianId)
          .maybeSingle();
      return row == null ? null : TechnicianAccountSummary.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<TechnicianAccountTransaction>> getAccountTransactions(String technicianId) async {
    try {
      final rows = await _client
          .from('technician_account_transactions')
          .select()
          .eq('technician_id', technicianId)
          .order('created_at', ascending: false);
      return rows.map(TechnicianAccountTransaction.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<Sale>> getSales(String technicianId) async {
    try {
      final rows = await _client
          .from('sales')
          .select()
          .eq('technician_id', technicianId)
          .order('created_at', ascending: false);
      return rows.map(Sale.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<Sale?> getSaleById(String saleId) async {
    try {
      final row = await _client.from('sales').select().eq('id', saleId).maybeSingle();
      return row == null ? null : Sale.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<SaleItem>> getSaleItems(String saleId) async {
    try {
      final rows = await _client.from('sale_items').select().eq('sale_id', saleId);
      return rows.map(SaleItem.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<String> recordSale({
    required String technicianId,
    String? customerName,
    String? customerPhone,
    required List<({String productId, int quantity})> items,
    required PaymentMethod paymentMethod,
    required double discount,
    required double paidAmount,
    required String clientRequestId,
    String? notes,
  }) async {
    try {
      final saleId = await _client.rpc('rpc_technician_sale', params: {
        'p_technician_id': technicianId,
        'p_customer_id': null,
        'p_customer_name': customerName,
        'p_customer_phone': customerPhone,
        'p_items': items.map((e) => {'product_id': e.productId, 'quantity': e.quantity}).toList(),
        'p_payment_method': paymentMethodToString(paymentMethod),
        'p_discount': discount,
        'p_paid_amount': paidAmount,
        'p_client_request_id': clientRequestId,
        'p_notes': notes,
      });
      return saleId as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> recordSupply({required String technicianId, required double amount, String? notes}) async {
    try {
      await _client.rpc('rpc_technician_supply', params: {
        'p_technician_id': technicianId,
        'p_amount': amount,
        'p_notes': notes,
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
