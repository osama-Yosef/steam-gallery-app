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
    switch (code) {
      case 'weak_password':
        return 'كلمة المرور غير صالحة (٨ أحرف على الأقل)';
      case 'same_password':
        return 'كلمة المرور الجديدة لازم تختلف عن القديمة';
      case 'over_request_rate_limit' ||
          'over_sms_send_rate_limit' ||
          'over_email_send_rate_limit':
        return 'محاولات كثيرة جدًا، انتظر شوية وحاول تاني';
      // Supabase answers both a wrong code and an expired one with this.
      case 'otp_expired':
        return 'الكود غير صحيح أو انتهت صلاحيته';
      case 'phone_not_confirmed':
        return 'رقم الهاتف لم يتم تأكيده بعد';
      case 'user_banned':
        return 'هذا الحساب موقوف. تواصل مع الإدارة.';
      case 'phone_exists' || 'user_already_exists':
        return 'هذا الرقم مسجَّل بالفعل';
      case 'sms_send_failed':
        return 'تعذَّر إرسال الرسالة. تأكد من الرقم وحاول بعد قليل.';
      case 'signup_disabled':
        return 'التسجيل مغلق حاليًا';
      case 'phone_provider_disabled' || 'otp_disabled':
        return 'التحقق برسالة غير متاح حاليًا';
      case 'session_expired' ||
          'session_not_found' ||
          'refresh_token_not_found':
        return 'انتهت الجلسة، سجِّل الدخول مرة أخرى';
      case 'reauthentication_needed' || 'reauthentication_not_valid':
        return 'لازم تسجِّل الدخول من جديد قبل تغيير كلمة المرور';
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
    if (m.contains('token has expired or is invalid')) {
      return 'الكود غير صحيح أو انتهت صلاحيته';
    }
    return 'تعذَّرت العملية. حاول مرة أخرى.';
  }

  /// Error codes raised by the rpc_* functions, checked in order. More
  /// specific codes must come before any code they contain as a substring —
  /// e.g. every FORBIDDEN_OR_* before plain FORBIDDEN, which used to swallow
  /// them all.
  static const List<(String, String)> _rpcErrorMessages = [
    ('INSUFFICIENT_STOCK', 'الكمية المطلوبة غير متوفرة'),
    // Catalogue browsing (0034).
    ('INVALID_PRICE_RANGE', 'نطاق السعر غير صحيح'),
    ('INVALID_SORT', 'طريقة الترتيب غير مدعومة'),
    ('INVALID_PAGE', 'تعذَّر تحميل هذه الصفحة من النتائج'),
    ('product_categories_name_len', 'اسم القسم مطلوب ولا يزيد عن 60 حرفًا'),
    ('product_categories_not_own_parent', 'القسم لا يمكن أن يكون تابعًا لنفسه'),
    // Checkout (0036): a saved address that no longer exists or isn't covered.
    ('ADDRESS_NOT_FOUND', 'العنوان ده مش موجود — اختر عنوانًا تانيًا'),
    (
      'ADDRESS_NOT_SERVICEABLE',
      'المنطقة دي غير مغطاة حاليًا — اختر عنوانًا تانيًا',
    ),
    // InstaPay manual verification (0039).
    ('REFERENCE_REQUIRED', 'اكتب رقم أو مرجع العملية'),
    ('PROOF_REQUIRED', 'أرفق صورة إثبات التحويل'),
    ('INVALID_PROOF_PATH', 'تعذَّر التحقق من صورة الإثبات — أعد المحاولة'),
    (
      'VERIFICATION_ALREADY_PENDING',
      'في تحويل بانتظار المراجعة لنفس الطلب بالفعل',
    ),
    (
      'DUPLICATE_REFERENCE_OR_REQUEST',
      'المرجع ده مُسجَّل قبل كدا',
    ),
    (
      'PAYMENT_NOT_PENDING_VERIFICATION',
      'التحويل ده اتراجع قبل كدا',
    ),
    // Wallet (0040).
    ('INSUFFICIENT_WALLET_BALANCE', 'رصيد محفظتك مش كافي لدفع المبلغ ده'),
    // Setup problems the admin can actually fix — never the generic message.
    (
      'NO_MAIN_WAREHOUSE',
      'لا يوجد مخزن رئيسي مُفعَّل — أنشئ المخزن الرئيسي أولًا',
    ),
    ('NO_CASHBOX', 'لا توجد خزنة مُفعَّلة — أنشئ الخزنة أولًا'),
    ('INSUFFICIENT_CASH', 'رصيد الخزنة لا يكفي لهذه العملية'),
    ('INVALID_REFUND_KIND', 'اختر الخزنة التي سيُخصم منها المبلغ (نقدي أو تحويل)'),
    ('FORBIDDEN_OR_NOT_ASSIGNED', 'هذا الطلب غير مسنَد لك'),
    ('FORBIDDEN_OR_NOT_IN_PROGRESS', 'لا يمكن إنهاء طلب لم يبدأ تنفيذه بعد'),
    ('FORBIDDEN_OR_NOT_CANCELLABLE', 'لا يمكن إلغاء هذا الطلب الآن'),
    ('FORBIDDEN', 'ليست لديك صلاحية لتنفيذ هذه العملية'),
    ('CANNOT_CHANGE_OWN_ACCOUNT', 'لا يمكنك تغيير صلاحية أو حالة حسابك أنت'),
    ('OTP_SESSION_REQUIRED', 'أكِّد رقمك بالكود المرسل في رسالة أولًا'),
    ('PHONE_NOT_VERIFIED', 'رقم الهاتف غير مؤكَّد'),
    ('UNKNOWN_SETTING', 'إعداد غير معروف'),
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
    (
      'LOCATION_OUTSIDE_CITY',
      'الموقع بعيد عن المدينة المختارة — راجع المدينة أو مكان المؤشر',
    ),
    ('CITY_NOT_AVAILABLE', 'المدينة غير متاحة حاليًا'),
    ('CITY_NOT_FOUND', 'المدينة غير موجودة'),
    ('TOO_MANY_ADDRESSES', 'وصلت للحد الأقصى من العناوين (10)'),
    ('ADDRESS_NOT_FOUND', 'العنوان غير موجود'),
    (
      'customer_addresses_one_default',
      'تعذَّر تعيين العنوان الافتراضي، حاول مرة أخرى',
    ),
    ('cities_country_id_name_ar_key', 'توجد مدينة بنفس الاسم في هذه الدولة'),
    (
      'service_areas_city_id_name_ar_key',
      'توجد منطقة بنفس الاسم في هذه المدينة',
    ),
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
    (
      'SHIPPING_FEE_NOT_APPROVED',
      'لازم تحديد سعر الشحن وموافقة العميل عليه قبل تأكيد الطلب',
    ),
    (
      'SHIPPING_FEE_NOT_PENDING',
      'لا يوجد سعر شحن بانتظار ردك حاليًا',
    ),
    ('ORDER_NOT_FOUND', 'الطلب غير موجود'),
    ('ORDER_NOT_PENDING', 'لا يمكن تنفيذ هذا الإجراء على حالة الطلب الحالية'),
    ('ORDER_NOT_CANCELLABLE', 'لا يمكن إلغاء هذا الطلب في حالته الحالية'),
    (
      'ORDER_NOT_RETURNABLE',
      'الاسترجاع متاح فقط للطلبات المُسلَّمة أو المكتملة',
    ),
    (
      'GATEWAY_REFUND_NOT_IMPLEMENTED',
      'استرداد دفعات بوابة الدفع غير متاح بعد',
    ),
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
