import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../technician_account/data/models/sale.dart';
import '../models/sale_line_input.dart';

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
}
