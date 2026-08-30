import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/order.dart';
import '../../data/models/order_item.dart';
import '../../data/repositories/order_repository.dart';

part 'order_providers.g.dart';

@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) {
  return SupabaseOrderRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Stream<List<Order>> customerOrders(Ref ref, String customerId) {
  return ref.watch(orderRepositoryProvider).watchCustomerOrders(customerId);
}

@riverpod
Stream<Order?> orderDetail(Ref ref, String orderId) {
  return ref.watch(orderRepositoryProvider).watchOrder(orderId);
}

@riverpod
Future<List<OrderItem>> orderItems(Ref ref, String orderId) {
  return ref.watch(orderRepositoryProvider).getOrderItems(orderId);
}

@riverpod
Stream<List<Order>> allOrders(Ref ref) {
  return ref.watch(orderRepositoryProvider).watchAllOrders();
}
