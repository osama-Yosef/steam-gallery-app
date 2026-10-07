import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/maps_launcher.dart';
import '../../../../locations/presentation/providers/locations_providers.dart';
import '../../../data/models/order.dart';

/// Everything about where the order goes, laid out clearly in one place —
/// city/area (looked up client-side, since the realtime `orders` stream
/// can't embed a join), the full snapshotted address, and a direct link to
/// the pin on the map when coordinates are on file.
class OrderAddressCard extends ConsumerWidget {
  final Order order;
  const OrderAddressCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(citiesProvider(activeOnly: false));
    final cityId = order.deliveryCityId;
    final cityName = citiesAsync.value
        ?.where((c) => c.id == cityId)
        .firstOrNull
        ?.nameAr;
    final serviceAreasAsync = cityId == null
        ? null
        : ref.watch(serviceAreasProvider(cityId, activeOnly: false));
    final areaName = serviceAreasAsync?.value
        ?.where((a) => a.id == order.deliveryServiceAreaId)
        .firstOrNull
        ?.nameAr;
    final hasCoordinates =
        order.deliveryLatitude != null && order.deliveryLongitude != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.location_copy, size: 18),
                const SizedBox(width: 6),
                Text(
                  'عنوان التوصيل',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (order.deliveryRecipientName != null ||
                order.deliveryPhone != null)
              Text(
                [
                  if (order.deliveryRecipientName != null)
                    order.deliveryRecipientName!,
                  if (order.deliveryPhone != null) order.deliveryPhone!,
                ].join(' — '),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            if (cityName != null || areaName != null)
              Text(
                [?cityName, ?areaName].join(' — '),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            const SizedBox(height: 4),
            Text(order.deliveryAddress!),
            if (order.deliveryDetailsLine.isNotEmpty)
              Text(order.deliveryDetailsLine),
            if (order.deliveryLandmark != null)
              Text('علامة مميزة: ${order.deliveryLandmark}'),
            if (hasCoordinates) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => MapsLauncher.open(
                    latitude: order.deliveryLatitude,
                    longitude: order.deliveryLongitude,
                  ),
                  style: FilledButton.styleFrom(
                    foregroundColor: AppColors.info,
                    backgroundColor: AppColors.info.withValues(alpha: 0.12),
                  ),
                  icon: const Icon(Iconsax.location_copy, size: 18),
                  label: const Text('افتح في الخرائط'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
