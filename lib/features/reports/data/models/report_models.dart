/// Plain (non-freezed) DTOs — these are computed client-side by aggregating
/// several queries for a date range, not parsed 1:1 from a single row, so
/// there's nothing freezed/copyWith buys here.
class SalesReport {
  final double totalSales;
  final double cogs;
  final double grossProfit;
  final double discounts;
  final double returns;
  final double netSales;

  const SalesReport({
    required this.totalSales,
    required this.cogs,
    required this.grossProfit,
    required this.discounts,
    required this.returns,
    required this.netSales,
  });
}

class ProfitReport {
  final double revenue;
  final double cogs;
  final double grossProfit;
  final double expenses;
  final double netProfit;

  const ProfitReport({
    required this.revenue,
    required this.cogs,
    required this.grossProfit,
    required this.expenses,
    required this.netProfit,
  });
}

class ExpenseCategoryTotal {
  final String categoryName;
  final double total;
  const ExpenseCategoryTotal({required this.categoryName, required this.total});
}

class ExpenseLine {
  final String categoryName;
  final double amount;
  final DateTime date;
  final String? notes;
  const ExpenseLine({
    required this.categoryName,
    required this.amount,
    required this.date,
    this.notes,
  });
}

class ExpensesReport {
  final double total;
  final List<ExpenseCategoryTotal> byCategory;
  final List<ExpenseLine> topExpenses;
  final List<ExpenseLine> all;

  const ExpensesReport({
    required this.total,
    required this.byCategory,
    required this.topExpenses,
    required this.all,
  });
}

class StockMovementTypeTotal {
  final String movementType;
  final int count;
  final double totalCost;
  const StockMovementTypeTotal({
    required this.movementType,
    required this.count,
    required this.totalCost,
  });
}

class InventoryReport {
  final double warehouseStockValue;
  final int lowStockCount;
  final List<StockMovementTypeTotal> movementsByType;

  const InventoryReport({
    required this.warehouseStockValue,
    required this.lowStockCount,
    required this.movementsByType,
  });
}
