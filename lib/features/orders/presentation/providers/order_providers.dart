import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/utils/history_query.dart';
import '../../data/models/order.dart';
import '../../data/models/order_item.dart';
import '../../data/repositories/order_repository.dart';
import '../../../../core/offline/outbox.dart';

part 'order_providers.g.dart';

@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) {
  return SupabaseOrderRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(outboxProvider),
  );
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
Stream<List<Order>> openOrders(Ref ref) {
  return ref.watch(orderRepositoryProvider).watchOpenOrders();
}

/// The orders history screen's results for one [HistoryQuery]: the first
/// page loads on watch, [loadMore] appends the next (infinite scroll).
@riverpod
class OrderHistory extends _$OrderHistory {
  @override
  Future<HistoryPage<Order>> build(HistoryQuery query) async {
    final items = await ref
        .watch(orderRepositoryProvider)
        .searchOrders(query, limit: historyPageSize, offset: 0);
    return HistoryPage(items: items, hasMore: items.length == historyPageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final next = await ref
          .read(orderRepositoryProvider)
          .searchOrders(
            query,
            limit: historyPageSize,
            offset: current.items.length,
          );
      if (ref.mounted) state = AsyncData(current.append(next, historyPageSize));
    } catch (_) {
      if (ref.mounted) {
        state = AsyncData(
          current.copyWith(loadingMore: false, loadMoreFailed: true),
        );
      }
    }
  }
}
