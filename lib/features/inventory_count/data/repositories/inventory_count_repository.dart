import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/inventory_count.dart';
import '../models/inventory_count_item.dart';
import '../../../../core/offline/outbox.dart';

abstract class InventoryCountRepository {
  Future<List<InventoryCount>> getCounts();

  Future<InventoryCount?> getCount(String countId);

  Future<List<InventoryCountItem>> getCountItems(String countId);

  Future<String> startWarehouseCount();

  /// Starts — or reopens the open — count of a technician's bag (0089).
  Future<String> startBagCount(String technicianId);

  /// A product found that the count has no line for (a surplus). Returns
  /// the line's id.
  Future<String> addItem({required String countId, required String productId});

  /// Products that can be added to a count as a surplus.
  Future<List<({String id, String name, String sku})>> getCountableProducts();

  /// The technician sends his own bag count for review.
  Future<void> submitCount(String countId);

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
  final Outbox _outbox;
  SupabaseInventoryCountRepository(this._client, this._outbox);

  @override
  Future<List<InventoryCount>> getCounts() async {
    try {
      final rows = await _client
          .from('inventory_counts')
          .select()
          .order('started_at', ascending: false);
      return await _withTechnicianNames(
        rows.map(InventoryCount.fromRow).toList(),
      );
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
      if (row == null) return null;
      return (await _withTechnicianNames([InventoryCount.fromRow(row)])).single;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// inventory_counts.location_id has no foreign key to embed through, so
  /// bag counts get their technician's name from technician_bags. A failure
  /// here only loses the name.
  Future<List<InventoryCount>> _withTechnicianNames(
    List<InventoryCount> counts,
  ) async {
    if (!counts.any((c) => c.isBag)) return counts;
    try {
      final rows = await _client
          .from('technician_bags')
          .select('id, technicians(users!technicians_id_fkey(full_name))');
      final nameByBag = {
        for (final r in rows)
          r['id'] as String:
              ((r['technicians'] as Map?)?['users'] as Map?)?['full_name']
                  as String?,
      };
      return [
        for (final c in counts)
          c.isBag ? c.copyWith(technicianName: nameByBag[c.locationId]) : c,
      ];
    } catch (_) {
      return counts;
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
  Future<String> startBagCount(String technicianId) async {
    try {
      final countId = await _client.rpc(
        'rpc_start_bag_count',
        params: {'p_technician_id': technicianId},
      );
      return countId as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<String> addItem({
    required String countId,
    required String productId,
  }) async {
    try {
      final itemId = await _client.rpc(
        'rpc_add_inventory_count_item',
        params: {'p_count_id': countId, 'p_product_id': productId},
      );
      return itemId as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<({String id, String name, String sku})>>
  getCountableProducts() async {
    try {
      final rows = await _client
          .from('products')
          .select('id, name, sku')
          .eq('is_active', true)
          .eq('is_assembly', false)
          .order('name');
      return [
        for (final r in rows)
          (
            id: r['id'] as String,
            name: r['name'] as String,
            sku: r['sku'] as String,
          ),
      ];
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> submitCount(String countId) async {
    try {
      await _client.rpc(
        'rpc_submit_inventory_count',
        params: {'p_count_id': countId},
      );
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
      // Stock, tills and prices shown elsewhere refetch on this.
      _outbox.markServerChanged();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
