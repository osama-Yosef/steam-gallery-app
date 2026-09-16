import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/location_models.dart';
import '../../providers/locations_providers.dart';
import '../../widgets/availability_badge.dart';

/// Server-side cap (rpc_save_my_address); mirrored here only to disable the
/// add button with an explanation instead of failing after a full form.
const kMaxAddresses = 10;

class MyAddressesScreen extends ConsumerWidget {
  const MyAddressesScreen({super.key});

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      ref.invalidate(myAddressesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(myAddressesProvider);
    final repo = ref.read(locationsRepositoryProvider);
    final count = addressesAsync.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('عناويني')),
      floatingActionButton: addressesAsync.hasValue
          ? FloatingActionButton.extended(
              onPressed: count >= kMaxAddresses
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'وصلت للحد الأقصى ($kMaxAddresses عناوين). احذف عنوانًا لإضافة جديد.',
                        ),
                      ),
                    )
                  : () => context.push(Routes.customerAddressNew),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('إضافة عنوان'),
            )
          : null,
      body: addressesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل العناوين',
          onRetry: () => ref.invalidate(myAddressesProvider),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return EmptyView(
              message:
                  'لسه مفيش عناوين محفوظة.\nأضف عنوانك لنعرف لو الخدمة متاحة عندك.',
              icon: Icons.location_off_outlined,
              action: FilledButton.icon(
                onPressed: () => context.push(Routes.customerAddressNew),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('إضافة عنوان'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myAddressesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _AddressCard(
                address: addresses[i],
                onEdit: () =>
                    context.push(Routes.customerAddressEdit(addresses[i].id)),
                onMakeDefault: () => _run(
                  context,
                  ref,
                  () => repo.setDefaultAddress(addresses[i].id),
                ),
                onDelete: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'حذف العنوان',
                    message: 'حذف "${addresses[i].label}"؟',
                    confirmLabel: 'حذف',
                    isDangerous: true,
                  );
                  if (!ok || !context.mounted) return;
                  await _run(
                    context,
                    ref,
                    () => repo.deleteMyAddress(addresses[i].id),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final CustomerAddress address;
  final VoidCallback onEdit;
  final VoidCallback onMakeDefault;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onMakeDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = address.detailsLine;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 4, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    address.isDefault
                        ? Icons.star_rounded
                        : Icons.place_outlined,
                    color: address.isDefault
                        ? AppColors.brandGold
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address.label,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (address.isDefault)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: Text(
                        'الافتراضي',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.brandGold,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    tooltip: 'خيارات',
                    onSelected: (v) => switch (v) {
                      'default' => onMakeDefault(),
                      'edit' => onEdit(),
                      'delete' => onDelete(),
                      _ => null,
                    },
                    itemBuilder: (_) => [
                      if (!address.isDefault)
                        const PopupMenuItem(
                          value: 'default',
                          child: Text('تعيين كعنوان افتراضي'),
                        ),
                      const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(address.addressLine),
                    if (details.isNotEmpty)
                      Text(details, style: theme.textTheme.bodySmall),
                    if (address.cityName != null)
                      Text(address.cityName!, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    AvailabilityBadge(
                      available: address.isServiceable,
                      areaName: address.serviceAreaName,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
