import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../locations/data/models/location_models.dart';
import '../../../locations/presentation/widgets/availability_badge.dart';

/// The chosen address (or the empty-state prompt) on the checkout screen.
/// Tapping it opens [showAddressPickerSheet].
class CheckoutAddressCard extends StatelessWidget {
  final CustomerAddress? selected;
  final VoidCallback onTap;
  const CheckoutAddressCard({super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = selected;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: a == null ? AppColors.textSecondary : AppColors.primaryDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: a == null
                    ? const Text('اختر عنوان التوصيل')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  a.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // A long area name ('الخدمة متاحة — مدينة نصر')
                              // plus the label can outgrow narrow screens.
                              Flexible(
                                child: AvailabilityBadge(
                                  available: a.isServiceable,
                                  areaName: a.serviceAreaName,
                                  compact: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.addressLine,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (a.detailsLine.isNotEmpty)
                            Text(
                              a.detailsLine,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sentinel returned by [showAddressPickerSheet] for «إضافة عنوان جديد» —
/// the caller navigates with its own (still-mounted) context rather than the
/// sheet's, which is being torn down at the same moment it pops.
const addAddressSentinel = '__add_new_address__';

/// Bottom sheet listing every saved address (with its coverage badge) plus
/// «إضافة عنوان جديد». Returns the chosen address id, [addAddressSentinel],
/// or null if dismissed.
Future<String?> showAddressPickerSheet(
  BuildContext context, {
  required List<CustomerAddress> addresses,
  required String? selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'عنوان التوصيل',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
            ),
            Flexible(
              child: RadioGroup<String>(
                groupValue: selectedId,
                onChanged: (v) => Navigator.of(ctx).pop(v),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final a in addresses)
                      RadioListTile<String>(
                        value: a.id,
                        title: Row(
                          children: [
                            Flexible(child: Text(a.label)),
                            const SizedBox(width: 8),
                            AvailabilityBadge(
                              available: a.isServiceable,
                              compact: true,
                            ),
                          ],
                        ),
                        subtitle: Text(
                          a.detailsLine.isEmpty
                              ? a.addressLine
                              : '${a.addressLine} — ${a.detailsLine}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined),
              title: const Text('إضافة عنوان جديد'),
              onTap: () => Navigator.of(ctx).pop(addAddressSentinel),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
