import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../sales/data/models/sale_line_input.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/technician_account_summary.dart';
import '../models/technician_account_transaction.dart';
import '../models/technician_supply.dart';

abstract class TechnicianAccountRepository {
  /// All technicians' summaries at once — used by the admin Technicians
  /// report (Module 11). Admin sees every row via RLS on the underlying
  /// tables the view joins.
  Future<List<TechnicianAccountSummary>> getAllAccountSummaries();

  Future<TechnicianAccountSummary?> getAccountSummary(String technicianId);

  Future<List<TechnicianAccountTransaction>> getAccountTransactions(
    String technicianId,
  );

  Future<List<Sale>> getSales(String technicianId);

  Future<Sale?> getSaleById(String saleId);

  /// The invoice raised against a finished maintenance job, if there is one.
  Future<Sale?> getSaleForMaintenance(String maintenanceRequestId);

  Future<List<SaleItem>> getSaleItems(String saleId);

  Future<String> recordSale({
    required String technicianId,
    String? customerName,
    String? customerPhone,
    required List<SaleLineInput> items,
    required PaymentMethod paymentMethod,
    required double discount,
    required double paidAmount,
    required String clientRequestId,
    String? notes,
    String? maintenanceRequestId,
  });

  Future<void> recordSupply({
    required String technicianId,
    required double amount,
    String? notes,
  });

  /// Supplies awaiting an admin's confirmation, newest first.
  Future<List<TechnicianSupply>> getPendingSupplies(String technicianId);

  /// Admin only. Approving posts the supply to the technician account and
  /// the cashbox; rejecting requires a [reason]. Repeating the same decision
  /// is a server-side no-op.
  Future<void> reviewSupply({
    required String supplyId,
    required bool approve,
    String? reason,
  });
}

class SupabaseTechnicianAccountRepository
    implements TechnicianAccountRepository {
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
  Future<TechnicianAccountSummary?> getAccountSummary(
    String technicianId,
  ) async {
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
  Future<List<TechnicianAccountTransaction>> getAccountTransactions(
    String technicianId,
  ) async {
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
      final row = await _client
          .from('sales')
          .select()
          .eq('id', saleId)
          .maybeSingle();
      return row == null ? null : Sale.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<Sale?> getSaleForMaintenance(String maintenanceRequestId) async {
    try {
      final row = await _client
          .from('sales')
          .select()
          .eq('maintenance_request_id', maintenanceRequestId)
          .maybeSingle();
      return row == null ? null : Sale.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<SaleItem>> getSaleItems(String saleId) async {
    try {
      // sale_items_display, not sale_items: the customer of a maintenance
      // invoice reads this too, and the raw table carries unit_cost_snapshot
      // (see 0029_security_hotfix_p0.sql).
      final rows = await _client
          .from('sale_items_display')
          .select()
          .eq('sale_id', saleId);
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
    required List<SaleLineInput> items,
    required PaymentMethod paymentMethod,
    required double discount,
    required double paidAmount,
    required String clientRequestId,
    String? notes,
    String? maintenanceRequestId,
  }) async {
    try {
      final saleId = await _client.rpc(
        'rpc_technician_sale',
        params: {
          'p_technician_id': technicianId,
          'p_customer_id': null,
          'p_customer_name': customerName,
          'p_customer_phone': customerPhone,
          'p_items': items.map((e) => e.toJson()).toList(),
          'p_payment_method': paymentMethodToString(paymentMethod),
          'p_discount': discount,
          'p_paid_amount': paidAmount,
          'p_client_request_id': clientRequestId,
          'p_notes': notes,
          'p_maintenance_request_id': maintenanceRequestId,
        },
      );
      return saleId as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> recordSupply({
    required String technicianId,
    required double amount,
    String? notes,
  }) async {
    try {
      await _client.rpc(
        'rpc_technician_supply',
        params: {
          'p_technician_id': technicianId,
          'p_amount': amount,
          'p_notes': notes,
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<TechnicianSupply>> getPendingSupplies(String technicianId) async {
    try {
      final rows = await _client
          .from('technician_supplies')
          .select()
          .eq('technician_id', technicianId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return rows.map(TechnicianSupply.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> reviewSupply({
    required String supplyId,
    required bool approve,
    String? reason,
  }) async {
    try {
      await _client.rpc(
        'rpc_admin_review_technician_supply',
        params: {
          'p_supply_id': supplyId,
          'p_approve': approve,
          'p_reason': reason,
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
