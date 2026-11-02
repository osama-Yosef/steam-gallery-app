import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/report_models.dart';
import '../sales_totals.dart';

abstract class ReportsRepository {
  Future<SalesReport> getSalesReport(DateTime from, DateTime to);
  Future<ProfitReport> getProfitReport(DateTime from, DateTime to);
  Future<OrdersProfitReport> getOrdersProfitReport(DateTime from, DateTime to);
  Future<ExpensesReport> getExpensesReport(DateTime from, DateTime to);
  Future<InventoryReport> getInventoryReport(DateTime from, DateTime to);
  Future<EmployeesReport> getEmployeesReport(DateTime from, DateTime to);

  /// The month containing [month], worked out on the server (0092).
  Future<MonthReport> getMonthReport(DateTime month);
}

class SupabaseReportsRepository implements ReportsRepository {
  final SupabaseClient _client;
  SupabaseReportsRepository(this._client);

  /// UTC with an explicit offset: a bare local timestamp is read by the
  /// server as UTC, which shifted every report range by Cairo's 3 hours.
  String _iso(DateTime d) => d.toUtc().toIso8601String();

  /// Shared by the Sales and Profit reports: the counted invoices in
  /// [from, to) as they stand after their last edit (see [SalesTotals]).
  Future<SalesTotals> _salesTotals(DateTime from, DateTime to) async {
    final (sales, orders) = await (
      _allRows(
        () => _client
            .from('sales')
            .select('id, total, discount')
            .eq('status', 'completed')
            .gte('created_at', _iso(from))
            .lt('created_at', _iso(to))
            .order('id'),
      ),
      _allRows(
        () => _client
            .from('orders')
            .select(
              'id, total, discount, order_items(quantity, unit_cost_snapshot, discount)',
            )
            .inFilter('status', [
              'confirmed',
              'preparing',
              'delivered',
              'completed',
            ])
            .gte('created_at', _iso(from))
            .lt('created_at', _iso(to))
            .order('id'),
      ),
    ).wait;

    final ids = [for (final s in sales) s['id'] as String];
    final saleLines = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += 100) {
      final chunk = ids.sublist(i, i + 100 > ids.length ? ids.length : i + 100);
      saleLines.addAll(
        await _allRows(
          () => _client
              .from('sale_items_with_returns')
              .select(
                'id, sale_id, quantity, returned_quantity, unit_price_snapshot, unit_cost_snapshot, discount',
              )
              .inFilter('sale_id', chunk)
              .order('id'),
        ),
      );
    }

