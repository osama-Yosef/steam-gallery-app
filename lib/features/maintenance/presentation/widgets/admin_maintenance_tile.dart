import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/maintenance_request.dart';
import 'maintenance_status_chips.dart';

/// A full-width, colour-coded card — same visual language as the customer
/// maintenance tile and the admin order tile, so the status colour says
/// what stage a request is at before its label is even read.
class AdminMaintenanceTile extends StatelessWidget {
  final MaintenanceRequest request;
  const AdminMaintenanceTile({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final color = maintenanceStatusColor(request.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: color.withValues(alpha: 0.08),
          child: InkWell(
            onTap: () =>
                context.push(Routes.adminMaintenanceDetail(request.id)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                    child: const Icon(
                      Iconsax.setting_2_copy,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.customerName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${request.ticketNumber} · ${request.phone} · ${Formatters.date(request.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      maintenanceStatusLabelAr(request.status),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
