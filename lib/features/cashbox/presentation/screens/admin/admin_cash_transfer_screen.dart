import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/offline/offline_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/input_formatters.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../../data/models/cashbox_balance.dart';
import '../../providers/cashbox_providers.dart';
import '../../widgets/cashbox_kind_selector.dart';

/// Moves money from one till to another (0080) — e.g. the drawer into the
/// safe at closing, or the safe into the CIB account. Balance only: nothing
/// here is a sale or an expense.
class AdminCashTransferScreen extends ConsumerStatefulWidget {
  const AdminCashTransferScreen({super.key});

  @override
  ConsumerState<AdminCashTransferScreen> createState() =>
      _AdminCashTransferScreenState();
}

class _AdminCashTransferScreenState
    extends ConsumerState<AdminCashTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  CashboxKind _from = CashboxKind.cash;
  CashboxKind _to = CashboxKind.main;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setFrom(CashboxKind k) => setState(() {
    if (k == _to) _to = _from;
    _from = k;
  });

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final notes = _notesCtrl.text.trim();
      final result = await ref
          .read(cashboxRepositoryProvider)
          .transferBetweenTills(
            from: _from,
            to: _to,
            amount: double.parse(_amountCtrl.text),
            notes: notes.isEmpty ? null : notes,
          );
      if (mounted) {
        if (result.queued) showSavedOfflineSnack(context, 'التحويل اتسجل');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balances = ref.watch(cashboxBalancesProvider).value;
    double? balanceOf(CashboxKind k) =>
        balances?.where((b) => b.kind == k).firstOrNull?.balance;
    final fromBalance = balanceOf(_from);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تحويل بين الخزن')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('من', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            CashboxKindSelector(value: _from, onChanged: _setFrom),
            if (fromBalance != null) ...[
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('رصيد ${cashboxKindLabelAr(_from)}: '),
                  MoneyText(fromBalance),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Center(child: Icon(Iconsax.arrow_down_copy)),
            const SizedBox(height: 8),
            Text('إلى', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            CashboxKindSelector(
              value: _to,
              exclude: {_from},
              onChanged: (k) => setState(() => _to = k),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [moneyInputFormatter],
              decoration: const InputDecoration(labelText: 'المبلغ'),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'أدخل مبلغًا صحيحًا';
                // Re-checked server-side under a lock; this only saves a
                // round trip for the common mistake.
                if (fromBalance != null && n > fromBalance) {
                  return 'المبلغ أكبر من رصيد الخزنة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                hintText: 'مثال: تقفيل اليوم',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Iconsax.info_circle_copy, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'التحويل بيغيّر رصيد الخزنتين بس، ومش بيتحسب مبيعات '
                    'ولا مصروفات.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.arrow_swap_horizontal_copy),
              label: const Text('تأكيد التحويل'),
            ),
          ],
        ),
      ),
    );
  }
}
