# نظام إدارة معرض أجهزة البخار — ERP (Flutter + Supabase)

نظام ERP صغير لإدارة معرض متخصص في أجهزة البخار: مبيعات، مخازن، صنايعية وشنطهم، صيانة (Queue حي عبر Realtime)، خزنة قائمة على Ledger، حسابات عملاء وصنايعية، مصروفات، جرد، تقارير، وصلاحيات مبنية بالكامل على PostgreSQL RLS.

## حالة المشروع

المراحل 1-6 (تحليل، تصميم قاعدة البيانات، منطق العمل، الأمان، معمارية Flutter، خريطة الشاشات) **مكتملة** — راجع `docs/`. الـ Backend (Schema + RLS + Functions + Storage) **مكتمل ومنفَّذ فعليًا وموصول بمشروع Supabase حقيقي** — تم اختبار حي واكتشاف وإصلاح عدة أخطاء إنتاج فعلية (راجع `supabase/migrations/0014` إلى `0019`). تنفيذ Flutter: **Modules 0-14 من `docs/07-implementation-roadmap.md` منجزة في الكود** (`flutter analyze` نظيف، `flutter test` ناجح). Module 15 (Hardening) جزئي — راجع نهاية `docs/07-implementation-roadmap.md` لما تبقى من اختبار حي يدوي.

## بنية المستودع

```
docs/
  01-system-analysis.md          # المتطلبات، الأدوار، الصلاحيات، Workflows، Edge Cases، الافتراضات
  02-database-design.md          # ERD + شرح كل جدول وسبب وجوده
  03-business-logic.md           # تفصيل كل دورة عمل (بيع/صرف/صيانة/جرد/خزنة/أرباح...)
  04-security-architecture.md    # RLS، RPC كطبقة حماية، Storage policies، Secrets
  05-flutter-architecture.md     # اختيار Riverpod + سبب، هيكل المجلدات، Routing، Realtime
  06-screens-navigation.md       # خريطة كل الشاشات لكل دور + تدفقات التنقل
  07-implementation-roadmap.md   # خطة التنفيذ Module by Module مع معيار قبول لكل Module

supabase/
  migrations/                    # SQL كامل، يُطبَّق بالترتيب الرقمي
    0001_extensions_and_types.sql
    0002_core_tables.sql
    0003_catalog_warehouse_tables.sql
    0004_orders_maintenance_tables.sql
    0005_technician_finance_tables.sql
    0006_cashbox_customer_expense_tables.sql
    0007_inventory_notifications_audit.sql
    0008_indexes.sql
    0009_views.sql
    0010_functions_triggers.sql  # كل RPC functions + triggers (الطبقة الحقيقية للأمان والذرية)
    0011_rls_policies.sql        # RLS على كل جدول بدون استثناء
    0012_storage_buckets_policies.sql
    0013_seed.sql                 # بيانات أولية فقط (لا Fake Data)
    0014_fix_role_sync_trigger.sql            # إصلاح: مزامنة role عند تحديث app_metadata
    0015_order_items_view_and_realtime.sql    # View لإخفاء cost عن العميل + Realtime للطلبات
    0016_fix_products_public_availability.sql # إصلاح: تعطّل السلة لكل العملاء
    0017_fix_customer_role_jwt_claim.sql       # إصلاح: role مفقود من JWT عند تسجيل عميل جديد
    0018_maintenance_realtime.sql              # Realtime لقائمة الصيانة
    0019_fix_bogus_customer_rows_for_non_customers.sql
    0020_notifications_realtime.sql            # Realtime للإشعارات
  functions/
    create-user/                 # Edge Function — المكان الوحيد الذي يُستخدم فيه service_role key
```

## بنية تطبيق Flutter

`lib/features/` — كل Module من خارطة التنفيذ في مجلد مستقل (`auth`, `products`, `cart`, `orders`, `maintenance`, `inventory`, `inventory_count`, `technician_account`, `cashbox`, `customer_account`, `dashboard`, `reports`, `notifications`, `users_admin`, `audit_log`)، كل واحد بنفس البنية: `data/{models,repositories}` + `presentation/{providers,screens}`. راجع `docs/05-flutter-architecture.md`.

## تطبيق قاعدة البيانات

```bash
supabase login
supabase link --project-ref <project-ref>
supabase db push          # يطبّق كل ملفات migrations/ بالترتيب
supabase functions deploy create-user
```

بعدها أنشئ أول Admin كما هو موضح في تعليق `supabase/migrations/0013_seed.sql`.

## القواعد الصلبة التي لا تُكسَر أثناء التنفيذ

1. لا `INSERT/UPDATE` مباشر من Flutter على أي جدول Ledger (`stock_movements`, `cash_transactions`, `*_account_transactions`, `audit_logs`, `sale_items`, `order_items`) — عبر RPC فقط.
2. لا حذف على أي جدول Ledger — تصحيح بحركة عكسية جديدة فقط.
3. كل سعر يُباع/يُشترى به يُسجَّل كـ Snapshot وقت العملية، لا يُقرأ من `products` الحالي.
4. `service_role key` لا يظهر إلا داخل `supabase/functions/*`.
5. أي Module جديد في Flutter يتبع البنية في `docs/05-flutter-architecture.md` (data/domain/presentation) ولا يضع Business Logic في الـ Widgets.

## الخطوة التالية

Module 15 (Hardening) — اختبار حي فعلي على مشروعك الحقيقي: Race Conditions، محاولات وصول غير مصرَّح بها، ضبط الأيقونة/اسم التطبيق النهائي، بناء نسخة Release لأندرويد/iOS. راجع القسم الأخير من `docs/07-implementation-roadmap.md` للتفاصيل.
