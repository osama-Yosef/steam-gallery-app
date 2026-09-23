import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_page.dart';
import '../widgets/otp_code_form.dart';

/// For a SIGNED-IN customer created before 0070 (phone-only, no email). The
/// router sends every such customer here until they add one — email is now
/// how sign-in, confirmation and password recovery all work, so an account
/// without one is stuck outside those otherwise.
class AddEmailScreen extends ConsumerStatefulWidget {
  const AddEmailScreen({super.key});

  @override
  ConsumerState<AddEmailScreen> createState() => _AddEmailScreenState();
}

class _AddEmailScreenState extends ConsumerState<AddEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _submitting = false;
  String? _sentTo;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final email = _emailCtrl.text.trim();
    try {
      await ref.read(authRepositoryProvider).addEmailToAccount(email);
      if (mounted) setState(() => _sentTo = email);
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
    final profileAsync = ref.watch(currentUserProfileProvider);
    final repo = ref.read(authRepositoryProvider);

    final signOut = TextButton(
      onPressed: () => repo.signOut(),
      child: const Text('تسجيل الخروج'),
    );

    if (profileAsync.isLoading && profileAsync.value == null) {
      return const Scaffold(body: LoadingView());
    }

    final sentTo = _sentTo;
    if (sentTo != null) {
      return AuthPage(
        title: 'تأكيد البريد الإلكتروني',
        actions: [signOut],
        child: OtpCodeForm(
          destination: sentTo,
          codeLength: Validators.emailOtpLength,
          validator: Validators.emailOtpCode,
          onVerify: (code) async {
            await repo.verifyEmailChangeOtp(email: sentTo, code: code);
            ref.invalidate(currentUserProfileProvider);
          },
          onResend: () => repo.addEmailToAccount(sentTo),
        ),
      );
    }

    return AuthPage(
      title: 'أضف بريدك الإلكتروني',
      actions: [signOut],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Iconsax.sms_copy, size: 56),
            const SizedBox(height: 16),
            const Text(
              'بريدك الإلكتروني بقى مطلوب لتسجيل الدخول واستعادة كلمة '
              'المرور. اكتبه وهنبعتلك كود تأكيد.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Iconsax.sms_copy),
              ),
              validator: Validators.email,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('إرسال كود التأكيد'),
            ),
          ],
        ),
      ),
    );
  }
}
