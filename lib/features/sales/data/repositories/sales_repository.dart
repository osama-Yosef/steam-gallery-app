import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/offline/outbox.dart';
import '../../../../core/utils/formatters.dart';
import '../../../cashbox/data/models/cashbox_balance.dart';
import '../../../technician_account/data/models/sale.dart';
import '../models/invoice_line.dart';
import '../models/sale_line_input.dart';
import '../models/sale_return_item.dart';

abstract class SalesRepository {
  /// Counter sale straight from the main warehouse to a walk-in customer
  /// who has no app account — see 0019_admin_walk_in_sales.sql. Payment is
  /// always taken in full on the spot (no partial/credit tracking, unlike
  /// technician sales), which is why there's no paidAmount parameter here.
  ///
  /// Offline-capable: queued in the [Outbox] when the server can't be
  /// reached (safe to resend — [clientRequestId] is the idempotency key).
  Future<OutboxResult> recordWalkInSale({
    String? customerName,
    String? customerPhone,
    required List<SaleLineInput> items,
    required PaymentMethod paymentMethod,
    required double discount,
    required String clientRequestId,
    String? notes,
  });

  /// The invoice's current content, one line per product (0075).
  Future<List<InvoiceLine>> getInvoiceLines(String saleId);

  /// Sets the invoice to exactly [items] (anything left out is removed) and
  /// [discount] (null keeps it). The money difference is collected into, or
  /// refunded from, the [moneyKind] till. See rpc_admin_edit_sale (0075).
  Future<OutboxResult> editSale({
    required String saleId,
    required int saleNumber,
    required List<InvoiceLine> items,
    double? discount,
    CashboxKind? moneyKind,
  });

  /// Cancels the whole invoice: stock back, money refunded from
  /// [refundKind], status -> cancelled. See rpc_admin_delete_sale (0075).
  Future<OutboxResult> deleteSale({
    required String saleId,
    required int saleNumber,
    required String reason,
    CashboxKind? refundKind,
  });

  /// Walk-in sales only (technician_id is null), newest first — a
  /// technician's own field sale never shows up here; see 0057 for why
  /// returning one is out of scope for this screen.
  ///
  /// A plain fetch, not a realtime stream: `sales` isn't in the realtime
  /// publication, so a stream only ever delivered its first snapshot and new
  /// invoices never appeared. The list is refetched after every write
  /// instead (OfflineRefresh).
  Future<List<Sale>> getWalkInSales();

  /// Reverses a completed walk-in sale: stock back to the main warehouse,
  /// the till refunded, status -> returned. [refundKind] picks which till
  /// (cash/transfer) the refund comes out of; omit to fall back to the
  /// sale's own payment method. See rpc_admin_return_sale (0057, 0063).
  Future<void> returnSale({
    required String saleId,
    required String reason,
    CashboxKind? refundKind,
  });

  /// The invoice's lines with how much of each is still returnable (0058).
  Future<List<SaleReturnItem>> getSaleItems(String saleId);

  /// A single sale by id — used by the return screen to default the refund
  /// till picker to how the sale was originally paid (0063).
  Future<Sale> getSale(String saleId);

  /// Returns [quantity] of one line — any amount up to what's left on it.
  /// [refundKind] picks which till (cash/transfer) the refund comes out of;
  /// omit to fall back to the sale's own payment method. See
  /// rpc_return_sale_item (0058, 0063).
  Future<void> returnSaleItem({
    required String saleItemId,
    required int quantity,
    required String reason,
    CashboxKind? refundKind,
  });
}

class SupabaseSalesRepository implements SalesRepository {
  final SupabaseClient _client;
  SupabaseSalesRepository(this._client);

  @override
  Future<OutboxResult> recordWalkInSale({
    String? customerName,
    String? customerPhone,
    required List<SaleLineInput> items,
    required PaymentMethod paymentMethod,
    required double discount,
    required String clientRequestId,
    String? notes,
  }) {
    final count = items.fold<int>(0, (sum, i) => sum + i.quantity);
    return Outbox.instance.submit(
      rpc: 'rpc_admin_walk_in_sale',
      params: {
        'p_customer_name': customerName,
        'p_customer_phone': customerPhone,
        'p_items': items.map((e) => e.toJson()).toList(),
        'p_payment_method': paymentMethodToString(paymentMethod),
        'p_discount': discount,
        'p_client_request_id': clientRequestId,
        'p_notes': notes,
      },
      label:
          'بيع مباشر · $count قطعة'
          '${customerName == null ? '' : ' · $customerName'}',
      kind: 'walk_in_sale',
      requestId: clientRequestId,
    );
  }

