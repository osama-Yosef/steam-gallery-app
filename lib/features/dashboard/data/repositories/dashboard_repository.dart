import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/dashboard_summary.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getSummary();

  /// Last 7 days of revenue, oldest first, for the trend chart.
  Future<List<DailyRevenuePoint>> getRevenueTrend({int days = 7});
}

class SupabaseDashboardRepository implements DashboardRepository {
  final SupabaseClient _client;
  SupabaseDashboardRepository(this._client);

  @override
  Future<DashboardSummary> getSummary() async {
    try {
      final results = await Future.wait<dynamic>([
        _client.from('cashbox_balances').select().limit(1).maybeSingle(),
        // 31 days is enough to derive both "today" and "this month" client-side
        // without fighting DB-vs-device timezone truncation on the view itself.
        _client
            .from('daily_sales_summary')
            .select()
            .order('day', ascending: false)
            .limit(31),
        _client.from('expenses').select('amount, expense_date'),
        _client.from('orders').select('id').eq('status', 'pending'),
        _client.from('maintenance_requests').select('id').inFilter('status', [
          'waiting',
          'assigned',
          'in_progress',
        ]),
        _client.from('technicians').select('id').eq('is_active', true),
        _client.from('low_stock_products').select('product_id'),
        _client.from('customer_account_summary').select('remaining_balance'),
        _client.from('technician_account_summary').select('amount_due'),
        _client.from('warehouse_stock_value').select().limit(1).maybeSingle(),
      ]);

      final balanceRow = results[0] as Map<String, dynamic>?;
      final dailyRows = (results[1] as List).cast<Map<String, dynamic>>();
      final expenseRows = (results[2] as List).cast<Map<String, dynamic>>();
      final pendingOrders = results[3] as List;
      final activeMaintenance = results[4] as List;
      final activeTechnicians = results[5] as List;
      final lowStock = results[6] as List;
      final customerAccounts = (results[7] as List)
          .cast<Map<String, dynamic>>();
      final technicianAccounts = (results[8] as List)
          .cast<Map<String, dynamic>>();
      final warehouseValueRow = results[9] as Map<String, dynamic>?;

      final now = DateTime.now();
      bool isToday(DateTime d) {
        final local = d.toLocal();
        return local.year == now.year &&
            local.month == now.month &&
            local.day == now.day;
      }

      bool isThisMonth(DateTime d) {
        final local = d.toLocal();
        return local.year == now.year && local.month == now.month;
      }

      double todayRevenue = 0, todayCogs = 0, monthRevenue = 0, monthCogs = 0;
      for (final row in dailyRows) {
        final day = DateTime.parse(row['day'] as String);
        final revenue = (row['revenue'] as num).toDouble();
        final cogs = (row['cogs'] as num).toDouble();
        if (isToday(day)) {
          todayRevenue += revenue;
          todayCogs += cogs;
        }
        if (isThisMonth(day)) {
          monthRevenue += revenue;
          monthCogs += cogs;
        }
      }

      double monthExpenses = 0;
      for (final row in expenseRows) {
        final date = DateTime.parse(row['expense_date'] as String);
        if (isThisMonth(date)) {
          monthExpenses += (row['amount'] as num).toDouble();
        }
      }

      double customerDebts = 0;
      for (final row in customerAccounts) {
        final v = (row['remaining_balance'] as num).toDouble();
        if (v > 0) customerDebts += v;
      }

      double technicianDues = 0;
      for (final row in technicianAccounts) {
        final v = (row['amount_due'] as num).toDouble();
        if (v > 0) technicianDues += v;
      }

      return DashboardSummary(
        cashboxBalance: (balanceRow?['balance'] as num?)?.toDouble() ?? 0,
        todayRevenue: todayRevenue,
        todayNetProfit: todayRevenue - todayCogs,
        monthRevenue: monthRevenue,
        monthNetProfit: monthRevenue - monthCogs - monthExpenses,
        monthExpenses: monthExpenses,
        pendingOrdersCount: pendingOrders.length,
        activeMaintenanceCount: activeMaintenance.length,
        activeTechniciansCount: activeTechnicians.length,
        lowStockCount: lowStock.length,
        customerDebtsTotal: customerDebts,
        technicianDuesTotal: technicianDues,
        warehouseStockValue:
            (warehouseValueRow?['stock_value'] as num?)?.toDouble() ?? 0,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<DailyRevenuePoint>> getRevenueTrend({int days = 7}) async {
    try {
      final rows = await _client
          .from('daily_sales_summary')
          .select()
          .order('day', ascending: false)
          .limit(days);
      final points = rows.map((r) => DailyRevenuePoint.fromRow(r)).toList();
      return points.reversed.toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
