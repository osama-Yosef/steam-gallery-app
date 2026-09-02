import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_summary.freezed.dart';

@freezed
abstract class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    required double cashboxBalance,
    required double todayRevenue,
    required double todayNetProfit,
    required double monthRevenue,
    required double monthNetProfit,
    required double monthExpenses,
    required int pendingOrdersCount,
    required int activeMaintenanceCount,
    required int activeTechniciansCount,
    required int lowStockCount,
    required double customerDebtsTotal,
    required double technicianDuesTotal,
    required double warehouseStockValue,
  }) = _DashboardSummary;
}

/// One point in the "آخر 7 أيام" revenue trend chart.
@freezed
abstract class DailyRevenuePoint with _$DailyRevenuePoint {
  const factory DailyRevenuePoint({required DateTime day, required double revenue}) = _DailyRevenuePoint;

  factory DailyRevenuePoint.fromRow(Map<String, dynamic> row) => DailyRevenuePoint(
        day: DateTime.parse(row['day'] as String),
        revenue: (row['revenue'] as num).toDouble(),
      );
}
