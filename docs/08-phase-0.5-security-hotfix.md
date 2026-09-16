# المرحلة 0.5 — الإصلاحات الأمنية والمالية قبل التحويل إلى «مكوجي»

أول مرحلة تنفيذ بعد الفحص الفني (Phase 0). تُغلق ثغرات كانت قابلة للاستغلال بمجرد تسجيل حساب عميل، قبل البناء فوق النظام.

- **الـ Migrations:** `supabase/migrations/0029_security_hotfix_p0.sql` و `0030_finance_and_workflow_fixes_p1.sql`
- **غير هدّامة:** لا حذف جداول ولا صفوف ولا تعطيل triggers أو RLS. التغييرات في الصلاحيات والـ policies والـ views وأجسام الدوال، مع أعمدة إضافية فقط.

## ما تم إصلاحه

| # | المشكلة | الإصلاح |
|---|---|---|
| P0-1 | العميل يقرأ `products.cost_price` مباشرة | قراءة جدول `products` للأدمن والفني فقط، والعميل يقرأ `products_public` |
| P0-2 | العميل يقرأ `unit_cost_snapshot` من `order_items` و `sale_items` (وكمان COGS من `daily_sales_summary`) | الجداول الخام للأدمن (والفني لمبيعاته)، والعميل يقرأ `order_items_display` و `sale_items_display` (بدون أي عمود تكلفة) |
| P0-3 | `rpc_create_order` تقبل خصم من العميل | الخصم يُتجاهَل، والتحقق من الأصناف والكمية، والـ idempotency مربوطة بالعميل |
| P0-4 | أي مستخدم (وحتى anon) يستدعي `notify_user` و `notify_all_admins` وغيرها | سحب EXECUTE من الجميع، ثم allowlist صريحة في `private.rpc_allowlist` |
| P0-5 | `is_active` غير مُطبَّق | `auth_role()` ترجع `anon` للمستخدم الموقوف، والإيقاف يعمل ban ويلغي الجلسات |
| P0-6 | المستخدم يعدّل رقم هاتفه، والرقم يُنسخ من metadata غير موثوقة | سحب صلاحية تعديل `phone`، والرقم يأتي من `auth.users.phone` فقط، وأي رقم محجوز في حساب قديم يُحرَّر لصاحبه الحقيقي عند التسجيل (`private.release_phone`) |
| P1-7 | لا يوجد state machine للطلب | الانتقالات المسموحة فقط: confirmed←preparing/delivered، preparing←delivered، delivered←completed |
| P1-8 | رد مزدوج عند إلغاء طلب مدفوع | قيد `adjustment` بقيمة المدفوع، فيرجع رصيد العميل صفرًا |
| P1-9 | دفعات العميل بدون تحقق | التحقق من ملكية الطلب، ومنع تجاوز المتبقي، و idempotency key، و guard للخزنة |
| P1-10 | الفني يسجّل دينًا على أي عميل أو يفوتر أي طلب صيانة | الفاتورة للفني المُسنَد فقط، والعميل يُؤخذ من الطلب، مع حدود للخصم والتحصيل |
| P1-11 | الفني يسجّل التوريد لنفسه | التوريد يصبح `pending` حتى يؤكده الأدمن عبر `rpc_admin_review_technician_supply` |
| P1-13 | مدخلات الصيانة بدون حدود، والعميل يلغي طلبًا جاريًا | تحقق من المدخلات، حد 5 طلبات نشطة، والإلغاء قبل البدء فقط، وعدم إسناد فني موقوف |

## قاعدة إلزامية لكل migration قادمة

أي دالة جديدة في `public` تكون قابلة للاستدعاء من anon افتراضيًا، بسبب صلاحية PUBLIC الافتراضية في Postgres. لذلك:

```sql
insert into private.rpc_allowlist (function_name, note) values ('rpc_new_thing', 'customer')
on conflict do nothing;          -- فقط لو العميل/الفني/الأدمن يستدعيها من التطبيق
select private.apply_function_grants();   -- آخر سطر في الـ migration دائمًا
```

الدوال الداخلية (مثل `post_technician_supply` و `notify_user`) **لا تُضاف** للـ allowlist.

## خطوات النشر (بالترتيب)

1. **Backup** للداتابيز (PITR أو `pg_dump`) قبل أي شيء.
2. شغّل `tool/sql/verify_security.sql` على الداتابيز الحية واحفظ النتيجة. الاستعلام رقم 0 يؤكد أن 0001 إلى 0028 مطبقة فعلًا (فحص drift).
3. طبّق `0029` ثم `0030`.
4. أعد تشغيل `verify_security.sql`. كل استعلام مكتوب عليه «Expect 0 rows» يجب أن يرجع صفر صفوف.
5. انشر الـ Edge Function `create-user` (رسائل الخطأ لم تعد تكشف تفاصيل داخلية).
6. انشر نسخة التطبيق الجديدة.
7. شغّل `tool/hardening_check.dart` بحساب عميل تجريبي على المشروع الحقيقي.

### التوافق مع نسخ التطبيق القديمة (بين خطوتي 3 و 6)

- الطلبات والدفعات والبيع تعمل كما هي. استدعاء الدفعة بدون key مازال مقبولًا.
- **فاتورة الصيانة عند العميل** تظهر بدون أصناف في النسخة القديمة، لأنها كانت تقرأ `sale_items` مباشرة. لا يحدث crash.
- **توريد الفني** في النسخة القديمة يُسجَّل `pending` بينما تقول الشاشة إنه تم. التأكيد متاح من الأدمن في النسخة الجديدة فقط.
- لذلك: انشر التطبيق الجديد بعد الـ migrations مباشرة.

### ملاحظة عن Supabase Security Advisor

قد يُنبّه على `security_definer_view` لكل من `products_public` و `order_items_display` و `sale_items_display`. هذا **مقصود**: الثلاثة لا تحتوي أي عمود تكلفة، وكل واحد فيها فلتر صفوف صريح مع `security_barrier`.

## الاختبارات

| الأداة | ماذا تغطي | كيف تُشغَّل |
|---|---|---|
| `tool/db_tests/phase05_security_test.mjs` | كل الـ migrations على Postgres حقيقي (PGlite/WASM)، و77 فحصًا (منها تحرير الأرقام المحجوزة): تسريب التكلفة، IDOR، التسعير، idempotency، الإلغاء، التوريد، الإيقاف، ثبات الـ ledger | `cd tool/db_tests && npm install && npm test` |
| `tool/sql/verify_security.sql` | فحوص قراءة فقط على الداتابيز الحية | SQL Editor |
| `tool/hardening_check.dart` | RLS و RPC عبر PostgREST الحقيقي، ومنها probes المرحلة 0.5 | راجع رأس الملف |

حدود `db_tests`: الـ stubs لـ auth و storage ليست Supabase نفسه. PostgREST و GoTrue (الـ ban الفعلي) و Realtime تُختبر فقط بـ `hardening_check.dart` على مشروع حقيقي.

## ما لم يُنفَّذ بعد (مؤجل لمراحله)

- **OTP وتفعيل Confirm phone:** Phase 2، ويحتاج اختيار مزود SMS.
- **Route guards حسب الدور في GoRouter، و pagination للكتالوج:** Phase 5 و 6.
- **`rpc_confirm_order`:** بدون تغيير، ويُعاد تصميمها مع `payment_status` في Phase 9.
