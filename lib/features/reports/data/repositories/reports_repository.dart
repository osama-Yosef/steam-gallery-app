import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/report_models.dart';

abstract class ReportsRepository {
  Future<SalesReport> getSalesReport(DateTime from, DateTime to);
  Future<ProfitReport> getProfitReport(DateTime from, DateTime to);
  Future<ExpensesReport> getExpensesReport(DateTime from, DateTime to);
  Future<InventoryReport> getInventoryReport(DateTime from, DateTime to);
}

class SupabaseReportsRepository implements ReportsRepository {
  final SupabaseClient _client;
  SupabaseReportsRepository(this._client);

  String _iso(DateTime d) => d.toIso8601String();

  /// Shared building block for both the Sales and Profit reports: revenue,
  /// COGS and item-level discounts from confirmed orders + completed
  /// technician sales in [from, to). See docs/03-business-logic.md §11.
  Future<({double revenue, double cogs, double discounts})> _revenueAndCogs(
    DateTime from,
    DateTime to,
  ) async {
    final orderRows = await _client
        .from('orders')
        .select(
          'discount, order_items(quantity, unit_price_snapshot, unit_cost_snapshot, discount)',
        )
        .inFilter('status', [
          'confirmed',
          'preparing',
          'delivered',
          'completed',
        ])
        .gte('created_at', _iso(from))
        .lt('created_at', _iso(to));

    final saleRows = await _client
        .from('sales')
        .select(
          'discount, sale_items(quantity, unit_price_snapshot, unit_cost_snapshot, discount)',
        )
        .eq('status', 'completed')
        .gte('created_at', _iso(from))
        .lt('created_at', _iso(to));

    double revenue = 0, cogs = 0, discounts = 0;

    void accumulate(List rows, String itemsKey) {
      for (final row in rows) {
        final items = (row[itemsKey] as List?) ?? [];
        for (final item in items) {
          final qty = (item['quantity'] as num).toInt();
          final price = (item['unit_price_snapshot'] as num).toDouble();
          final cost = (item['unit_cost_snapshot'] as num).toDouble();
          final itemDiscount = (item['discount'] as num).toDouble();
          revenue += qty * price - itemDiscount;
          cogs += qty * cost;
          discounts += itemDiscount;
        }
        discounts += (row['discount'] as num? ?? 0).toDouble();
      }
    }

    accumulate(orderRows, 'order_items');
    accumulate(saleRows, 'sale_items');

    return (revenue: revenue, cogs: cogs, discounts: discounts);
  }

  Future<double> _returnsInRange(DateTime from, DateTime to) async {
    try {
      final rows = await _client
          .from('customer_account_transactions')
          .select('amount')
          .eq('transaction_type', 'return_credit')
          .gte('created_at', _iso(from))
          .lt('created_at', _iso(to));
      double total = 0;
      for (final row in rows) {
        total += (row['amount'] as num).abs().toDouble();
      }
      return total;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<double> _expensesInRange(DateTime from, DateTime to) async {
    final rows = await _client
        .from('expenses')
        .select('amount')
        .gte('expense_date', from.toIso8601String().split('T').first)
        .lt('expense_date', to.toIso8601String().split('T').first);
    double total = 0;
    for (final row in rows) {
      total += (row['amount'] as num).toDouble();
    }
    return total;
  }

  @override
  Future<SalesReport> getSalesReport(DateTime from, DateTime to) async {
    try {
      final base = await _revenueAndCogs(from, to);
      final returns = await _returnsInRange(from, to);
      final netSales = base.revenue - returns;
      return SalesReport(
        totalSales: base.revenue,
        cogs: base.cogs,
        grossProfit: base.revenue - base.cogs,
        discounts: base.discounts,
        returns: returns,
        netSales: netSales,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<ProfitReport> getProfitReport(DateTime from, DateTime to) async {
    try {
      final base = await _revenueAndCogs(from, to);
      final expenses = await _expensesInRange(from, to);
      final gross = base.revenue - base.cogs;
      return ProfitReport(
        revenue: base.revenue,
        cogs: base.cogs,
        grossProfit: gross,
        expenses: expenses,
        netProfit: gross - expenses,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<ExpensesReport> getExpensesReport(DateTime from, DateTime to) async {
    try {
      final rows = await _client
          .from('expenses')
          .select('amount, expense_date, notes, expense_categories(name)')
          .gte('expense_date', from.toIso8601String().split('T').first)
          .lt('expense_date', to.toIso8601String().split('T').first)
          .order('expense_date', ascending: false);

      final lines = rows.map((row) {
        final categoryName =
            (row['expense_categories'] as Map?)?['name'] as String? ??
            'غير مصنَّف';
        return ExpenseLine(
          categoryName: categoryName,
          amount: (row['amount'] as num).toDouble(),
          date: DateTime.parse(row['expense_date'] as String),
          notes: row['notes'] as String?,
        );
      }).toList();

      final byCategory = <String, double>{};
      double total = 0;
      for (final l in lines) {
        byCategory[l.categoryName] =
            (byCategory[l.categoryName] ?? 0) + l.amount;
        total += l.amount;
      }

      final categoryTotals =
          byCategory.entries
              .map(
                (e) =>
                    ExpenseCategoryTotal(categoryName: e.key, total: e.value),
              )
              .toList()
            ..sort((a, b) => b.total.compareTo(a.total));

      final top = [...lines]..sort((a, b) => b.amount.compareTo(a.amount));

      return ExpensesReport(
        total: total,
        byCategory: categoryTotals,
        topExpenses: top.take(5).toList(),
        all: lines,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<InventoryReport> getInventoryReport(DateTime from, DateTime to) async {
    try {
      final results = await Future.wait<dynamic>([
        _client.from('warehouse_stock_value').select().limit(1).maybeSingle(),
        _client.from('low_stock_products').select('product_id'),
        _client
            .from('stock_movements')
            .select('movement_type, total_cost')
            .gte('created_at', _iso(from))
            .lt('created_at', _iso(to)),
      ]);

      final valueRow = results[0] as Map<String, dynamic>?;
      final lowStock = results[1] as List;
      final movementRows = (results[2] as List).cast<Map<String, dynamic>>();

      final byType = <String, ({int count, double totalCost})>{};
      for (final row in movementRows) {
        final type = row['movement_type'] as String;
        final cost = (row['total_cost'] as num).toDouble();
        final existing = byType[type];
        byType[type] = (
          count: (existing?.count ?? 0) + 1,
          totalCost: (existing?.totalCost ?? 0) + cost,
        );
      }

      return InventoryReport(
        warehouseStockValue:
            (valueRow?['stock_value'] as num?)?.toDouble() ?? 0,
        lowStockCount: lowStock.length,
        movementsByType: byType.entries
            .map(
              (e) => StockMovementTypeTotal(
                movementType: e.key,
                count: e.value.count,
                totalCost: e.value.totalCost,
              ),
            )
            .toList(),
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
