import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/stock_movement.dart';
import '../models/technician_bag_stock_item.dart';
import '../models/warehouse_stock_item.dart';

abstract class InventoryRepository {
  /// v1 has exactly one (main) warehouse — see docs/02-database-design.md —
  /// so no warehouse_id is needed here or in the RPC calls below.
  Future<List<WarehouseStockItem>> getWarehouseStock({String? search});

  Future<List<TechnicianBagStockItem>> getBagStock(String technicianId);

  Future<List<StockMovement>> getStockMovements({String? productId, int limit = 200});

  Future<void> receivePurchase({
    required String productId,
    required int quantity,
    required double unitCost,
    String? notes,
  });

  Future<void> issueStock({
    required String technicianId,
    required List<({String productId, int quantity})> items,
    String? notes,
  });
}

class SupabaseInventoryRepository implements InventoryRepository {
  final SupabaseClient _client;
  SupabaseInventoryRepository(this._client);

  @override
  Future<List<WarehouseStockItem>> getWarehouseStock({String? search}) async {
    try {
      var query = _client
          .from('warehouse_stock')
          .select('quantity, products!inner(id, name, sku, cost_price, selling_price, min_stock)');
      if (search != null && search.trim().isNotEmpty) {
        query = query.ilike('products.name', '%${search.trim()}%');
      }
      final rows = await query;
      final items = rows.map(WarehouseStockItem.fromRow).toList()
        ..sort((a, b) => a.productName.compareTo(b.productName));
      return items;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<TechnicianBagStockItem>> getBagStock(String technicianId) async {
    try {
      final row = await _client
          .from('technician_bags')
          .select(
              'technician_bag_stock(quantity, products(id, name, sku, cost_price, selling_price))')
          .eq('technician_id', technicianId)
          .maybeSingle();
      if (row == null) return [];
      final stockRows = (row['technician_bag_stock'] as List).cast<Map<String, dynamic>>();
      final items = stockRows
          .where((r) => (r['quantity'] as int) > 0)
          .map(TechnicianBagStockItem.fromRow)
          .toList()
        ..sort((a, b) => a.productName.compareTo(b.productName));
      return items;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<StockMovement>> getStockMovements({String? productId, int limit = 200}) async {
    try {
      var query = _client.from('stock_movements').select('''
            id, movement_number, movement_type, quantity, from_location_type,
            to_location_type, unit_cost, total_cost, notes, created_at,
            products!inner(id, name)
          ''');
      if (productId != null) query = query.eq('product_id', productId);
      final rows = await query.order('created_at', ascending: false).limit(limit);
      return rows.map(StockMovement.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> receivePurchase({
    required String productId,
    required int quantity,
    required double unitCost,
    String? notes,
  }) async {
    try {
      await _client.rpc('rpc_receive_purchase', params: {
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_unit_cost': unitCost,
        'p_notes': notes,
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<void> issueStock({
    required String technicianId,
    required List<({String productId, int quantity})> items,
    String? notes,
  }) async {
    try {
      await _client.rpc('rpc_issue_stock_to_technician', params: {
        'p_technician_id': technicianId,
        'p_items': items.map((e) => {'product_id': e.productId, 'quantity': e.quantity}).toList(),
        'p_notes': notes,
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
