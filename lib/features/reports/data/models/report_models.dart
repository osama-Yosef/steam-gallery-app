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

/// The whole month on one page (rpc_month_report, 0092). Debts and stock are
/// as of now, whichever month was asked for.
class MonthReport {
  final DateTime month;
  final double sales;
  final double salesWalkIn;
  final double salesTechnician;
  final double salesOnline;
  final int invoices;
  final double cost;
  final double grossProfit;
  final double expenses;
  final List<ExpenseCategoryTotal> expenseCategories;
  final double netProfit;
  final double purchases;
  final int purchaseInvoices;
  final double supplierPayments;
  final double supplierDebt;
  final List<({String name, double balance})> supplierDebts;
  final double stockWarehouse;
  final double stockBags;

  const MonthReport({
    required this.month,
    required this.sales,
    required this.salesWalkIn,
    required this.salesTechnician,
    required this.salesOnline,
    required this.invoices,
    required this.cost,
    required this.grossProfit,
    required this.expenses,
    required this.expenseCategories,
    required this.netProfit,
    required this.purchases,
    required this.purchaseInvoices,
    required this.supplierPayments,
    required this.supplierDebt,
    required this.supplierDebts,
    required this.stockWarehouse,
    required this.stockBags,
  });

  double get stockTotal => stockWarehouse + stockBags;

  factory MonthReport.fromRpc(Map<String, dynamic> j) {
    double n(String key) => (j[key] as num).toDouble();
    return MonthReport(
      month: DateTime.parse(j['month'] as String),
      sales: n('sales'),
      salesWalkIn: n('sales_walk_in'),
      salesTechnician: n('sales_technician'),
      salesOnline: n('sales_online'),
      invoices: (j['invoices'] as num).toInt(),
      cost: n('cost'),
      grossProfit: n('gross_profit'),
      expenses: n('expenses'),
      expenseCategories: [
        for (final c in j['expense_categories'] as List)
          ExpenseCategoryTotal(
            categoryName: c['name'] as String,
            total: (c['total'] as num).toDouble(),
          ),
      ],
      netProfit: n('net_profit'),
      purchases: n('purchases'),
      purchaseInvoices: (j['purchase_invoices'] as num).toInt(),
      supplierPayments: n('supplier_payments'),
      supplierDebt: n('supplier_debt'),
      supplierDebts: [
        for (final s in j['supplier_debts'] as List)
          (
            name: s['name'] as String,
            balance: (s['balance'] as num).toDouble(),
          ),
      ],
      stockWarehouse: n('stock_warehouse'),
      stockBags: n('stock_bags'),
    );
  }
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

  double get totalMonthlySalaries =>
      rows.where((r) => r.isActive).fold(0, (s, r) => s + r.monthlySalary);
  double get totalAdvances => rows.fold(0, (s, r) => s + r.advances);
  double get totalSalariesPaid => rows.fold(0, (s, r) => s + r.salariesPaid);
  double get totalAdvanceBalance =>
      rows.fold(0, (s, r) => s + r.advanceBalance);
}
