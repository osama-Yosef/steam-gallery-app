import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../auth/data/models/app_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../data/models/payment_models.dart';
import '../../providers/payment_providers.dart';

/// Admin/sales queue of InstaPay submissions awaiting a human check against
/// the real bank statement (0039). Approving or rejecting is final — there
/// is no "undo", matching rpc_admin_verify_instapay's one-way transition out
/// of pending_verification.
///
/// Sales may approve/reject (migration 0044) but must never change where
/// customer transfers are expected to land — the settings gear below is
/// structurally absent for it rather than merely relying on the
/// admin-only rpc_admin_set_text_setting to reject the attempt.
class AdminInstapayReviewScreen extends ConsumerWidget {
  const AdminInstapayReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingInstapaySubmissionsProvider);
    final isSales =
        ref.watch(currentUserProfileProvider).value?.role == AppRole.sales;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مراجعة تحويلات InstaPay'),
        actions: [
          if (!isSales)
            IconButton(
              tooltip: 'إعدادات InstaPay',
              icon: const Icon(Iconsax.setting_2_copy),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const _InstapaySettingsSheet(),
              ),
            ),
        ],
      ),
      body: pendingAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'تعذَّر تحميل القائمة',
          onRetry: () => ref.invalidate(pendingInstapaySubmissionsProvider),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return const EmptyView(
              message: 'لا توجد تحويلات بانتظار المراجعة',
              icon: Iconsax.task_square_copy,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(pendingInstapaySubmissionsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _SubmissionCard(payment: payments[i]),
            ),
          );
        },
      ),
    );
  }
}

class _InstapaySettingsSheet extends ConsumerStatefulWidget {
  const _InstapaySettingsSheet();

  @override
  ConsumerState<_InstapaySettingsSheet> createState() =>
      _InstapaySettingsSheetState();
}

class _InstapaySettingsSheetState extends ConsumerState<_InstapaySettingsSheet> {
  final _ipaCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  void _prefill(InstapayDetails d) {
    if (_loaded) return;
    _loaded = true;
    _ipaCtrl.text = d.ipaAddress ?? '';
    _nameCtrl.text = d.beneficiaryName ?? '';
  }

  @override
  void dispose() {
    _ipaCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .setInstapaySettings(
            ipaAddress: _ipaCtrl.text.trim(),
            beneficiaryName: _nameCtrl.text.trim(),
          );
      ref.invalidate(instapayDetailsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(instapayDetailsProvider);
    detailsAsync.whenData(_prefill);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'إعدادات InstaPay',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text('العميل هيشوف الرقم ده لما يختار الدفع بـ InstaPay.'),
          const SizedBox(height: 16),
          TextField(
            controller: _ipaCtrl,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: 'رقم/عنوان InstaPay (IPA)',
              hintText: 'مثال: mokoji@instapay',
              suffixIcon: IconButton(
                tooltip: 'نسخ',
                icon: const Icon(Iconsax.copy_copy),
                onPressed: () {
                  if (_ipaCtrl.text.trim().isEmpty) return;
                  Clipboard.setData(ClipboardData(text: _ipaCtrl.text.trim()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم النسخ')),
                  );
                },
              ),
            ),
          ),
          TextField(
            controller: _nameCtrl,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'اسم المستفيد'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _SubmissionCard extends ConsumerStatefulWidget {
  final PaymentRecord payment;
  const _SubmissionCard({required this.payment});

  @override
  ConsumerState<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends ConsumerState<_SubmissionCard> {
  bool _busy = false;
  String? _proofUrl;

  Future<void> _loadProof() async {
    final path = widget.payment.proofPath;
    if (path == null) return;
    try {
      final url = await ref.read(paymentRepositoryProvider).signedProofUrl(path);
      if (mounted) setState(() => _proofUrl = url);
    } catch (_) {
      // Non-fatal: the review can proceed without the preview loading.
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProof();
  }

  Future<void> _decide(bool approve) async {
    String? reason;
    if (!approve) {
      reason = await _askReason(context);
      if (reason == null || reason.trim().isEmpty) return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .verifyInstapayPayment(
            paymentId: widget.payment.id,
            approve: approve,
            rejectionReason: reason,
          );
      ref.invalidate(pendingInstapaySubmissionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'مثلًا: المرجع مش موجود في كشف الحساب',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    Formatters.currency(p.amount),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Formatters.dateTime(p.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('المرجع: ${p.providerReference ?? '—'}'),
            if (p.orderId != null) Text('الطلب: ${p.orderId}'),
            const SizedBox(height: 8),
            if (_proofUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _proofUrl!,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Text('تعذَّر تحميل صورة الإثبات'),
                ),
              )
            else
              const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            const SizedBox(height: 12),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _decide(false),
                      child: const Text('رفض'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _decide(true),
                      child: const Text('تأكيد الدفع'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
