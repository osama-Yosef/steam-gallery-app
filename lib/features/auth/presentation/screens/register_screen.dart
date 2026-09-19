import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/brand.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';

/// Customer self sign-up only. Technician/admin accounts are created
/// exclusively by an existing admin (see docs/04-security-architecture.md §1)
/// — there is intentionally no role picker on this screen.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Uint8List? _avatarBytes;
  String? _avatarExt;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _avatarBytes = bytes;
      _avatarExt = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final localPhone = _phoneCtrl.text.trim();
      final needsVerification = await ref
          .read(authRepositoryProvider)
          .signUpCustomer(
            localPhone: localPhone,
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
            avatarBytes: _avatarBytes,
            avatarExt: _avatarExt,
          );
      if (needsVerification) {
        // Auth has texted a code; the account only becomes usable once it's
        // entered. The photo waits for that session too.
        ref
            .read(pendingOtpProvider.notifier)
            .start(
              OtpRequest(
                phoneE164: Validators.toE164Egypt(localPhone),
                purpose: OtpPurpose.signup,
                avatarBytes: _avatarBytes,
                avatarExt: _avatarExt,
              ),
            );
        if (mounted) context.push(Routes.verifyOtp);
      } else {
        ref.invalidate(currentUserProfileProvider);
      }
    } catch (e) {
      if (!mounted) return;
      final message = AppException.from(e).messageAr;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حساب جديد في ${Brand.name}')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: _avatarBytes != null
                                  ? MemoryImage(_avatarBytes!)
                                  : null,
                              child: _avatarBytes == null
                                  ? const Icon(Iconsax.user_copy, size: 36)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: CircleAvatar(
                                radius: 14,
                                child: Icon(
                                  Iconsax.camera_copy,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: _pickAvatar,
                        child: Text(
                          _avatarBytes == null
                              ? 'إضافة صورة (اختياري)'
                              : 'تغيير الصورة',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        prefixIcon: Icon(Iconsax.user_copy),
                      ),
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
                        prefixIcon: Icon(Iconsax.call_copy),
                      ),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Iconsax.lock_copy),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Iconsax.eye_slash_copy
                                : Iconsax.eye_copy,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        prefixIcon: const Icon(Iconsax.lock_copy),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Iconsax.eye_slash_copy
                                : Iconsax.eye_copy,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                      ),
                      validator: (v) => v != _passwordCtrl.text
                          ? 'كلمة المرور غير متطابقة'
                          : null,
                    ),
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
          ),
        ),
      ),
    );
  }
}
