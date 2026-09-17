import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../orders/presentation/providers/order_providers.dart';
import '../../../presentation/providers/payment_providers.dart';

/// Customer submits a manual InstaPay transfer for one order: shows the
/// business's own handle, collects the transfer reference and a screenshot,
/// then waits for admin verification. No callback from the customer is ever
/// treated as proof of payment — this only ever creates a
/// `pending_verification` payment (0039); an admin confirms it separately.
class InstapayPaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  const InstapayPaymentScreen({super.key, required this.orderId});

  @override
  ConsumerState<InstapayPaymentScreen> createState() =>
      _InstapayPaymentScreenState();
}

class _InstapayPaymentScreenState extends ConsumerState<InstapayPaymentScreen> {
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final String _clientRequestId = const Uuid().v4();
  Uint8List? _proofBytes;
  String? _proofExt;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    if (mounted) {
      setState(() {
        _proofBytes = bytes;
        _proofExt = ext;
      });
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    final reference = _referenceCtrl.text.trim();
    if (amount == null || amount <= 0) {
      setState(() => _error = 'اكتب المبلغ اللي حوّلته');
      return;
    }
    if (reference.isEmpty) {
      setState(() => _error = 'اكتب رقم أو مرجع العملية من تطبيق InstaPay');
      return;
    }
    if (_proofBytes == null) {
      setState(() => _error = 'أرفق صورة إثبات التحويل');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final path = await repo.uploadProof(_proofBytes!, _proofExt!);
      await repo.submitInstapayPayment(
        orderId: widget.orderId,
        amount: amount,
        reference: reference,
        proofPath: path,
        clientRequestId: _clientRequestId,
      );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = AppException.from(e).messageAr);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(instapayDetailsProvider);
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('الدفع عبر InstaPay')),
      body: _submitted
          ? _SubmittedView(onDone: () => Navigator.of(context).maybePop())
          : detailsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل بيانات InstaPay',
                onRetry: () => ref.invalidate(instapayDetailsProvider),
              ),
              data: (details) {
                if (!details.configured) {
                  return const EmptyView(
                    message:
                        'الدفع عبر InstaPay مش متاح دلوقتي.\nاختر طريقة دفع تانية.',
                    icon: Icons.info_outline,
                  );
                }
                final remaining = orderAsync.value?.remaining;
                if (_amountCtrl.text.isEmpty && remaining != null) {
                  _amountCtrl.text = remaining
                      .toStringAsFixed(2)
                      .replaceFirst(RegExp(r'\.?0+$'), '');
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'حوّل المبلغ على',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              details.ipaAddress!,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (details.beneficiaryName != null) ...[
                              const SizedBox(height: 4),
                              Text('باسم: ${details.beneficiaryName}'),
                            ],
                            if (remaining != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'المطلوب: ${Formatters.currency(remaining)}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'المبلغ اللي حوّلته',
                        suffixText: 'ج.م',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _referenceCtrl,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'رقم/مرجع عملية InstaPay',
                        hintText: 'انسخه من تطبيق البنك بعد التحويل',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _pickProof,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        _proofBytes == null
                            ? 'أرفق صورة إثبات التحويل'
                            : 'تم إرفاق الصورة — تغيير',
                      ),
                    ),
                    if (_proofBytes != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _proofBytes!,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('submit-instapay'),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('إرسال للمراجعة'),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _SubmittedView extends StatelessWidget {
  final VoidCallback onDone;
  const _SubmittedView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'تم استلام طلبك',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'هنراجع التحويل ونأكد الدفع في أقرب وقت. هتوصلك إشعار بمجرد ما نخلص.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onDone, child: const Text('تمام')),
          ],
        ),
      ),
    );
  }
}
