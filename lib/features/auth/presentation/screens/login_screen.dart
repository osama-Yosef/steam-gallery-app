import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../../../core/constants/brand.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Guards against a double sign-in request from an impatient double-tap:
    // the button's onPressed already checks _loading, but that only takes
    // effect after this function's first `setState` call actually runs —
    // a second tap landing before then would otherwise slip through.
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final localPhone = _phoneCtrl.text.trim();
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithPhone(
            localPhone: localPhone,
            password: _passwordCtrl.text,
          );
      ref.invalidate(currentUserProfileProvider);
      // GoRouterRefreshStream reacts to the auth event and redirects
      // automatically once the profile loads.
    } catch (e) {
      if (!mounted) return;
      // The password was right but the sign-up code was never entered:
      // offer a fresh code instead of a dead end. (Auth only reports this
      // after checking the password, so it reveals nothing to a guesser.)
      if (AppException.from(e).cause case AuthException(
        code: 'phone_not_confirmed',
      )) {
        await _continueSignupVerification(localPhone);
        return;
      }
      final message = AppException.from(e).messageAr;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueSignupVerification(String localPhone) async {
    final phone = Validators.toE164Egypt(localPhone);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).resendSignupOtp(phone);
    } catch (e) {
      // e.g. a code was sent moments ago (cooldown) — the screen still lets
      // them type that one or resend later.
      messenger.showSnackBar(
        SnackBar(content: Text(AppException.from(e).messageAr)),
      );
    }
    ref
        .read(pendingOtpProvider.notifier)
        .start(OtpRequest(phoneE164: phone, purpose: OtpPurpose.signup));
    if (mounted) context.push(Routes.verifyOtp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    const Center(child: BrandLogo(width: 120)),
                    const SizedBox(height: 16),
                    Text(
                      'تسجيل الدخول',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Brand.tagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
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
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Iconsax.lock_copy),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Iconsax.eye_slash_copy : Iconsax.eye_copy,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
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
                          : const Text('دخول'),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () => context.push(Routes.forgotPassword),
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(Routes.register),
                      child: const Text('عميل جديد؟ إنشاء حساب'),
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
