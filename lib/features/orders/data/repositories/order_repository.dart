import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../cart/data/models/cart_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';

abstract class OrderRepository {
  /// Snapshot-priced order creation via rpc_create_order. [clientRequestId]
  /// must stay the same across retries of the same checkout attempt so a
  /// flaky connection can't create duplicate orders (see NFR-11).
  Future<String> createOrder({
    required String customerId,
    required List<CartItem> items,
    String? deliveryAddress,
    String? notes,
    required String clientRequestId,
  });

  Stream<List<Order>> watchCustomerOrders(String customerId);
  Stream<Order?> watchOrder(String orderId);
  Future<List<OrderItem>> getOrderItems(String orderId);

  // Admin
  Stream<List<Order>> watchAllOrders();
  Future<void> confirmOrder(String orderId);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<void> cancelOrder(String orderId, String reason);
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? orderId,
    String? notes,
  });
}

class SupabaseOrderRepository implements OrderRepository {
  final SupabaseClient _client;
  SupabaseOrderRepository(this._client);

  @override
  Future<String> createOrder({
    required String customerId,
    required List<CartItem> items,
    String? deliveryAddress,
    String? notes,
    required String clientRequestId,
  }) async {
    try {
      final id = await _client.rpc(
        'rpc_create_order',
        params: {
          'p_customer_id': customerId,
          'p_items': items
              .map((e) => {'product_id': e.productId, 'quantity': e.quantity})
              .toList(),
          'p_delivery_address': deliveryAddress,
          'p_latitude': null,
          'p_longitude': null,
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
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? orderId,
    String? notes,
  }) async {
    try {
      await _client.rpc(
        'rpc_record_customer_payment',
        params: {
          'p_customer_id': customerId,
          'p_amount': amount,
          'p_order_id': orderId,
          'p_notes': notes,
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
