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

/// Profit from orders only (0046) — unlike [ProfitReport], this deliberately
/// excludes technician walk-in sales, so an admin can see how the storefront
/// itself is performing in isolation.
class OrdersProfitReport {
  final int orderCount;
  final double revenue;
  final double cogs;
  final double grossProfit;

  const OrdersProfitReport({
    required this.orderCount,
    required this.revenue,
    required this.cogs,
    required this.grossProfit,
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

/// One employee over the report's period: attendance, advances taken and
/// salaries paid in it, and the advances still owed today.
class EmployeeReportRow {
  final String name;
  final String? jobTitle;
  final double monthlySalary;
  final bool isActive;
  final int presentDays;
  final int lateDays;
  final int absentDays;
  final int leaveDays;
  final double advances;
  final double salariesPaid;
  final double advanceBalance;

  const EmployeeReportRow({
    required this.name,
    required this.jobTitle,
    required this.monthlySalary,
    required this.isActive,
    required this.presentDays,
    required this.lateDays,
    required this.absentDays,
    required this.leaveDays,
    required this.advances,
    required this.salariesPaid,
    required this.advanceBalance,
  });
}

class EmployeesReport {
  final List<EmployeeReportRow> rows;

  const EmployeesReport({required this.rows});

  double get totalMonthlySalaries => rows
      .where((r) => r.isActive)
      .fold(0, (s, r) => s + r.monthlySalary);
  double get totalAdvances => rows.fold(0, (s, r) => s + r.advances);
  double get totalSalariesPaid => rows.fold(0, (s, r) => s + r.salariesPaid);
  double get totalAdvanceBalance =>
      rows.fold(0, (s, r) => s + r.advanceBalance);
}
