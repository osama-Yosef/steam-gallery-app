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
      return AppException(_mapAuthMessage(error.message), error);
    }

    if (error is PostgrestException) {
      return AppException(_mapPostgrestMessage(error), error);
    }

    return AppException('حدث خطأ غير متوقع. حاول مرة أخرى.', error);
  }

  static String _mapAuthMessage(String raw) {
    final m = raw.toLowerCase();
    if (m.contains('invalid login credentials')) return 'رقم الهاتف أو كلمة المرور غير صحيحة';
    if (m.contains('user already registered') || m.contains('already exists')) {
      return 'هذا الرقم مسجَّل بالفعل';
    }
    if (m.contains('password')) return 'كلمة المرور غير صالحة (٨ أحرف على الأقل)';
    if (m.contains('network')) return 'تعذَّر الاتصال بالخادم، تحقق من الإنترنت';
    return 'تعذَّر تسجيل الدخول. حاول مرة أخرى.';
  }

  static String _mapPostgrestMessage(PostgrestException e) {
    final msg = e.message;
    if (msg.contains('INSUFFICIENT_STOCK')) return 'الكمية المطلوبة غير متوفرة';
    if (msg.contains('FORBIDDEN')) return 'ليست لديك صلاحية لتنفيذ هذه العملية';
    if (msg.contains('INVALID_AMOUNT')) return 'المبلغ المدخل غير صحيح';
    if (msg.contains('PRODUCT_NOT_FOUND')) return 'المنتج غير موجود أو غير متاح';
    if (msg.contains('TECHNICIAN_BAG_NOT_FOUND')) return 'لا توجد شنطة بضاعة لهذا الصنايعي';
    if (msg.contains('ORDER_NOT_PENDING')) return 'لا يمكن تنفيذ هذا الإجراء على حالة الطلب الحالية';
    if (msg.contains('ORDER_NOT_CANCELLABLE')) return 'لا يمكن إلغاء هذا الطلب في حالته الحالية';
    if (msg.contains('REQUEST_NOT_WAITING')) return 'طلب الصيانة لم يعد في حالة الانتظار';
    if (msg.contains('FORBIDDEN_OR_NOT_ASSIGNED')) return 'هذا الطلب غير مسنَد لك';
    if (msg.contains('FORBIDDEN_OR_NOT_IN_PROGRESS')) return 'لا يمكن إنهاء طلب لم يبدأ تنفيذه بعد';
    if (msg.contains('FORBIDDEN_OR_NOT_CANCELLABLE')) return 'لا يمكن إلغاء هذا الطلب الآن';
    if (msg.contains('COUNT_NOT_DRAFT')) return 'الجرد مُعتمَد بالفعل ولا يمكن تعديله';
    if (msg.contains('row-level security')) return 'ليست لديك صلاحية للوصول لهذه البيانات';
    return 'تعذَّر تنفيذ العملية. حاول مرة أخرى.';
  }
}
