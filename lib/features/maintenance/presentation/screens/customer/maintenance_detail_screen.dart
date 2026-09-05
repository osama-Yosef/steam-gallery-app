import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/confirm_dialog.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../data/models/maintenance_request.dart';
import '../../providers/maintenance_providers.dart';
import '../../widgets/maintenance_image_thumb.dart';

class MaintenanceDetailScreen extends ConsumerWidget {
  final String requestId;
  const MaintenanceDetailScreen({super.key, required this.requestId});

  Future<void> _addImage(
    BuildContext context,
    WidgetRef ref,
    String customerId,
  ) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    try {
      await ref
          .read(maintenanceRepositoryProvider)
          .uploadImage(requestId, customerId, bytes, ext);
      ref.invalidate(maintenanceImagesProvider(requestId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'إلغاء الطلب',
      message: 'هل تريد إلغاء طلب الصيانة؟',
      isDangerous: true,
    );
    if (!confirmed) return;
    try {
      await ref
          .read(maintenanceRepositoryProvider)
          .cancel(requestId, 'ألغاه العميل');
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

    return Scaffold(
      appBar: AppBar(title: const Text('طلب الصيانة')),
      body: requestAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => const ErrorView(message: 'تعذَّر تحميل الطلب'),
        data: (req) {
          if (req == null) return const EmptyView(message: 'الطلب غير موجود');
          final isActive = kActiveMaintenanceStatuses.contains(req.status);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'رقم الدور #${req.ticketNumber}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          _StatusChip(status: req.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.dateTime(req.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final posAsync = ref.watch(
                      myQueuePositionProvider(requestId),
                    );
                    return posAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (pos) => Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'يوجد قبلك',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '${pos.peopleAhead} عملاء',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'وصف المشكلة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(req.problemDescription),
              if (req.deviceType != null) ...[
                const SizedBox(height: 8),
                Text('نوع الجهاز: ${req.deviceType}'),
              ],
              if (req.address != null) ...[
                const SizedBox(height: 8),
                Text('العنوان: ${req.address}'),
              ],
              if (req.cancelledReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  'سبب الإلغاء: ${req.cancelledReason}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Text('الصور', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final imagesAsync = ref.watch(
                    maintenanceImagesProvider(requestId),
                  );
                  return SizedBox(
                    height: 100,
                    child: imagesAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (images) => ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final img in images)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: MaintenanceImageThumb(
                                storedPathOrUrl: img.imageUrl,
                              ),
                            ),
                          if (isActive)
                            InkWell(
                              onTap: () =>
                                  _addImage(context, ref, req.customerId),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (isActive) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _cancel(context, ref),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('إلغاء الطلب'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final MaintenanceStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MaintenanceStatus.waiting => Colors.orange,
      MaintenanceStatus.assigned || MaintenanceStatus.inProgress => Colors.blue,
      MaintenanceStatus.completed => Colors.green,
      MaintenanceStatus.cancelled => Theme.of(context).colorScheme.error,
    };
    return Chip(
      label: Text(maintenanceStatusLabelAr(status)),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color),
      side: BorderSide.none,
    );
  }
}
