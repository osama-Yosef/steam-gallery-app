import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_page.dart';
import '../widgets/otp_code_form.dart';

/// For a SIGNED-IN account whose phone was never verified (created before
/// verification existed). The router sends customers here while the server
/// requires verification; anyone can also open it from their account screen.
///
/// Verifying signs the same account in again by code, which is the evidence
/// rpc_mark_phone_verified accepts.
class VerifyPhoneScreen extends ConsumerStatefulWidget {
  const VerifyPhoneScreen({super.key});

  @override
  ConsumerState<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends ConsumerState<VerifyPhoneScreen> {
  bool _sent = false;
  bool _sending = false;

  Future<void> _send(String phoneE164) async {
    setState(() => _sending = true);
    try {
      await ref
          .read(firebasePhoneAuthServiceProvider)
          .sendCode(
            phoneE164: phoneE164,
            onCodeSent: () {
              if (mounted) setState(() => _sent = true);
            },
            onError: (message) {
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final repo = ref.read(authRepositoryProvider);
    final phone = profileAsync.value?.phoneE164;

    final signOut = TextButton(
      onPressed: () => repo.signOut(),
      child: const Text('تسجيل الخروج'),
    );

    if (profileAsync.isLoading && profileAsync.value == null) {
      return const Scaffold(body: LoadingView());
    }

    if (phone == null) {
      return AuthPage(
        title: 'تأكيد رقم الهاتف',
        actions: [signOut],
        child: const Text(
          'لا يوجد رقم هاتف على هذا الحساب. تواصل مع الدعم.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return AuthPage(
      title: 'تأكيد رقم الهاتف',
      actions: [signOut],
      child: !_sent
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Iconsax.verify_copy, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'لحماية حسابك، أكِّد إن رقم الهاتف ده بتاعك. هنبعتلك كود في رسالة.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  phone,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _sending ? null : () => _send(phone),
                  child: _sending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إرسال الكود'),
                ),
              ],
            )
          : OtpCodeForm(
              destination: phone,
              onVerify: (code) async {
                final token = await ref
                    .read(firebasePhoneAuthServiceProvider)
                    .verifyCode(code);
                await repo.markPhoneVerifiedWithFirebaseToken(token);
                ref.invalidate(currentUserProfileProvider);
                final verified =
                    (await ref.read(
                      currentUserProfileProvider.future,
                    ))?.isPhoneVerified ??
                    false;
                if (!context.mounted) return;
                if (verified) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تأكيد رقم الهاتف')),
                  );
                  // When verification was required the router moves on by
                  // itself; when opened voluntarily, go back.
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                } else {
                  throw const AppException(
                    'تعذَّر تأكيد الرقم. اطلب كودًا جديدًا وحاول مرة أخرى.',
                  );
                }
              },
              onResend: () => ref
                  .read(firebasePhoneAuthServiceProvider)
                  .sendCode(
                    phoneE164: phone,
                    onCodeSent: () {},
                    // verificationFailed fires from its own async callback,
                    // independent of the Future sendCode() returns -- by
                    // the time it fires, OtpCodeForm's own try/catch around
                    // `await onResend()` has usually already moved on, so a
                    // throw here would escape as an unhandled error instead
                    // of reaching it. Show the message directly instead,
                    // same as _send() above.
                    onError: (message) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
                  ),
            ),
    );
  }
}
