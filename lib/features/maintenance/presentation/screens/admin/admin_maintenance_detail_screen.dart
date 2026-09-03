import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/maps_launcher.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/maintenance_request.dart';
import '../../providers/maintenance_providers.dart';

class AdminMaintenanceDetailScreen extends ConsumerWidget {
  final String requestId;
  const AdminMaintenanceDetailScreen({super.key, required this.requestId});

  Future<void> _assign(BuildContext context, WidgetRef ref) async {
    final technicians = await ref.read(assignableTechniciansProvider.future);
    if (!context.mounted) return;
    if (technicians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد صنايعية نشطون')));
      return;
    }
    String? selectedId = technicians.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('إسناد لصنايعي'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedId,
            isExpanded: true,
            items: technicians
                .map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text('${t.fullName} (${t.employeeCode})', overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => selectedId = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('إسناد')),
          ],
        ),
      ),
    );
    if (confirmed != true || selectedId == null) return;
    try {
      await ref.read(maintenanceRepositoryProvider).assign(requestId, selectedId!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الإسناد بنجاح')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء طلب الصيانة'),
        content: TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'السبب')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('تراجع')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(reasonCtrl.text.trim()),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await ref.read(maintenanceRepositoryProvider).cancel(requestId, reason);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(maintenanceRequestDetailProvider(requestId));
    final imagesAsync = ref.watch(maintenanceImagesProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الصيانة')),
      body: requestAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الطلب'),
        data: (req) {
          if (req == null) return const EmptyView(message: 'الطلب غير موجود');
          final canCancel = kActiveMaintenanceStatuses.contains(req.status);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('طلب #${req.ticketNumber}', style: Theme.of(context).textTheme.titleLarge),
                  Chip(label: Text(maintenanceStatusLabelAr(req.status))),
                ],
              ),
              const SizedBox(height: 4),
              Text(Formatters.dateTime(req.createdAt)),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(req.customerName),
                  subtitle: Text(req.phone),
                ),
              ),
              if (req.address != null) ...[
                const SizedBox(height: 8),
                Text('العنوان: ${req.address}'),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => MapsLauncher.open(
                  latitude: req.latitude,
                  longitude: req.longitude,
                  address: req.address,
                ),
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('فتح الموقع'),
              ),
              const SizedBox(height: 16),
              if (req.deviceType != null) ...[
                Text('نوع الجهاز: ${req.deviceType}'),
                const SizedBox(height: 8),
              ],
              Text('وصف المشكلة', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(req.problemDescription),
              if (req.notes != null) ...[
                const SizedBox(height: 8),
                Text('ملاحظات: ${req.notes}'),
              ],
              if (req.cancelledReason != null) ...[
                const SizedBox(height: 8),
                Text('سبب الإلغاء: ${req.cancelledReason}',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              Text('الصور', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: imagesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (images) {
                    if (images.isEmpty) return const Text('لا توجد صور');
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final img in images)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: img.imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (req.status == MaintenanceStatus.waiting)
                    FilledButton.icon(
                      onPressed: () => _assign(context, ref),
                      icon: const Icon(Icons.assignment_ind_outlined),
                      label: const Text('إسناد لصنايعي'),
                    ),
                  if (canCancel)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      onPressed: () => _cancel(context, ref),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('إلغاء الطلب'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
