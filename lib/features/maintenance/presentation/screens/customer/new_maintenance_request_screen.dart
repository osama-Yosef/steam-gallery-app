import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../providers/maintenance_providers.dart';

/// Assumption (see docs/01-system-analysis.md §9): no GPS picker in v1 —
/// the address is free text. The technician's "فتح الموقع" button falls
/// back to a Google Maps text search on that address when no coordinates
/// are on file, so the feature still works end-to-end without adding the
/// geolocator package / platform permissions this session.
class NewMaintenanceRequestScreen extends ConsumerStatefulWidget {
  const NewMaintenanceRequestScreen({super.key});

  @override
  ConsumerState<NewMaintenanceRequestScreen> createState() => _NewMaintenanceRequestScreenState();
}

class _NewMaintenanceRequestScreenState extends ConsumerState<NewMaintenanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _deviceCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _prefilled = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _deviceCtrl.dispose();
    _problemCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(String customerId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final id = await ref.read(maintenanceRepositoryProvider).createRequest(
            customerId: customerId,
            customerName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
            deviceType: _deviceCtrl.text.trim().isEmpty ? null : _deviceCtrl.text.trim(),
            problemDescription: _problemCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      if (mounted) context.pushReplacement(Routes.customerMaintenanceDetail(id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).value;
    if (profile != null && !_prefilled) {
      _prefilled = true;
      _nameCtrl.text = profile.fullName;
      _phoneCtrl.text = profile.phone ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('طلب صيانة جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'الاسم'),
              validator: (v) => Validators.required(v, 'الاسم'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              validator: (v) => Validators.required(v, 'رقم الهاتف'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'العنوان'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deviceCtrl,
              decoration: const InputDecoration(labelText: 'نوع الجهاز'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _problemCtrl,
              decoration: const InputDecoration(labelText: 'وصف المشكلة'),
              maxLines: 3,
              validator: (v) => Validators.required(v, 'وصف المشكلة'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظات إضافية (اختياري)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting || profile == null ? null : () => _submit(profile.id),
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('إرسال الطلب'),
            ),
          ],
        ),
      ),
    );
  }
}
