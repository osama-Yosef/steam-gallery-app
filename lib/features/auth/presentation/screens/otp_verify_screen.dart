import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_page.dart';
import '../widgets/otp_code_form.dart';

/// Code entry for a user who is NOT signed in yet: confirming a new account,
/// or proving the number to reset a password. What's being verified comes from
/// [pendingOtpProvider], not the URL.
///
/// Success needs no navigation here: verifying signs the user in, and the
/// router takes it from there (home, or the new-password screen during
/// recovery).
class OtpVerifyScreen extends ConsumerWidget {
  const OtpVerifyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = ref.watch(pendingOtpProvider);

    if (request == null) {
      // Reached without starting a flow (e.g. a web page refresh drops the
      // in-memory request): nothing to verify, start over.
      return AuthPage(
        title: 'تأكيد رقم الهاتف',
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
    final isRecovery = request.purpose == OtpPurpose.passwordRecovery;

    Future<void> verify(String code) async {
      if (isRecovery) {
        // Must be set before the session appears, or the router would route
        // the freshly signed-in user home instead of to the new password.
        ref.read(passwordRecoveryProvider.notifier).begin();
        try {
          await repo.verifySignInOtp(phoneE164: request.phoneE164, code: code);
        } catch (_) {
          ref.read(passwordRecoveryProvider.notifier).end();
          rethrow;
        }
      } else {
        await repo.verifySignupOtp(
          phoneE164: request.phoneE164,
          code: code,
          avatarBytes: request.avatarBytes,
          avatarExt: request.avatarExt,
        );
      }
      ref.read(pendingOtpProvider.notifier).clear();
      ref.invalidate(currentUserProfileProvider);
    }

    Future<void> resend() => isRecovery
        ? repo.sendSignInOtp(request.phoneE164)
        : repo.resendSignupOtp(request.phoneE164);

    return AuthPage(
      title: isRecovery ? 'استعادة الحساب' : 'تأكيد رقم الهاتف',
      child: OtpCodeForm(
        phoneE164: request.phoneE164,
        onVerify: verify,
        onResend: resend,
      ),
    );
  }
}