    return SalesTotals.from(sales: sales, saleLines: saleLines, orders: orders);
  }

  /// Every row of [query], a page at a time: the server returns at most
  /// 1000 rows per request, which a long range can pass. [query] must be
  /// ordered on a unique column so pages don't overlap.
  Future<List<Map<String, dynamic>>> _allRows(
    PostgrestTransformBuilder<List<Map<String, dynamic>>> Function() query,
  ) async {
    const page = 1000;
    final rows = <Map<String, dynamic>>[];
    while (true) {
      final batch = await query().range(rows.length, rows.length + page - 1);
      rows.addAll(batch);
      if (batch.length < page) return rows;
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

  /// Sales as the invoices stand after their last edit: an edited or
  /// partly returned invoice counts at what it is now, once. What edits and
  /// returns took off is shown as [SalesReport.returns], already left out.
  @override
  Future<SalesReport> getSalesReport(DateTime from, DateTime to) async {
    try {
      final t = await _salesTotals(from, to);
      return SalesReport(
        totalSales: t.gross,
        cogs: t.cost,
        grossProfit: t.net - t.cost,
        discounts: t.discounts,
        returns: t.removed,
        netSales: t.net,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<ProfitReport> getProfitReport(DateTime from, DateTime to) async {
    try {
      final t = await _salesTotals(from, to);
      final expenses = await _expensesInRange(from, to);
      final gross = t.net - t.cost;
      return ProfitReport(
        revenue: t.net,
        cogs: t.cost,
        grossProfit: gross,
        expenses: expenses,
        netProfit: gross - expenses,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Same revenue/COGS shape as the Sales report but scoped to `orders`
  /// alone (no technician walk-in `sales`), plus how many orders fell in
  /// range — for the "أرباح الطلبات" report (0046), which must read in
  /// isolation from the storefront's technician-sales channel.
  Future<({double revenue, double cogs, int orderCount})> _ordersRevenueAndCogs(
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

    double revenue = 0, cogs = 0;
    for (final row in orderRows) {
      final items = (row['order_items'] as List?) ?? [];
      for (final item in items) {
        final qty = (item['quantity'] as num).toInt();
        final price = (item['unit_price_snapshot'] as num).toDouble();
        final cost = (item['unit_cost_snapshot'] as num).toDouble();
        final itemDiscount = (item['discount'] as num).toDouble();
        revenue += qty * price - itemDiscount;
        cogs += qty * cost;
      }
    }
    return (revenue: revenue, cogs: cogs, orderCount: orderRows.length);
  }

  @override
  Future<OrdersProfitReport> getOrdersProfitReport(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final base = await _ordersRevenueAndCogs(from, to);
      return OrdersProfitReport(
        orderCount: base.orderCount,
        revenue: base.revenue,
        cogs: base.cogs,
        grossProfit: base.revenue - base.cogs,
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

  @override
  Future<EmployeesReport> getEmployeesReport(DateTime from, DateTime to) async {
    String day(DateTime d) => d.toIso8601String().split('T').first;
    try {
      final (employees, attendance, advances, payrolls) = await (
        _client
            .from('employee_balances')
            .select(
              'employee_id, full_name, job_title, monthly_salary, is_active, advance_balance',
            )
            .order('full_name'),
        _client
            .from('employee_attendance')
            .select('employee_id, status')
            .gte('work_date', day(from))
            .lt('work_date', day(to)),
        _client
            .from('employee_advances')
            .select('employee_id, amount')
            .gte('advance_date', day(from))
            .lt('advance_date', day(to)),
        // A salary counts in the period it was paid in.
        _client
            .from('employee_payrolls')
            .select('employee_id, net_amount')
            .gte('created_at', _iso(from))
            .lt('created_at', _iso(to)),
      ).wait;

      final days = <String, Map<String, int>>{};
      for (final a in attendance) {
        final byStatus = days.putIfAbsent(a['employee_id'] as String, () => {});
        final status = a['status'] as String;
        byStatus[status] = (byStatus[status] ?? 0) + 1;
      }
      final advanced = <String, double>{};
      for (final a in advances) {
        final id = a['employee_id'] as String;
        advanced[id] = (advanced[id] ?? 0) + (a['amount'] as num).toDouble();
      }
      final paid = <String, double>{};
      for (final p in payrolls) {
        final id = p['employee_id'] as String;
        paid[id] = (paid[id] ?? 0) + (p['net_amount'] as num).toDouble();
      }

      final rows = <EmployeeReportRow>[];
      for (final e in employees) {
        final id = e['employee_id'] as String;
        final isActive = e['is_active'] as bool;
        final d = days[id] ?? const {};
        final row = EmployeeReportRow(
          name: e['full_name'] as String,
          jobTitle: e['job_title'] as String?,
          monthlySalary: (e['monthly_salary'] as num).toDouble(),
          isActive: isActive,
          presentDays: d['present'] ?? 0,
          lateDays: d['late'] ?? 0,
          absentDays: d['absent'] ?? 0,
          leaveDays: d['leave'] ?? 0,
          advances: advanced[id] ?? 0,
          salariesPaid: paid[id] ?? 0,
          advanceBalance: (e['advance_balance'] as num).toDouble(),
        );
        // A stopped employee only shows when something happened in the
        // period or they still owe advances.
        final touched =
            d.isNotEmpty ||
            row.advances > 0 ||
            row.salariesPaid > 0 ||
            row.advanceBalance > 0;
        if (isActive || touched) rows.add(row);
      }
      return EmployeesReport(rows: rows);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<MonthReport> getMonthReport(DateTime month) async {
    final y = month.year.toString().padLeft(4, '0');
    final m = month.month.toString().padLeft(2, '0');
    try {
      final params = {'p_month': '$y-$m-01'};
      final res = await _client.rpc('rpc_month_report', params: params);
      ({StockValue start, StockValue end})? stock;
      try {
        final s = await _client.rpc('rpc_month_stock', params: params);
        stock = StockValue.pairFromRpc((s as Map).cast<String, dynamic>());
      } catch (_) {
        // A database without 0096: the report still shows, without it.
      }
      return MonthReport.fromRpc(
        (res as Map).cast<String, dynamic>(),
        stockOverMonth: stock,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
