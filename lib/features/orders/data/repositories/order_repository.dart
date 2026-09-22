import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../technician_account/data/models/sale.dart';
import '../models/order.dart';
import '../models/order_item.dart';

abstract class OrderRepository {
  /// Snapshot-priced order creation via rpc_create_order. [clientRequestId]
  /// must stay the same across retries of the same checkout attempt so a
  /// flaky connection can't create duplicate orders (see NFR-11).
  /// [items] is a plain (productId, quantity, optionIds) list — decoupled
  /// from the cart feature's own model so this repository does not depend
  /// on it. [optionIds] (0049) are the priced options selected for that
  /// line; the server re-prices from them, never trusting a client total.
  Future<String> createOrder({
    required String customerId,
    required List<({String productId, int quantity, List<String> optionIds})>
    items,
    required String addressId,
    String? notes,
    required String clientRequestId,
  });

  Stream<List<Order>> watchCustomerOrders(String customerId);
  Stream<Order?> watchOrder(String orderId);
  Future<List<OrderItem>> getOrderItems(String orderId);
  /// The customer's answer to a proposed shipping fee — [rejectionReason]
  /// is required when [approve] is false. See
  /// rpc_customer_respond_shipping_fee (0065).
  Future<void> respondToShippingFee({
    required String orderId,
    required bool approve,
    String? rejectionReason,
  });

  // Admin
  Stream<List<Order>> watchAllOrders();
  /// Proposes (or re-proposes, after a rejection) the shipping fee while
  /// the order is still pending — required before [confirmOrder] will
  /// succeed. See rpc_admin_set_shipping_fee (0065).
  Future<void> setShippingFee({required String orderId, required double amount});
  Future<void> confirmOrder(String orderId);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<void> cancelOrder(String orderId, String reason);
  /// Post-delivery return (Phase 14) — restocks items and refunds through
  /// whichever channel(s) actually paid for the order (wallet, InstaPay, or
  /// cash), unlike [cancelOrder] this only applies to a delivered/completed
  /// order.
  Future<void> returnOrder(String orderId, String reason);
  /// [paymentMethod] (0059) says which till the money lands in — cash or
  /// transfer/card; 'deferred' is refused server-side. This has nothing to
  /// do with the order's payment_status, only which cashbox gets credited.
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? orderId,
    String? notes,
    required String clientRequestId,
    required PaymentMethod paymentMethod,
  });
}

class SupabaseOrderRepository implements OrderRepository {
  final SupabaseClient _client;
  SupabaseOrderRepository(this._client);

  @override
  Future<String> createOrder({
    required String customerId,
    required List<({String productId, int quantity, List<String> optionIds})>
    items,
    required String addressId,
    String? notes,
    required String clientRequestId,
  }) async {
    try {
      final id = await _client.rpc(
        'rpc_create_order',
        params: {
          'p_customer_id': customerId,
          'p_items': items
              .map(
                (e) => {
                  'product_id': e.productId,
                  'quantity': e.quantity,
                  'option_ids': e.optionIds,
                },
              )
              .toList(),
          'p_address_id': addressId,
          'p_notes': notes,
          'p_client_request_id': clientRequestId,
        },
      );
      return id as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Stream<List<Order>> watchCustomerOrders(String customerId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Order.fromRow).toList());
  }

  @override
  Stream<Order?> watchOrder(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((rows) => rows.isEmpty ? null : Order.fromRow(rows.first));
  }

  @override
  Future<List<OrderItem>> getOrderItems(String orderId) async {
    try {
      final rows = await _client
          .from('order_items_display')
          .select()
          .eq('order_id', orderId);
      return rows.map(OrderItem.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Stream<List<Order>> watchAllOrders() {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Order.fromRow).toList());
  }

  @override
  Future<void> setShippingFee({
    required String orderId,
    required double amount,
  }) async {
    try {
      await _client.rpc(
        'rpc_admin_set_shipping_fee',
        params: {'p_order_id': orderId, 'p_amount': amount},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> respondToShippingFee({
    required String orderId,
    required bool approve,
    String? rejectionReason,
  }) async {
    try {
      await _client.rpc(
        'rpc_customer_respond_shipping_fee',
        params: {
          'p_order_id': orderId,
          'p_approve': approve,
          'p_rejection_reason': rejectionReason,
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> confirmOrder(String orderId) async {
    try {
      await _client.rpc('rpc_confirm_order', params: {'p_order_id': orderId});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _client.rpc(
        'rpc_update_order_status',
        params: {'p_order_id': orderId, 'p_new_status': status.name},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _client.rpc(
        'rpc_cancel_order',
        params: {'p_order_id': orderId, 'p_reason': reason},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> returnOrder(String orderId, String reason) async {
    try {
      await _client.rpc(
        'rpc_admin_return_order',
        params: {'p_order_id': orderId, 'p_reason': reason},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? orderId,
    String? notes,
    required String clientRequestId,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      await _client.rpc(
        'rpc_record_customer_payment',
        params: {
          'p_customer_id': customerId,
          'p_amount': amount,
          'p_order_id': orderId,
          'p_notes': notes,
          'p_client_request_id': clientRequestId,
          'p_payment_method': paymentMethodToString(paymentMethod),
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
