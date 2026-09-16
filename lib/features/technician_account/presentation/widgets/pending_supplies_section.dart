import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../data/models/technician_supply.dart';
import '../providers/technician_account_providers.dart';

/// Supplies still waiting for an admin to confirm the cash arrived. The
/// technician sees them read-only (they don't reduce the amount due yet);
/// an admin ([canReview]) confirms or rejects each one.
class PendingSuppliesSection extends ConsumerWidget {
  final String technicianId;
  final bool canReview;

  const PendingSuppliesSection({
    super.key,
    required this.technicianId,
    required this.canReview,
  });

  void _refresh(WidgetRef ref) {
    ref.invalidate(pendingTechnicianSuppliesProvider(technicianId));
    ref.invalidate(technicianAccountSummaryProvider(technicianId));
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    TechnicianSupply supply,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: 'تأكيد استلام التوريد',
      message:
          'تأكيد استلام ${Formatters.currency(supply.amount)} نقدًا؟ سيُضاف المبلغ للخزنة ويُخصم من المطلوب توريده.',
    );
    if (!ok || !context.mounted) return;
    await _review(context, ref, supply, approve: true);
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    TechnicianSupply supply,
  ) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رفض التوريد'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'سبب الرفض'),
          autofocus: true,
          maxLength: 500,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(reasonCtrl.text.trim()),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
    if (reason == null || reason.isEmpty || !context.mounted) return;
    await _review(context, ref, supply, approve: false, reason: reason);
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    TechnicianSupply supply, {
    required bool approve,
    String? reason,
  }) async {
    try {
      await ref
          .read(technicianAccountRepositoryProvider)
          .reviewSupply(supplyId: supply.id, approve: approve, reason: reason);
      _refresh(ref);
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
    final suppliesAsync = ref.watch(
      pendingTechnicianSuppliesProvider(technicianId),
    );

    return suppliesAsync.when(
      // The account card above is the primary content; a failed or empty
      // pending list just stays out of the way.
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (supplies) {
        if (supplies.isEmpty) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'توريدات بانتظار التأكيد',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final supply in supplies)
                  ListTile(
                    leading: const Icon(Icons.hourglass_top),
                    title: Text(Formatters.currency(supply.amount)),
                    subtitle: Text(
                      [
                        Formatters.dateTime(supply.createdAt),
                        if (supply.notes != null) supply.notes!,
                      ].join(' — '),
                    ),
                    trailing: canReview
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'رفض',
                                icon: Icon(
                                  Icons.close,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                onPressed: () => _reject(context, ref, supply),
                              ),
                              IconButton(
                                tooltip: 'تأكيد الاستلام',
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                onPressed: () => _approve(context, ref, supply),
                              ),
                            ],
                          )
                        : Text(supplyStatusLabelAr(supply.status)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
