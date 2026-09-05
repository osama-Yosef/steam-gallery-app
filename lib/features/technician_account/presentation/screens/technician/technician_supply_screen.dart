import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../providers/technician_account_providers.dart';

/// Records a توريد (remittance of cash held by the technician to the
/// gallery's cashbox). [technicianId] null means the signed-in technician is
/// remitting for themself; an admin passes a specific technician's id.
class TechnicianSupplyScreen extends ConsumerStatefulWidget {
  final String? technicianId;
  const TechnicianSupplyScreen({super.key, this.technicianId});

  @override
  ConsumerState<TechnicianSupplyScreen> createState() =>
      _TechnicianSupplyScreenState();
}

class _TechnicianSupplyScreenState
    extends ConsumerState<TechnicianSupplyScreen> {
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

  Future<void> _submit(String technicianId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(technicianAccountRepositoryProvider)
          .recordSupply(
            technicianId: technicianId,
            amount: double.parse(_amountCtrl.text),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
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
    final technicianId =
        widget.technicianId ?? ref.watch(currentUserProfileProvider).value?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل توريد')),
      body: technicianId == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
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
                  TextFormField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _submitting ? null : () => _submit(technicianId),
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('تأكيد التوريد'),
                  ),
                ],
              ),
            ),
    );
  }
}
