import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/report_models.dart';

abstract class ReportsRepository {
  Future<List<SalesPeriodSummary>> getDailySales({int days = 30});
  Future<List<SalesPeriodSummary>> getMonthlySales({int months = 12});
  Future<double> getWarehouseStockValue();
  Future<List<LowStockProduct>> getLowStockProducts();
  Future<List<TechnicianAccountReportRow>> getTechnicianAccounts();
  Future<List<CustomerAccountReportRow>> getCustomerAccounts();
}

class SupabaseReportsRepository implements ReportsRepository {
  final SupabaseClient _client;
  SupabaseReportsRepository(this._client);

  @override
  Future<List<SalesPeriodSummary>> getDailySales({int days = 30}) async {
    try {
      final rows =
          await _client.from('daily_sales_summary').select().order('day', ascending: false).limit(days);
      return rows.map((r) => SalesPeriodSummary.fromRow(r, 'day')).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<SalesPeriodSummary>> getMonthlySales({int months = 12}) async {
    try {
      final rows = await _client
          .from('monthly_sales_summary')
          .select()
          .order('month', ascending: false)
          .limit(months);
      return rows.map((r) => SalesPeriodSummary.fromRow(r, 'month')).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<double> getWarehouseStockValue() async {
    try {
      final rows = await _client.from('warehouse_stock_value').select('stock_value');
      return rows.fold<double>(0, (sum, r) => sum + (r['stock_value'] as num).toDouble());
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<LowStockProduct>> getLowStockProducts() async {
    try {
      final rows = await _client.from('low_stock_products').select().order('current_quantity');
      return rows.map(LowStockProduct.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<TechnicianAccountReportRow>> getTechnicianAccounts() async {
    try {
      final rows = await _client.from('technician_account_summary').select();
      return rows.map(TechnicianAccountReportRow.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  @override
  Future<List<CustomerAccountReportRow>> getCustomerAccounts() async {
    try {
      final rows = await _client.from('customer_account_summary').select();
      return rows.map(CustomerAccountReportRow.fromRow).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
