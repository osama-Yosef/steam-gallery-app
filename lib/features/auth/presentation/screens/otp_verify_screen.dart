import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_page.dart';
import '../widgets/otp_code_form.dart';

/// Code entry for a user who is NOT signed in yet: confirming a new account
/// by email (0070), or an emailed recovery code. What's being verified comes
/// from [pendingOtpProvider], not the URL.
///
/// Signup verifies (and signs in) with Supabase directly, so the router
/// takes it from there. Recovery also creates a session (verifyOTP with
/// type: recovery) — [passwordRecoveryProvider] holds the router on the
/// new-password screen until it's set, same as the old phone-OTP design.
/// The legacy phone-signup purpose still works for any account created
/// before 0070 that's mid-flow on it.
class OtpVerifyScreen extends ConsumerWidget {
  const OtpVerifyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(pendingOtpProvider);

    if (request == null) {
      // Reached without starting a flow (e.g. a web page refresh drops the
      // in-memory request): nothing to verify, start over.
      return AuthPage(
        title: 'تأكيد الحساب',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'انتهت هذه الخطوة. ابدأ من جديد من شاشة الدخول.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(Routes.login),
              child: const Text('الرجوع لتسجيل الدخول'),
            ),
          ],
        ),
      );
    }

    final repo = ref.read(authRepositoryProvider);
    final purpose = request.purpose;

    Future<void> verify(String code) async {
      switch (purpose) {
        case OtpPurpose.passwordRecovery:
          // Must be set before the session appears, or the router would
          // route the freshly signed-in user home instead of to the new
          // password.
          ref.read(passwordRecoveryProvider.notifier).begin();
          try {
            await repo.verifyRecoveryEmailOtp(email: request.destination, code: code);
          } catch (_) {
            ref.read(passwordRecoveryProvider.notifier).end();
            rethrow;
          }
        case OtpPurpose.emailSignup:
          await repo.verifySignupEmailOtp(
            email: request.destination,
            code: code,
            avatarBytes: request.avatarBytes,
            avatarExt: request.avatarExt,
          );
        case OtpPurpose.signup:
          await repo.verifySignupOtp(
            phoneE164: request.destination,
            code: code,
            avatarBytes: request.avatarBytes,
            avatarExt: request.avatarExt,
          );
        case OtpPurpose.emailChange:
          await repo.verifyEmailChangeOtp(email: request.destination, code: code);
      }
      ref.read(pendingOtpProvider.notifier).clear();
      ref.invalidate(currentUserProfileProvider);
    }

    Future<void> resend() => switch (purpose) {
      OtpPurpose.passwordRecovery => repo.sendPasswordRecoveryEmail(request.destination),
      OtpPurpose.emailSignup => repo.resendSignupEmailOtp(request.destination),
      OtpPurpose.signup => repo.resendSignupOtp(request.destination),
      OtpPurpose.emailChange => repo.addEmailToAccount(request.destination),
    };

    final isEmail = purpose != OtpPurpose.signup;

    return AuthPage(
      title: purpose == OtpPurpose.passwordRecovery ? 'استعادة الحساب' : 'تأكيد الحساب',
      child: OtpCodeForm(
        destination: request.destination,
        codeLength: isEmail ? Validators.emailOtpLength : Validators.otpLength,
        validator: isEmail ? Validators.emailOtpCode : Validators.otpCode,
        onVerify: verify,
        onResend: resend,
      ),
    );
  }
}
