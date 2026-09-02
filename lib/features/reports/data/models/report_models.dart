/// Plain read-only view rows for the reports screen — no freezed/equality
/// needed, these are display-only and never round-tripped back to the DB.
library;

class SalesPeriodSummary {
  final DateTime period;
  final double revenue;
  final double cogs;
  double get profit => revenue - cogs;

  SalesPeriodSummary({required this.period, required this.revenue, required this.cogs});

  factory SalesPeriodSummary.fromRow(Map<String, dynamic> row, String periodKey) => SalesPeriodSummary(
        period: DateTime.parse(row[periodKey] as String),
        revenue: (row['revenue'] as num).toDouble(),
        cogs: (row['cogs'] as num).toDouble(),
      );
}

class LowStockProduct {
  final String productId;
  final String name;
  final String sku;
  final int minStock;
  final int currentQuantity;

  LowStockProduct({
    required this.productId,
    required this.name,
    required this.sku,
    required this.minStock,
    required this.currentQuantity,
  });

  factory LowStockProduct.fromRow(Map<String, dynamic> row) => LowStockProduct(
        productId: row['product_id'] as String,
        name: row['name'] as String,
        sku: row['sku'] as String,
        minStock: row['min_stock'] as int,
        currentQuantity: row['current_quantity'] as int,
      );
}

class TechnicianAccountReportRow {
  final String technicianId;
  final String technicianName;
  final double bagValue;
  final double totalSales;
  final double totalCollected;
  final double amountDue;

  TechnicianAccountReportRow({
    required this.technicianId,
    required this.technicianName,
    required this.bagValue,
    required this.totalSales,
    required this.totalCollected,
    required this.amountDue,
  });

  factory TechnicianAccountReportRow.fromRow(Map<String, dynamic> row) => TechnicianAccountReportRow(
        technicianId: row['technician_id'] as String,
        technicianName: row['technician_name'] as String,
        bagValue: (row['bag_value'] as num).toDouble(),
        totalSales: (row['total_sales'] as num).toDouble(),
        totalCollected: (row['total_collected'] as num).toDouble(),
        amountDue: (row['amount_due'] as num).toDouble(),
      );
}

class CustomerAccountReportRow {
  final String customerId;
  final String customerName;
  final double totalPurchases;
  final double totalPaid;
  final double remainingBalance;

  CustomerAccountReportRow({
    required this.customerId,
    required this.customerName,
    required this.totalPurchases,
    required this.totalPaid,
    required this.remainingBalance,
  });

  factory CustomerAccountReportRow.fromRow(Map<String, dynamic> row) => CustomerAccountReportRow(
        customerId: row['customer_id'] as String,
        customerName: row['customer_name'] as String,
        totalPurchases: (row['total_purchases'] as num).toDouble(),
        totalPaid: (row['total_paid'] as num).toDouble(),
        remainingBalance: (row['remaining_balance'] as num).toDouble(),
      );
}

class ExpenseCategoryTotal {
  final String categoryName;
  final double total;
  ExpenseCategoryTotal({required this.categoryName, required this.total});
}
