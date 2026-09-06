import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/money_text.dart';
import '../../providers/cashbox_providers.dart';

/// Manual cash in / cash out on the till.
///
/// One screen for both directions — the two forms are identical apart from
/// their wording and which RPC they call, and keeping them together makes it
/// obvious they behave the same way.
enum CashMovementKind {
  deposit,
  withdrawal;

  bool get isDeposit => this == CashMovementKind.deposit;

  String get title => isDeposit ? 'إيداع في الخزنة' : 'سحب من الخزنة';

  String get action => isDeposit ? 'تأكيد الإيداع' : 'تأكيد السحب';

  IconData get icon =>
      isDeposit ? Icons.south_west_rounded : Icons.north_east_rounded;
}

class AdminCashMovementScreen extends ConsumerStatefulWidget {
  final CashMovementKind kind;
  const AdminCashMovementScreen({super.key, required this.kind});

  @override
  ConsumerState<AdminCashMovementScreen> createState() =>
      _AdminCashMovementScreenState();
}

class _AdminCashMovementScreenState
    extends ConsumerState<AdminCashMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(cashboxRepositoryProvider);
      final amount = double.parse(_amountCtrl.text);
      final notes = _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim();
      if (widget.kind.isDeposit) {
        await repo.depositCash(amount: amount, notes: notes);
      } else {
        await repo.withdrawCash(amount: amount, notes: notes);
      }
      if (mounted) Navigator.of(context).pop(true);
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
    final balanceAsync = ref.watch(cashboxBalanceProvider);
    final balance = balanceAsync.value?.balance;

    return Scaffold(
      appBar: AppBar(title: Text(widget.kind.title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (balance != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('رصيد الخزنة الحالي'),
                  trailing: MoneyText(balance),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'المبلغ'),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'أدخل مبلغًا صحيحًا';
                // The RPC re-checks this under a row lock; this is only here
                // so the common mistake is caught without a round trip.
                if (!widget.kind.isDeposit && balance != null && n > balance) {
                  return 'المبلغ أكبر من رصيد الخزنة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: 'السبب / ملاحظات (اختياري)',
                hintText: widget.kind.isDeposit
                    ? 'مثال: عهدة بداية اليوم'
                    : 'مثال: تحويل للبنك',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // The whole point of this screen is that it does NOT affect
            // profit; say so where the admin can see it, not just in the SQL.
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'هذه الحركة تغيّر رصيد الخزنة فقط، ولا تُحتسب ضمن '
                    'المبيعات أو المصروفات أو الأرباح.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  : Icon(widget.kind.icon),
              label: Text(widget.kind.action),
            ),
          ],
        ),
      ),
    );
  }
}
