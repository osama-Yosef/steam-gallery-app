import 'package:supabase_flutter/supabase_flutter.dart';

/// Every repository throws this instead of leaking raw
/// PostgrestException/AuthException to the UI. Screens only ever need to
/// show `.messageAr`.
class AppException implements Exception {
  final String messageAr;
  final Object? cause;

  const AppException(this.messageAr, [this.cause]);

  factory AppException.from(Object error) {
    if (error is AppException) return error;

    if (error is AuthException) {
      return AppException(_mapAuthMessage(error), error);
    }

    if (error is PostgrestException) {
      return AppException(_mapPostgrestMessage(error), error);
    }

    return AppException('حدث خطأ غير متوقع. حاول مرة أخرى.', error);
  }

  /// Prefer Supabase's own `code` (a fixed, documented enum — see
  /// https://supabase.com/docs/guides/auth/debugging/error-codes) over
  /// guessing from the free-text `message`. A loose substring check like
  /// `message.contains('password')` used to catch messages that have
  /// nothing to do with password strength (rate limits, transient network
  /// errors, etc.) and wrongly tell the user their correct password is
  /// invalid — found via live testing when a correct 8-character password
  /// intermittently got this exact wrong diagnosis.
  static String _mapAuthMessage(AuthException error) {
    final code = error.code;
    if (code == 'weak_password' || code == 'same_password') {
      return 'كلمة المرور غير صالحة (٨ أحرف على الأقل)';
    }
    if (code == 'over_request_rate_limit' ||
        code == 'over_sms_send_rate_limit' ||
        code == 'over_email_send_rate_limit') {
      return 'محاولات كثيرة جدًا، انتظر شوية وحاول تاني';
    }

    final m = error.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'رقم الهاتف أو كلمة المرور غير صحيحة';
    }
    if (m.contains('user already registered') || m.contains('already exists')) {
      return 'هذا الرقم مسجَّل بالفعل';
    }
    if (m.contains('network') ||
        m.contains('socket') ||
        m.contains('timeout')) {
      return 'تعذَّر الاتصال بالخادم، تحقق من الإنترنت';
    }
    return 'تعذَّر تسجيل الدخول. حاول مرة أخرى.';
  }

  static String _mapPostgrestMessage(PostgrestException e) {
    final msg = e.message;
    if (msg.contains('INSUFFICIENT_STOCK')) return 'الكمية المطلوبة غير متوفرة';
    // Checked before FORBIDDEN: both these codes contain no overlapping text,
    // but they describe a setup problem the admin can actually fix, so they
    // must never fall through to the generic "تعذَّر تنفيذ العملية".
    if (msg.contains('NO_MAIN_WAREHOUSE')) {
      return 'لا يوجد مخزن رئيسي مُفعَّل — أنشئ المخزن الرئيسي أولًا';
    }
    if (msg.contains('NO_CASHBOX')) {
      return 'لا توجد خزنة مُفعَّلة — أنشئ الخزنة أولًا';
    }
    if (msg.contains('INSUFFICIENT_CASH')) {
      return 'رصيد الخزنة لا يكفي لسحب هذا المبلغ';
    }
    if (msg.contains('FORBIDDEN')) return 'ليست لديك صلاحية لتنفيذ هذه العملية';
    if (msg.contains('INVALID_QUANTITY')) return 'الكمية المدخلة غير صحيحة';
    if (msg.contains('INVALID_AMOUNT')) return 'المبلغ المدخل غير صحيح';
    if (msg.contains('PRODUCT_NOT_FOUND')) {
      return 'المنتج غير موجود أو غير متاح';
    }
    if (msg.contains('TECHNICIAN_BAG_NOT_FOUND')) {
      return 'لا توجد شنطة بضاعة لهذا الصنايعي';
    }
    if (msg.contains('ORDER_NOT_PENDING')) {
      return 'لا يمكن تنفيذ هذا الإجراء على حالة الطلب الحالية';
    }
    if (msg.contains('ORDER_NOT_CANCELLABLE')) {
      return 'لا يمكن إلغاء هذا الطلب في حالته الحالية';
    }
    if (msg.contains('REQUEST_NOT_WAITING')) {
      return 'طلب الصيانة لم يعد في حالة الانتظار';
    }
    if (msg.contains('FORBIDDEN_OR_NOT_ASSIGNED')) {
      return 'هذا الطلب غير مسنَد لك';
    }
    if (msg.contains('FORBIDDEN_OR_NOT_IN_PROGRESS')) {
      return 'لا يمكن إنهاء طلب لم يبدأ تنفيذه بعد';
    }
    if (msg.contains('FORBIDDEN_OR_NOT_CANCELLABLE')) {
      return 'لا يمكن إلغاء هذا الطلب الآن';
    }
    if (msg.contains('COUNT_NOT_DRAFT')) {
      return 'الجرد مُعتمَد بالفعل ولا يمكن تعديله';
    }
    if (msg.contains('ITEM_NOT_FOUND_OR_COUNT_CLOSED')) {
      return 'لا يمكن تعديل هذا الصنف بعد اعتماد الجرد';
    }
    if (msg.contains('chk_reason_required_if_diff')) {
      return 'لازم تكتب سبب الفرق في الكمية';
    }
    if (msg.contains('row-level security')) {
      return 'ليست لديك صلاحية للوصول لهذه البيانات';
    }
    return 'تعذَّر تنفيذ العملية. حاول مرة أخرى.';
  }
}
