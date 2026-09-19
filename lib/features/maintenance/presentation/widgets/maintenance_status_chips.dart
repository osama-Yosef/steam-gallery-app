import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/maintenance_request.dart';

Color maintenanceStatusColor(MaintenanceStatus s) => switch (s) {
  MaintenanceStatus.waiting => AppColors.warning,
  MaintenanceStatus.assigned || MaintenanceStatus.inProgress => AppColors.info,
  MaintenanceStatus.completed => AppColors.success,
  MaintenanceStatus.cancelled => AppColors.danger,
};

/// A compact, colour-coded status pill — mirrors [OrderStatusChip]'s look so
/// orders and maintenance read as one consistent system.
class MaintenanceStatusChip extends StatelessWidget {
  final MaintenanceStatus status;
  const MaintenanceStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = maintenanceStatusColor(status);
    return Chip(
      label: Text(maintenanceStatusLabelAr(status)),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color),
      side: BorderSide.none,
    );
  }
}
