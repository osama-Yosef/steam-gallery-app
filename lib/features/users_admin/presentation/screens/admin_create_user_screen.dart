import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/data/models/app_user.dart';
import '../providers/users_admin_providers.dart';

/// Creates a technician or admin account via the create-user Edge Function.
/// No self sign-up for these roles — see docs/04-security-architecture.md §1.
class AdminCreateUserScreen extends ConsumerStatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  ConsumerState<AdminCreateUserScreen> createState() =>
      _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends ConsumerState<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _employeeCodeCtrl = TextEditingController();
  AppRole _role = AppRole.technician;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _employeeCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(usersAdminRepositoryProvider)
          .createTechnicianOrAdmin(
            localPhone: _phoneCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
            role: _role,
            employeeCode: _employeeCodeCtrl.text.trim().isEmpty
                ? null
                : _employeeCodeCtrl.text.trim(),
          );
      ref.invalidate(adminUsersListProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إنشاء الحساب بنجاح')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة صنايعي / أدمن')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<AppRole>(
                segments: const [
                  ButtonSegment(
                    value: AppRole.technician,
                    label: Text('صنايعي'),
                    icon: Icon(Icons.build_outlined),
                  ),
                  ButtonSegment(
                    value: AppRole.admin,
                    label: Text('أدمن'),
                    icon: Icon(Icons.admin_panel_settings_outlined),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                validator: (v) => Validators.required(v, 'الاسم'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  hintText: '01012345678',
                ),
                validator: Validators.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور المبدئية',
                ),
                validator: Validators.password,
              ),
              if (_role == AppRole.technician) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _employeeCodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'كود الموظف (اختياري)',
                    hintText: 'يُنشأ تلقائيًا إذا تُرك فارغًا',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('إنشاء الحساب'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
