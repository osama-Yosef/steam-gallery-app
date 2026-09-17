import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../payments/presentation/providers/payment_providers.dart';
import '../../providers/wallet_providers.dart';

/// Shares the exact submission pattern as InstapayPaymentScreen (Phase 12) —
/// same manual-transfer-then-admin-review flow, just crediting the wallet
/// instead of an order (rpc_wallet_topup_via_instapay, 0040).
class WalletTopupScreen extends ConsumerStatefulWidget {
  const WalletTopupScreen({super.key});

  @override
  ConsumerState<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends ConsumerState<WalletTopupScreen> {
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
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final walletRepo = ref.read(walletRepositoryProvider);
      final path = await paymentRepo.uploadProof(_proofBytes!, _proofExt!);
      await walletRepo.topupViaInstapay(
        amount: amount,
        reference: reference,
        proofPath: path,
        clientRequestId: _clientRequestId,
      );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) setState(() => _error = AppException.from(e).messageAr);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(instapayDetailsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('شحن الرصيد')),
      body: _submitted
          ? Center(
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
                      'تم استلام طلب الشحن',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'هنراجع التحويل ونضيف الرصيد بمجرد التأكيد.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('تمام'),
                    ),
                  ],
                ),
              ),
            )
          : detailsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: 'تعذَّر تحميل بيانات InstaPay',
                onRetry: () => ref.invalidate(instapayDetailsProvider),
              ),
              data: (details) {
                if (!details.configured) {
                  return const EmptyView(
                    message: 'الشحن عبر InstaPay مش متاح دلوقتي.',
                    icon: Icons.info_outline,
                  );
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
                      key: const Key('submit-topup'),
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
