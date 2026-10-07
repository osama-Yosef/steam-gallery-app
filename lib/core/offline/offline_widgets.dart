import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../router/route_names.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/confirm_dialog.dart';
import 'network_status.dart';
import 'outbox.dart';

/// Shown after a write that was queued instead of sent.
void showSavedOfflineSnack(BuildContext context, [String? what]) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${what ?? 'تم الحفظ'} على الجهاز — هيتبعت تلقائيًا أول ما النت يرجع',
      ),
    ),
  );
}

/// A strip above the admin content: offline notice, and how many writes are
/// waiting to sync (tap for the list). Hidden when online with nothing
/// pending.
class OfflineStatusBar extends ConsumerWidget {
  /// Where the sync list lives for this shell (admin or sales).
  final String syncRoute;
  const OfflineStatusBar({super.key, this.syncRoute = Routes.adminSync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outbox = ref.watch(outboxProvider);
    return ListenableBuilder(
      listenable: Listenable.merge([NetworkStatus.instance, outbox]),
      builder: (context, _) {
        final online = NetworkStatus.instance.isOnline;
        final pending = outbox.pending.length;
        final failed = outbox.failed.length;
        if (online && pending == 0 && failed == 0) {
          return const SizedBox.shrink();
        }

        final parts = <String>[
          if (!online) 'أوفلاين — بتشوف آخر بيانات محفوظة',
          if (pending > 0) '$pending عملية مستنية المزامنة',
          if (failed > 0) '$failed عملية رفضها السيرفر',
        ];
        final color = failed > 0
            ? AppColors.danger
            : online
            ? AppColors.primary
            : AppColors.warning;

        return Material(
          color: color.withValues(alpha: 0.12),
          child: InkWell(
            onTap: () => context.push(syncRoute),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    online ? Iconsax.refresh_copy : Iconsax.wifi_square_copy,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      parts.join(' · '),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (outbox.isSyncing)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  else if (pending + failed > 0)
                    Icon(Icons.chevron_left_rounded, size: 18, color: color),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Everything waiting to be sent, plus anything the server rejected (with
/// its reason) to retry or discard.
class OfflineSyncScreen extends ConsumerWidget {
  const OfflineSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outbox = ref.watch(outboxProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('المزامنة')),
      body: ListenableBuilder(
        listenable: Listenable.merge([NetworkStatus.instance, outbox]),
        builder: (context, _) {
          final entries = outbox.entries;
          final online = NetworkStatus.instance.isOnline;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: Icon(
                    online ? Iconsax.wifi_copy : Iconsax.wifi_square_copy,
                    color: online ? AppColors.success : AppColors.danger,
                  ),
                  title: Text(online ? 'متصل بالسيرفر' : 'غير متصل'),
                  subtitle: Text(
                    entries.isEmpty
                        ? 'كل العمليات اتبعتت'
                        : '${outbox.pending.length} مستنية · ${outbox.failed.length} مرفوضة',
                  ),
                  trailing: outbox.isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FilledButton.tonal(
                          onPressed: outbox.pending.isEmpty
                              ? null
                              : () => outbox.sync(),
                          child: const Text('مزامنة الآن'),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text('لا توجد عمليات مستنية')),
                ),
              for (final e in entries)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              e.failed
                                  ? Iconsax.danger_copy
                                  : Iconsax.clock_copy,
                              size: 20,
                              color: e.failed
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.label,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.dateTime(e.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (e.failed) ...[
                          const SizedBox(height: 6),
                          Text(
                            e.error!,
                            style: const TextStyle(color: AppColors.danger),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final ok = await showConfirmDialog(
                                    context,
                                    title: 'تجاهل العملية',
                                    message:
                                        'العملية دي هتتشال ومش هتتبعت للسيرفر. متأكد؟',
                                  );
                                  if (ok) await outbox.discard(e);
                                },
                                child: const Text('تجاهل'),
                              ),
                              FilledButton.tonal(
                                onPressed: () => outbox.retry(e),
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
