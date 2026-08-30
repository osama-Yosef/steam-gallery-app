import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_movement.freezed.dart';

enum StockMovementType {
  purchase,
  sale,
  issueToTechnician,
  technicianSale,
  returnFromCustomer,
  returnToSupplier,
  damage,
  inventoryAdjustment,
  transfer,
}

StockMovementType stockMovementTypeFromString(String v) => switch (v) {
      'purchase' => StockMovementType.purchase,
      'sale' => StockMovementType.sale,
      'issue_to_technician' => StockMovementType.issueToTechnician,
      'technician_sale' => StockMovementType.technicianSale,
      'return_from_customer' => StockMovementType.returnFromCustomer,
      'return_to_supplier' => StockMovementType.returnToSupplier,
      'damage' => StockMovementType.damage,
      'inventory_adjustment' => StockMovementType.inventoryAdjustment,
      'transfer' => StockMovementType.transfer,
      _ => StockMovementType.purchase,
    };

String stockMovementTypeLabelAr(StockMovementType t) => switch (t) {
      StockMovementType.purchase => 'شراء',
      StockMovementType.sale => 'بيع',
      StockMovementType.issueToTechnician => 'صرف لصنايعي',
      StockMovementType.technicianSale => 'بيع صنايعي',
      StockMovementType.returnFromCustomer => 'مرتجع عميل',
      StockMovementType.returnToSupplier => 'مرتجع لمورد',
      StockMovementType.damage => 'تالف',
      StockMovementType.inventoryAdjustment => 'تسوية جرد',
      StockMovementType.transfer => 'نقل',
    };

String locationTypeLabelAr(String? t) => switch (t) {
      'warehouse' => 'المخزن الرئيسي',
      'technician_bag' => 'شنطة صنايعي',
      'external' => 'خارجي',
      _ => '—',
    };

@freezed
abstract class StockMovement with _$StockMovement {
  const factory StockMovement({
    required String id,
    required int movementNumber,
    required String productId,
    required String productName,
    required StockMovementType movementType,
    required int quantity,
    String? fromLocationType,
    String? toLocationType,
    required double unitCost,
    required double totalCost,
    String? notes,
    required DateTime createdAt,
  }) = _StockMovement;

  factory StockMovement.fromRow(Map<String, dynamic> row) {
    final product = row['products'] as Map<String, dynamic>;
    return StockMovement(
      id: row['id'] as String,
      movementNumber: row['movement_number'] as int,
      productId: product['id'] as String,
      productName: product['name'] as String,
      movementType: stockMovementTypeFromString(row['movement_type'] as String),
      quantity: row['quantity'] as int,
      fromLocationType: row['from_location_type'] as String?,
      toLocationType: row['to_location_type'] as String?,
      unitCost: (row['unit_cost'] as num).toDouble(),
      totalCost: (row['total_cost'] as num).toDouble(),
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
