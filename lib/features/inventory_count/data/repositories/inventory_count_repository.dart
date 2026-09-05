import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/inventory_count.dart';
import '../models/inventory_count_item.dart';

abstract class InventoryCountRepository {
  Future<List<InventoryCount>> getCounts();

  Future<InventoryCount?> getCount(String countId);

  Future<List<InventoryCountItem>> getCountItems(String countId);

  /// v1 only supports counting the main warehouse — see docs/02-database-design.md.
  Future<String> startWarehouseCount();

  Future<void> saveItem({
    required String itemId,
    required int actualQuantity,
    String? reason,
    String? notes,
  });

  Future<void> completeCount(String countId);
}

class SupabaseInventoryCountRepository implements InventoryCountRepository {
  final SupabaseClient _client;
  SupabaseInventoryCountRepository(this._client);

  @override
  Future<List<InventoryCount>> getCounts() async {
    try {
      final rows = await _client
          .from('inventory_counts')
          .select()
          .order('started_at', ascending: false);
      return rows.map(InventoryCount.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<InventoryCount?> getCount(String countId) async {
    try {
      final row = await _client
          .from('inventory_counts')
          .select()
          .eq('id', countId)
          .maybeSingle();
      return row == null ? null : InventoryCount.fromRow(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<InventoryCountItem>> getCountItems(String countId) async {
    try {
      final rows = await _client
          .from('inventory_count_items')
          .select(
            'id, system_quantity, actual_quantity, difference, reason, notes, products(id, name, sku)',
          )
          .eq('inventory_count_id', countId);
      final items = rows.map(InventoryCountItem.fromRow).toList()
        ..sort((a, b) => a.productName.compareTo(b.productName));
      return items;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<String> startWarehouseCount() async {
    try {
      final warehouse = await _client
          .from('warehouses')
          .select('id')
          .eq('type', 'main')
          .eq('is_active', true)
          .single();
      final countId = await _client.rpc(
        'rpc_start_inventory_count',
        params: {
          'p_location_type': 'warehouse',
          'p_location_id': warehouse['id'],
          'p_product_ids': null,
        },
      );
      return countId as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> saveItem({
    required String itemId,
    required int actualQuantity,
    String? reason,
    String? notes,
  }) async {
    try {
      await _client.rpc(
        'rpc_save_inventory_count_item',
        params: {
          'p_item_id': itemId,
          'p_actual_quantity': actualQuantity,
          'p_reason': reason,
          'p_notes': notes,
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> completeCount(String countId) async {
    try {
      await _client.rpc(
        'rpc_complete_inventory_count',
        params: {'p_count_id': countId},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
