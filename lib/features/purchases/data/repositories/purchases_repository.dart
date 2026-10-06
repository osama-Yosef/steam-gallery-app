import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/outbox.dart';
import '../../../../core/utils/formatters.dart';
import '../../../cashbox/data/models/cashbox_balance.dart';
import '../models/purchase_models.dart';

abstract class PurchasesRepository {
  Future<List<SupplierBalance>> getSuppliers();
  Future<List<PurchaseInvoice>> getInvoices({String? supplierId});
  Future<PurchaseInvoice> getInvoice(String id);
  Future<List<PurchaseInvoiceItem>> getInvoiceItems(String invoiceId);
  Future<List<SupplierPayment>> getInvoicePayments(String invoiceId);

  /// Records a purchase from a supplier: stock into the main warehouse, cost
  /// prices updated, and [paidAmount] (0 = آجل) paid out of the [paymentKind]
  /// till — the rest stays on the supplier's balance. Pick an existing
  /// supplier by [supplierId], or give [supplierName] to find/create one.
  /// Offline-capable ([clientRequestId] makes a resend safe).
  Future<OutboxResult> createInvoice({
    String? supplierId,
    String? supplierName,
    String? supplierPhone,
    required List<PurchaseLineInput> items,
    required double discount,
    required double paidAmount,
    CashboxKind? paymentKind,
    required DateTime invoiceDate,
    String? supplierInvoiceRef,
    String? notes,
    required String clientRequestId,
  });

  /// Pays a supplier — against [invoiceId], or their oldest unpaid invoices
  /// first when null. Offline-capable.
  Future<OutboxResult> paySupplier({
    required String supplierId,
    required String supplierName,
    required double amount,
    required CashboxKind kind,
    String? invoiceId,
    String? notes,
    required String clientRequestId,
  });
}

class SupabasePurchasesRepository implements PurchasesRepository {
  final SupabaseClient _client;
  SupabasePurchasesRepository(this._client);

  @override
  Future<List<SupplierBalance>> getSuppliers() async {
    try {
      final rows = await _client
          .from('supplier_balances')
          .select()
          .order('name');
      return rows.map(SupplierBalance.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<PurchaseInvoice>> getInvoices({String? supplierId}) async {
    try {
      var query = _client.from('purchase_invoices_summary').select();
      if (supplierId != null) query = query.eq('supplier_id', supplierId);
      final rows = await query
          .order('invoice_date', ascending: false)
          .order('invoice_number', ascending: false)
          .limit(500);
      return rows.map(PurchaseInvoice.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<PurchaseInvoice> getInvoice(String id) async {
    try {
      final row = await _client
          .from('purchase_invoices_summary')
          .select()
          .eq('id', id)
          .single();
      return PurchaseInvoice.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<PurchaseInvoiceItem>> getInvoiceItems(String invoiceId) async {
    try {
      final rows = await _client
          .from('purchase_invoice_items')
          .select('product_name_snapshot, quantity, unit_cost, line_total')
          .eq('invoice_id', invoiceId)
          .order('product_name_snapshot');
      return rows.map(PurchaseInvoiceItem.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<SupplierPayment>> getInvoicePayments(String invoiceId) async {
    try {
      final rows = await _client
          .from('supplier_payments')
          .select('payment_number, amount, kind, notes, created_at')
          .eq('invoice_id', invoiceId)
          .order('created_at');
      return rows.map(SupplierPayment.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<OutboxResult> createInvoice({
    String? supplierId,
    String? supplierName,
    String? supplierPhone,
    required List<PurchaseLineInput> items,
    required double discount,
    required double paidAmount,
    CashboxKind? paymentKind,
    required DateTime invoiceDate,
    String? supplierInvoiceRef,
    String? notes,
    required String clientRequestId,
  }) {
    final total =
        items.fold<double>(0, (sum, l) => sum + l.lineTotal) - discount;
    return Outbox.instance.submit(
      rpc: 'rpc_create_purchase_invoice',
      params: {
        'p_supplier_id': supplierId,
        'p_supplier_name': supplierName,
        'p_supplier_phone': supplierPhone,
        'p_items': items.map((l) => l.toJson()).toList(),
        'p_discount': discount,
        'p_paid_amount': paidAmount,
        'p_payment_kind': paymentKind == null
            ? null
            : cashboxKindToString(paymentKind),
        'p_invoice_date': invoiceDate.toIso8601String().split('T').first,
        'p_supplier_invoice_ref': supplierInvoiceRef,
        'p_notes': notes,
        'p_client_request_id': clientRequestId,
      },
      label:
          'فاتورة شراء · ${supplierName ?? ''} · ${Formatters.currency(total)}',
      kind: 'purchase_invoice',
      requestId: clientRequestId,
    );
  }

  @override
  Future<OutboxResult> paySupplier({
    required String supplierId,
    required String supplierName,
    required double amount,
    required CashboxKind kind,
    String? invoiceId,
    String? notes,
    required String clientRequestId,
  }) {
    return Outbox.instance.submit(
      rpc: 'rpc_pay_supplier',
      params: {
        'p_supplier_id': supplierId,
        'p_amount': amount,
        'p_kind': cashboxKindToString(kind),
        'p_invoice_id': invoiceId,
        'p_notes': notes,
        'p_client_request_id': clientRequestId,
      },
      label: 'سداد للمورد $supplierName · ${Formatters.currency(amount)}',
      kind: 'supplier_payment',
      refId: supplierId,
      requestId: clientRequestId,
    );
  }
}
