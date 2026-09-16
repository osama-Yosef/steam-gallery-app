import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/data/models/auth_settings.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/users_admin_providers.dart';

/// Admin control for require_verified_phone (0031). Turning it on is
/// confirmed first: with no working SMS provider, every customer who hasn't
/// verified yet would be stuck on a code that never arrives.
class PhoneVerificationSwitch extends ConsumerStatefulWidget {
  const PhoneVerificationSwitch({super.key});

  @override
  ConsumerState<PhoneVerificationSwitch> createState() =>
      _PhoneVerificationSwitchState();
}

class _PhoneVerificationSwitchState
    extends ConsumerState<PhoneVerificationSwitch> {
  bool _saving = false;

  Future<void> _set(bool value) async {
    if (value) {
      final ok = await showConfirmDialog(
        context,
        title: 'طلب تأكيد رقم الهاتف',
        message:
            'أي عميل لم يؤكد رقمه سيُطلب منه كود برسالة قبل أن يطلب أو يفتح '
            'طلب صيانة.\n\nفعِّل هذا فقط بعد تفعيل مزود الرسائل (SMS) و'
            '"Confirm phone" في إعدادات Supabase Auth، وإلا لن تصل الأكواد.',
        confirmLabel: 'تفعيل',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(usersAdminRepositoryProvider)
          .setRequireVerifiedPhone(value);
      ref.invalidate(authSettingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppException.from(e).messageAr)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(authSettingsProvider).value ?? AuthSettings.unknown;
    return SwitchListTile(
      secondary: const Icon(Icons.verified_user_outlined),
      title: const Text('طلب تأكيد رقم الهاتف للعملاء'),
      subtitle: const Text('كود برسالة قبل الطلب أو فتح طلب صيانة'),
      value: settings.requireVerifiedPhone,
      onChanged: _saving ? null : _set,
    );
  }
}
