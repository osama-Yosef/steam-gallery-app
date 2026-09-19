import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../technician_account/data/models/sale.dart';
import '../models/sale_line_input.dart';
import '../models/sale_return_item.dart';

abstract class SalesRepository {
  /// Counter sale straight from the main warehouse to a walk-in customer
  /// who has no app account — see 0019_admin_walk_in_sales.sql. Payment is
  /// always taken in full on the spot (no partial/credit tracking, unlike
  /// technician sales), which is why there's no paidAmount parameter here.
  Future<String> recordWalkInSale({
    String? customerName,
    String? customerPhone,
    required List<SaleLineInput> items,
    required PaymentMethod paymentMethod,
    required double discount,
    required String clientRequestId,
    String? notes,
  });

  /// Walk-in sales only (technician_id is null) — a technician's own field
  /// sale never shows up here; see 0057 for why returning one is out of
  /// scope for this screen.
  Stream<List<Sale>> watchWalkInSales();

  /// Reverses a completed walk-in sale: stock back to the main warehouse,
  /// the till refunded, status -> returned. See rpc_admin_return_sale (0057).
  Future<void> returnSale({required String saleId, required String reason});

  /// The invoice's lines with how much of each is still returnable (0058).
  Future<List<SaleReturnItem>> getSaleItems(String saleId);

  /// Returns [quantity] of one line — any amount up to what's left on it.
  /// See rpc_return_sale_item (0058).
  Future<void> returnSaleItem({
    required String saleItemId,
    required int quantity,
    required String reason,
  });
}

class SupabaseSalesRepository implements SalesRepository {
  final SupabaseClient _client;
  SupabaseSalesRepository(this._client);

  @override
  Future<String> recordWalkInSale({
    String? customerName,
    String? customerPhone,
    required List<SaleLineInput> items,
    required PaymentMethod paymentMethod,
    required double discount,
    required String clientRequestId,
    String? notes,
  }) async {
    try {
      final saleId = await _client.rpc(
        'rpc_admin_walk_in_sale',
        params: {
          'p_customer_name': customerName,
          'p_customer_phone': customerPhone,
          'p_items': items.map((e) => e.toJson()).toList(),
          'p_payment_method': paymentMethodToString(paymentMethod),
          'p_discount': discount,
          'p_client_request_id': clientRequestId,
          'p_notes': notes,
        },
      );
      return saleId as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Stream<List<Sale>> watchWalkInSales() {
    return _client
        .from('sales')
        .stream(primaryKey: ['id'])
        .isFilter('technician_id', null)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Sale.fromRow).toList());
  }

  @override
  Future<void> returnSale({
    required String saleId,
    required String reason,
  }) async {
    try {
      await _client.rpc(
        'rpc_admin_return_sale',
        params: {'p_sale_id': saleId, 'p_reason': reason},
      );
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
  Future<void> returnSaleItem({
    required String saleItemId,
    required int quantity,
    required String reason,
  }) async {
    try {
      await _client.rpc(
        'rpc_return_sale_item',
        params: {
          'p_sale_item_id': saleItemId,
          'p_quantity': quantity,
          'p_reason': reason,
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
