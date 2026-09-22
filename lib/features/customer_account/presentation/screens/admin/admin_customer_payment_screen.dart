import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../technician_account/data/models/sale.dart';
import '../../providers/customer_account_providers.dart';

class AdminCustomerPaymentScreen extends ConsumerStatefulWidget {
  final String customerId;
  const AdminCustomerPaymentScreen({super.key, required this.customerId});

  @override
  ConsumerState<AdminCustomerPaymentScreen> createState() =>
      _AdminCustomerPaymentScreenState();
}

class _AdminCustomerPaymentScreenState
    extends ConsumerState<AdminCustomerPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  // One key per payment entry, reused on retry, so a lost response followed
  // by a second tap can't record the same payment twice.
  final String _clientRequestId = const Uuid().v4();
  // Which till this payment lands in — used to silently default to cash
  // server-side with no way to say otherwise, so a transfer payment never
  // showed up in خزنة التحويلات. See rpc_record_customer_payment (0059).
  var _paymentMethod = PaymentMethod.cash;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(customerAccountRepositoryProvider)
          .recordPayment(
            customerId: widget.customerId,
            amount: double.parse(_amountCtrl.text),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            clientRequestId: _clientRequestId,
            paymentMethod: _paymentMethod,
          );
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
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دفعة')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'المبلغ'),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'أدخل مبلغًا صحيحًا';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('استُلم الفلوس إزاي؟'),
            const SizedBox(height: 8),
            SegmentedButton<PaymentMethod>(
              segments: const [
                ButtonSegment(value: PaymentMethod.cash, label: Text('نقدًا')),
                ButtonSegment(
                  value: PaymentMethod.transfer,
                  label: Text('تحويل'),
                ),
              ],
              selected: {_paymentMethod},
              onSelectionChanged: (s) =>
                  setState(() => _paymentMethod = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              maxLines: 2,
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
                  : const Icon(Iconsax.tick_circle_copy),
              label: const Text('تسجيل الدفعة'),
            ),
          ],
        ),
      ),
    );
  }
}
