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

  /// Error codes raised by the rpc_* functions, checked in order. More
  /// specific codes must come before any code they contain as a substring —
  /// e.g. every FORBIDDEN_OR_* before plain FORBIDDEN, which used to swallow
  /// them all.
  static const List<(String, String)> _rpcErrorMessages = [
    ('INSUFFICIENT_STOCK', 'الكمية المطلوبة غير متوفرة'),
    // Setup problems the admin can actually fix — never the generic message.
    (
      'NO_MAIN_WAREHOUSE',
      'لا يوجد مخزن رئيسي مُفعَّل — أنشئ المخزن الرئيسي أولًا',
    ),
    ('NO_CASHBOX', 'لا توجد خزنة مُفعَّلة — أنشئ الخزنة أولًا'),
    ('INSUFFICIENT_CASH', 'رصيد الخزنة لا يكفي لهذه العملية'),
    ('FORBIDDEN_OR_NOT_ASSIGNED', 'هذا الطلب غير مسنَد لك'),
    ('FORBIDDEN_OR_NOT_IN_PROGRESS', 'لا يمكن إنهاء طلب لم يبدأ تنفيذه بعد'),
    ('FORBIDDEN_OR_NOT_CANCELLABLE', 'لا يمكن إلغاء هذا الطلب الآن'),
    ('FORBIDDEN', 'ليست لديك صلاحية لتنفيذ هذه العملية'),
    ('CANNOT_CHANGE_OWN_ACCOUNT', 'لا يمكنك تغيير صلاحية أو حالة حسابك أنت'),
    ('USER_NOT_FOUND', 'المستخدم غير موجود'),
    ('CUSTOMER_NOT_FOUND', 'العميل غير موجود'),
    (
      'IDEMPOTENCY_KEY_CONFLICT',
      'تعارض في الطلب، أعد فتح الشاشة وحاول مرة أخرى',
    ),
    ('INVALID_QUANTITY', 'الكمية المدخلة غير صحيحة'),
    ('INVALID_AMOUNT', 'المبلغ المدخل غير صحيح'),
    ('INVALID_DISCOUNT', 'قيمة الخصم غير صحيحة'),
    ('PAYMENT_EXCEEDS_TOTAL', 'المبلغ المحصَّل أكبر من إجمالي الفاتورة'),
    ('AMOUNT_EXCEEDS_REMAINING', 'المبلغ أكبر من المتبقي على الطلب'),
    ('DEFERRED_REQUIRES_CUSTOMER', 'البيع الآجل يحتاج عميلًا مسجَّلًا'),
    ('DEFERRED_NOT_SUPPORTED', 'البيع الآجل غير متاح هنا'),
    ('EMPTY_ORDER', 'لا توجد أصناف'),
    ('TOO_MANY_ITEMS', 'عدد الأصناف أكبر من المسموح'),
    ('INVALID_ITEM', 'بيانات أحد الأصناف غير صحيحة'),
    ('INPUT_TOO_LONG', 'أحد الحقول أطول من المسموح'),
    ('INVALID_LOCATION', 'الموقع الجغرافي غير صحيح'),
    ('INVALID_PHONE', 'رقم الهاتف غير صحيح'),
    ('INVALID_INPUT', 'البيانات المدخلة غير مكتملة أو غير صحيحة'),
    ('REASON_REQUIRED', 'لازم تكتب السبب'),
    ('PRODUCT_NOT_FOUND', 'المنتج غير موجود أو غير متاح'),
    ('TECHNICIAN_BAG_NOT_FOUND', 'لا توجد شنطة بضاعة لهذا الصنايعي'),
    ('TECHNICIAN_NOT_AVAILABLE', 'الصنايعي غير موجود أو غير مُفعَّل'),
    (
      'INVALID_STATUS_TRANSITION',
      'لا يمكن نقل الطلب لهذه الحالة من حالته الحالية',
    ),
    ('ORDER_NOT_FOUND', 'الطلب غير موجود'),
    ('ORDER_NOT_PENDING', 'لا يمكن تنفيذ هذا الإجراء على حالة الطلب الحالية'),
    ('ORDER_NOT_CANCELLABLE', 'لا يمكن إلغاء هذا الطلب في حالته الحالية'),
    ('ORDER_NOT_PAYABLE', 'لا يمكن تسجيل دفعة على طلب ملغي أو مرتجع'),
    ('ORDER_CUSTOMER_MISMATCH', 'الطلب لا يخص هذا العميل'),
    ('REQUEST_NOT_WAITING', 'طلب الصيانة لم يعد في حالة الانتظار'),
    ('REQUEST_NOT_FOUND', 'طلب الصيانة غير موجود'),
    ('REQUEST_NOT_INVOICEABLE', 'لا يمكن عمل فاتورة لطلب لم يبدأ تنفيذه'),
    (
      'TOO_MANY_ACTIVE_REQUESTS',
      'لديك طلبات صيانة مفتوحة كثيرة، انتظر انتهاء بعضها',
    ),
    ('SUPPLY_NOT_FOUND', 'التوريد غير موجود'),
    ('SUPPLY_NOT_PENDING', 'تمت مراجعة هذا التوريد بالفعل'),
    ('COUNT_NOT_DRAFT', 'الجرد مُعتمَد بالفعل ولا يمكن تعديله'),
    (
      'ITEM_NOT_FOUND_OR_COUNT_CLOSED',
      'لا يمكن تعديل هذا الصنف بعد اعتماد الجرد',
    ),
    ('chk_reason_required_if_diff', 'لازم تكتب سبب الفرق في الكمية'),
    ('row-level security', 'ليست لديك صلاحية للوصول لهذه البيانات'),
  ];

  static String _mapPostgrestMessage(PostgrestException e) {
    final msg = e.message;
    for (final (code, messageAr) in _rpcErrorMessages) {
      if (msg.contains(code)) return messageAr;
    }
    // A function the caller isn't granted (0029's EXECUTE allowlist).
    if (e.code == '42501') return 'ليست لديك صلاحية لتنفيذ هذه العملية';
    return 'تعذَّر تنفيذ العملية. حاول مرة أخرى.';
  }
}
