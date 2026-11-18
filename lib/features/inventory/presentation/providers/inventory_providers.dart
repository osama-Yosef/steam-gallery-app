import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/stock_movement.dart';
import '../../data/models/technician_bag_stock_item.dart';
import '../../data/models/warehouse_stock_item.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../../../core/utils/provider_cache.dart';
import '../../../../core/offline/outbox.dart';

import '../../../technician_account/data/repositories/technician_account_repository.dart';
import '../state/bag_stock.dart';

part 'inventory_providers.g.dart';

@Riverpod(keepAlive: true)
InventoryRepository inventoryRepository(Ref ref) {
  return SupabaseInventoryRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(outboxProvider),
  );
}

@riverpod
Future<List<WarehouseStockItem>> warehouseStock(Ref ref, {String? search}) {
  ref.cacheFor();
  ref.refreshOnServerChange();
  return ref
      .watch(inventoryRepositoryProvider)
      .getWarehouseStock(search: search);
}

@riverpod
Future<List<WarehouseStockItem>> assemblyStock(Ref ref) {
  ref.cacheFor();
  ref.refreshOnServerChange();
  return ref.watch(inventoryRepositoryProvider).getAssemblyStock();
}

@riverpod
Future<List<TechnicianBagStockItem>> technicianBagStock(
  Ref ref,
  String technicianId,
) async {
  // His sales still waiting to sync are already out of the bag: take them
  // off, and reload when one is added or sent (the server then has it).
  final outbox = ref.watch(outboxProvider);
  List<OutboxEntry> pending() => outbox.pendingOf(technicianSaleKind);
  final seen = pending().length;
  void onQueueChange() {
    if (pending().length != seen) ref.invalidateSelf();
  }

  outbox.addListener(onQueueChange);
  ref.onDispose(() => outbox.removeListener(onQueueChange));

  final bag = await ref
      .watch(inventoryRepositoryProvider)
      .getBagStock(technicianId);
  return bagStockAfterPending(bag, pending(), technicianId);
}

@riverpod
Future<List<StockMovement>> stockMovements(Ref ref, {String? productId}) {
  ref.cacheFor();
  ref.refreshOnServerChange();
  return ref
      .watch(inventoryRepositoryProvider)
      .getStockMovements(productId: productId);
}
