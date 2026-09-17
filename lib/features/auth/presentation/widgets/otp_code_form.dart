import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/validators.dart';

/// Code entry + resend with a cooldown, shared by every OTP screen.
///
/// The cooldown only keeps the UI honest: Supabase Auth enforces the real
/// minimum interval between texts (and answers over_sms_send_rate_limit if
/// it's hit anyway, which is shown like any other error).
class OtpCodeForm extends StatefulWidget {
  /// Shown in the explanation, e.g. "+201012345678".
  final String phoneE164;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function() onResend;

  /// Seconds before "resend" unlocks. A code has normally just been sent when
  /// this form appears, so it starts locked.
  final int resendCooldownSeconds;

  const OtpCodeForm({
    super.key,
    required this.phoneE164,
    required this.onVerify,
    required this.onResend,
    this.resendCooldownSeconds = 60,
  });

  @override
  State<OtpCodeForm> createState() => _OtpCodeFormState();
}

class _OtpCodeFormState extends State<OtpCodeForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  Timer? _timer;
  late int _secondsLeft;
  bool _verifying = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _secondsLeft = widget.resendCooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
  }

  Future<void> _verify() async {
    if (_verifying) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _verifying = true);
    try {
      await widget.onVerify(_codeCtrl.text.trim());
    } catch (e) {
      _codeCtrl.clear();
      _showError(e);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _secondsLeft > 0) return;
    setState(() => _resending = true);
    try {
      await widget.onResend();
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إرسال كود جديد')));
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'أرسلنا كود من ${Validators.otpLength} أرقام في رسالة إلى',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            widget.phoneE164,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('otp-code-field'),
            controller: _codeCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            maxLength: Validators.otpLength,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 12),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '••••••',
            ),
            validator: Validators.otpCode,
            onFieldSubmitted: (_) => _verify(),
            onChanged: (v) {
              // Most people paste or autofill the whole code: go straight on.
              if (v.length == Validators.otpLength) _verify();
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('otp-verify-button'),
            onPressed: _verifying ? null : _verify,
            child: _verifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('تأكيد'),
          ),
          const SizedBox(height: 12),
          TextButton(
            key: const Key('otp-resend-button'),
            onPressed: _secondsLeft > 0 || _resending ? null : _resend,
            child: Text(
              _secondsLeft > 0
                  ? 'إعادة الإرسال بعد $_secondsLeft ثانية'
                  : 'لم يصلك الكود؟ إعادة الإرسال',
            ),
          ),
        ],
      ),
    );
  }
}
