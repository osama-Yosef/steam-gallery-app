import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/models/inventory_count.dart';
import '../../data/models/inventory_count_item.dart';
import '../../data/repositories/inventory_count_repository.dart';

part 'inventory_count_providers.g.dart';

@Riverpod(keepAlive: true)
InventoryCountRepository inventoryCountRepository(Ref ref) {
  return SupabaseInventoryCountRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Future<List<InventoryCount>> inventoryCounts(Ref ref) {
  return ref.watch(inventoryCountRepositoryProvider).getCounts();
}

@riverpod
Future<InventoryCount?> inventoryCountDetail(Ref ref, String countId) {
  return ref.watch(inventoryCountRepositoryProvider).getCount(countId);
}

@riverpod
Future<List<InventoryCountItem>> inventoryCountItems(Ref ref, String countId) {
  return ref.watch(inventoryCountRepositoryProvider).getCountItems(countId);
}