  @override
  Future<List<InvoiceLine>> getInvoiceLines(String saleId) async {
    try {
      final rows = await _client
          .from('sale_items_with_returns')
          .select(
            'product_id, product_name_snapshot, quantity, returned_quantity, unit_price_snapshot, discount',
          )
          .eq('sale_id', saleId);
      final productIds = {for (final r in rows) r['product_id'] as String};
      final flags = productIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client
                .from('products')
                .select('id, is_service, is_assembly')
                .inFilter('id', productIds.toList());
      final flagsById = {for (final f in flags) f['id'] as String: f};

      final qty = <String, int>{};
      final value = <String, double>{};
      final names = <String, String>{};
      for (final r in rows) {
        final id = r['product_id'] as String;
        final total = r['quantity'] as int;
        final left = total - (r['returned_quantity'] as int);
        if (left <= 0) continue;
        final unit = (r['unit_price_snapshot'] as num).toDouble();
        final lineDiscount = (r['discount'] as num).toDouble();
        qty[id] = (qty[id] ?? 0) + left;
        value[id] =
            (value[id] ?? 0) + left * unit - lineDiscount * left / total;
        names[id] = r['product_name_snapshot'] as String;
      }
      return [
        for (final id in qty.keys)
          InvoiceLine(
            productId: id,
            productName: names[id]!,
            quantity: qty[id]!,
            unitPrice: value[id]! / qty[id]!,
            isService: flagsById[id]?['is_service'] as bool? ?? false,
            isAssembly: flagsById[id]?['is_assembly'] as bool? ?? false,
          ),
      ]..sort((a, b) => a.productName.compareTo(b.productName));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<OutboxResult> editSale({
    required String saleId,
    required int saleNumber,
    required List<InvoiceLine> items,
    double? discount,
    CashboxKind? moneyKind,
  }) {
    final total =
        items.fold<double>(0, (sum, l) => sum + l.lineTotal) - (discount ?? 0);
    return Outbox.instance.submit(
      rpc: 'rpc_admin_edit_sale',
      params: {
        'p_sale_id': saleId,
        'p_items': items.map((l) => l.toEditJson()).toList(),
        'p_discount': discount,
        'p_reason': 'تعديل فاتورة',
        'p_money_kind': moneyKind == null
            ? null
            : cashboxKindToString(moneyKind),
      },
      label: 'تعديل فاتورة #$saleNumber · ${Formatters.currency(total)}',
      kind: 'sale_edit',
      refId: saleId,
      meta: {
        'lines': items.map((l) => l.toJson()).toList(),
        'discount': discount,
      },
    );
  }

  @override
  Future<OutboxResult> deleteSale({
    required String saleId,
    required int saleNumber,
    required String reason,
    CashboxKind? refundKind,
  }) {
    return Outbox.instance.submit(
      rpc: 'rpc_admin_delete_sale',
      params: {
        'p_sale_id': saleId,
        'p_reason': reason,
        'p_refund_kind': refundKind == null
            ? null
            : cashboxKindToString(refundKind),
      },
      label: 'حذف فاتورة #$saleNumber',
      kind: 'sale_delete',
      refId: saleId,
    );
  }

  @override
  Future<List<Sale>> getWalkInSales() async {
    try {
      final rows = await _client
          .from('sales')
          .select()
          .isFilter('technician_id', null)
          .order('created_at', ascending: false)
          .limit(1000);
      return rows.map(Sale.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> returnSale({
    required String saleId,
    required String reason,
    CashboxKind? refundKind,
  }) async {
    try {
      await _client.rpc(
        'rpc_admin_return_sale',
        params: {
          'p_sale_id': saleId,
          'p_reason': reason,
          'p_refund_kind': refundKind == null
              ? null
              : cashboxKindToString(refundKind),
        },
      );
      Outbox.instance.markServerChanged();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<SaleReturnItem>> getSaleItems(String saleId) async {
    try {
      final rows = await _client
          .from('sale_items_with_returns')
          .select()
          .eq('sale_id', saleId);
      return rows.map(SaleReturnItem.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<Sale> getSale(String saleId) async {
    try {
      final row = await _client
          .from('sales')
          .select()
          .eq('id', saleId)
          .single();
      return Sale.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> returnSaleItem({
    required String saleItemId,
    required int quantity,
    required String reason,
    CashboxKind? refundKind,
  }) async {
    try {
      await _client.rpc(
        'rpc_return_sale_item',
        params: {
          'p_sale_item_id': saleItemId,
          'p_quantity': quantity,
          'p_reason': reason,
          'p_refund_kind': refundKind == null
              ? null
              : cashboxKindToString(refundKind),
        },
      );
      Outbox.instance.markServerChanged();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
