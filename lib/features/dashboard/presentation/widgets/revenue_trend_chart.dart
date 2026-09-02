import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/dashboard_summary.dart';

/// Deliberately dependency-free bar chart (no fl_chart) — simple enough
/// that plain Flutter widgets do the job for a 7-point trend without
/// pulling in a charting package for one visual.
class RevenueTrendChart extends StatelessWidget {
  final List<DailyRevenuePoint> points;
  const RevenueTrendChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 140, child: Center(child: Text('لا توجد بيانات مبيعات بعد')));
    }
    final maxValue = points.map((p) => p.revenue).fold<double>(0, (a, b) => a > b ? a : b);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((p) {
          final heightFactor = maxValue == 0 ? 0.02 : (p.revenue / maxValue).clamp(0.02, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    p.revenue > 0 ? Formatters.currency(p.revenue).replaceAll(' ج.م', '') : '',
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 100 * heightFactor,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_weekdayAr(p.day.weekday), style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _weekdayAr(int weekday) => const ['اث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'][weekday - 1];
}
