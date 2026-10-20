import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/dashboard_summary.dart';

/// The Cairo calendar day of a daily_sales_summary `day` (0078): midnight in
/// Cairo, sent as a UTC instant (e.g. 2026-10-14T21:00:00+00:00 for the
/// 15th). Converting it to the phone's own zone put today's sales on
/// yesterday whenever the phone wasn't on Cairo time, so the dashboard
/// showed 0 for today. Noon UTC of that instant is always the Cairo date,
/// whatever zone the phone is set to.
DateTime cairoDay(String day) {
  final noon = DateTime.parse(day).toUtc().add(const Duration(hours: 12));
  return DateTime(noon.year, noon.month, noon.day);
}

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
        // 0059 split this into two rows (cash + transfer) — the dashboard
        // figure is the business's total across both, not one arbitrary row.
        _client.from('cashbox_balances').select(),
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
        _client
            .from('technicians')
            .select('id, users!technicians_id_fkey(role)')
            .eq('is_active', true),
        _client.from('low_stock_products').select('product_id'),
        _client.from('customer_account_summary').select('remaining_balance'),
        _client.from('technician_account_summary').select('amount_due'),
        _client.from('warehouse_stock_value').select().limit(1).maybeSingle(),
        _client
            .from('wallet_liability_summary')
            .select()
            .limit(1)
            .maybeSingle(),
        _client.from('supplier_balances').select('balance'),
      ]);

      final balanceRows = (results[0] as List).cast<Map<String, dynamic>>();
      final totalCashboxBalance = balanceRows.fold<double>(
        0,
        (sum, r) => sum + (r['balance'] as num).toDouble(),
      );
      final dailyRows = (results[1] as List).cast<Map<String, dynamic>>();
      final expenseRows = (results[2] as List).cast<Map<String, dynamic>>();
      final pendingOrders = results[3] as List;
      final activeMaintenance = results[4] as List;
      // Only users who are still technicians (see listTechnicians).
      final activeTechnicians = (results[5] as List)
          .where((r) => (r['users'] as Map?)?['role'] == 'technician')
          .toList();
      final lowStock = results[6] as List;
      final customerAccounts = (results[7] as List)
          .cast<Map<String, dynamic>>();
      final technicianAccounts = (results[8] as List)
          .cast<Map<String, dynamic>>();
      final warehouseValueRow = results[9] as Map<String, dynamic>?;
      final walletLiabilityRow = results[10] as Map<String, dynamic>?;
      final supplierRows = (results[11] as List).cast<Map<String, dynamic>>();

      final now = DateTime.now();
      // Dates already in local terms: their own calendar day.
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
        final day = cairoDay(row['day'] as String);
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

      double monthExpenses = 0, todayExpenses = 0;
      for (final row in expenseRows) {
        final date = DateTime.parse(row['expense_date'] as String);
        final amount = (row['amount'] as num).toDouble();
        if (isThisMonth(date)) monthExpenses += amount;
        if (isToday(date)) todayExpenses += amount;
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

      // What the shop still owes its suppliers (same sum as the suppliers
      // screen's total: only balances above zero).
      double supplierDebts = 0;
      for (final row in supplierRows) {
        final v = (row['balance'] as num).toDouble();
        if (v > 0) supplierDebts += v;
      }

      return DashboardSummary(
        cashboxBalance: totalCashboxBalance,
        todayRevenue: todayRevenue,
        todayNetProfit: todayRevenue - todayCogs,
        monthRevenue: monthRevenue,
        monthNetProfit: monthRevenue - monthCogs - monthExpenses,
        monthExpenses: monthExpenses,
        todayExpenses: todayExpenses,
        pendingOrdersCount: pendingOrders.length,
        activeMaintenanceCount: activeMaintenance.length,
        activeTechniciansCount: activeTechnicians.length,
        lowStockCount: lowStock.length,
        customerDebtsTotal: customerDebts,
        technicianDuesTotal: technicianDues,
        warehouseStockValue:
            (warehouseValueRow?['stock_value'] as num?)?.toDouble() ?? 0,
        walletLiabilityTotal:
            (walletLiabilityRow?['total_liability'] as num?)?.toDouble() ?? 0,
        supplierDebtsTotal: supplierDebts,
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
