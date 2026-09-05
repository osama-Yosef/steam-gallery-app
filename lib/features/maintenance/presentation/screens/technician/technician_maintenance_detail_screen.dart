import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/maps_launcher.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/maintenance_request.dart';
import '../../providers/maintenance_providers.dart';
import '../../widgets/maintenance_image_thumb.dart';

class TechnicianMaintenanceDetailScreen extends ConsumerWidget {
  final String requestId;
  const TechnicianMaintenanceDetailScreen({super.key, required this.requestId});

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'استلام الطلب',
      message: 'هل تريد استلام طلب الصيانة ده؟',
    );
    if (!confirmed) return;
    try {
      await ref.read(maintenanceRepositoryProvider).claim(requestId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'بدء التنفيذ',
      message: 'هل تريد بدء تنفيذ الصيانة؟',
    );
    if (!confirmed) return;
    try {
      await ref.read(maintenanceRepositoryProvider).start(requestId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final notesCtrl = TextEditingController();
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تم التنفيذ'),
        content: TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (proceed != true) return;
    try {
      await ref
          .read(maintenanceRepositoryProvider)
          .complete(
            requestId,
            notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          );
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
    final requestAsync = ref.watch(maintenanceRequestDetailProvider(requestId));
    final imagesAsync = ref.watch(maintenanceImagesProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الصيانة')),
      body: requestAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الطلب'),
        data: (req) {
          if (req == null) return const EmptyView(message: 'الطلب غير موجود');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'طلب #${req.ticketNumber}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
              Text(
                'وصف المشكلة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(req.problemDescription),
              if (req.notes != null) ...[
                const SizedBox(height: 8),
                Text('ملاحظات: ${req.notes}'),
              ],
              const SizedBox(height: 16),
              Text('الصور', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: imagesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (images) {
                    if (images.isEmpty) return const Text('لا توجد صور');
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final img in images)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: MaintenanceImageThumb(
                              storedPathOrUrl: img.imageUrl,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // A waiting job can be taken by the technician directly — no
              // admin assignment step in between.
              if (req.status == MaintenanceStatus.waiting)
                FilledButton.icon(
                  onPressed: () => _claim(context, ref),
                  icon: const Icon(Icons.pan_tool_alt_outlined),
                  label: const Text('استلام الطلب'),
                ),
              if (req.status == MaintenanceStatus.assigned)
                FilledButton.icon(
                  onPressed: () => _start(context, ref),
                  icon: const Icon(Icons.play_arrow_outlined),
                  label: const Text('بدء التنفيذ'),
                ),
              if (req.status == MaintenanceStatus.inProgress)
                FilledButton.icon(
                  onPressed: () => _complete(context, ref),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('تم التنفيذ'),
                ),
            ],
          );
        },
      ),
    );
  }
}
