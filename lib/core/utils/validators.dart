/// Client-side validation is a UX convenience only — every rule here is
/// re-enforced server-side (constraints/RPC checks), never trusted alone.
/// See docs/04-security-architecture.md §5.
abstract final class Validators {
  static final _egyptPhone = RegExp(r'^01[0125][0-9]{8}$');

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'رقم الهاتف مطلوب';
    if (!_egyptPhone.hasMatch(value.trim())) return 'رقم هاتف غير صحيح (مثال: 01012345678)';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
    if (value.length < 8) return 'كلمة المرور 8 أحرف على الأقل';
    return null;
  }

  static String? required(String? value, [String label = 'هذا الحقل']) {
    if (value == null || value.trim().isEmpty) return '$label مطلوب';
    return null;
  }

  static String? positiveNumber(String? value, [String label = 'القيمة']) {
    if (value == null || value.trim().isEmpty) return '$label مطلوبة';
    final n = num.tryParse(value.trim());
    if (n == null) return '$label غير صحيحة';
    if (n <= 0) return '$label يجب أن تكون أكبر من صفر';
    return null;
  }

  /// Converts a local Egyptian number (01xxxxxxxxx) to the E.164 format
  /// Supabase phone auth expects (+20...).
  static String toE164Egypt(String local) {
    final digits = local.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('20')) return '+$digits';
    if (digits.startsWith('0')) return '+20${digits.substring(1)}';
    return '+20$digits';
  }
}
