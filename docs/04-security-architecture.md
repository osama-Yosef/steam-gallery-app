# المرحلة 3ب / الأمان — Security Architecture

## 1. Authentication

- Supabase Auth (`email` + `password`) — Assumption A1 في `01-system-analysis.md`.
- العميل: Self Sign-up مفتوح، `role` يُضبط تلقائيًا `customer` عبر Trigger `handle_new_user()` على `auth.users` (لا يمكن للعميل اختيار role آخر عند التسجيل).
- الصنايعي: **لا Self Sign-up إطلاقًا**. يُنشأ حصرًا عبر Edge Function `create-technician` تستخدم `service_role key` (يعمل فقط على السيرفر، أبدًا داخل Flutter) — Admin يستدعيها بعد التحقق من صلاحيته.
- الأدمن: يُنشأ يدويًا (Seed أول Admin عبر SQL/Dashboard)، ثم يمكن لأدمن موجود إنشاء أدمن آخر بنفس آلية Edge Function.
- `role` يُخزَّن في `public.users.role` **وأيضًا** يُدمَج داخل `auth.users.raw_app_meta_data.role` عبر Trigger، بحيث يظهر داخل الـ JWT مباشرة (`auth.jwt() ->> 'role'`) دون الحاجة لـ Query إضافي في كل RLS Policy — أسرع وأكثر أمانًا لأن `app_metadata` لا يمكن للمستخدم تعديله من العميل (بخلاف `user_metadata`).

## 2. Authorization — Row Level Security

**القاعدة الذهبية: RLS مفعّل (`ENABLE ROW LEVEL SECURITY`) على كل جدول في `public` schema بدون استثناء واحد، بما فيها الجداول المرجعية.**

نمط عام للـ Policies (مُفصَّل بالكامل في `supabase/migrations/0011_rls_policies.sql`):

```sql
-- Helper function تُستخدم في كل الـ Policies
create or replace function auth_role() returns text
language sql stable as $$
  select coalesce(auth.jwt() ->> 'role', 'anon');
$$;

create or replace function is_admin() returns boolean
language sql stable as $$ select auth_role() = 'admin'; $$;

create or replace function is_technician() returns boolean
language sql stable as $$ select auth_role() = 'technician'; $$;
```

### أمثلة سياسات حرجة

| الجدول | Policy |
|---|---|
| `products` | SELECT: للجميع (المصادَق عليهم) حيث `is_active=true`؛ Admin يرى الكل. INSERT/UPDATE/DELETE: `is_admin()` فقط. |
| `products.cost_price` | **لا Policy عمودية في RLS مباشرة** (RLS يعمل على مستوى الصف)؛ الحماية تكون عبر **View منفصل** `products_public` بدون `cost_price` يُستخدم في واجهة العميل، بينما الجدول الأصلي يُقرأ فقط من سياق Admin/Technician. |
| `warehouse_stock` | SELECT/INSERT/UPDATE: `is_admin()` فقط مباشرة؛ أي تعديل فعلي يمر عبر RPC (`security definer`) وليس عبر REST مباشر أصلاً. |
| `technician_bag_stock` | SELECT: `is_admin() OR (is_technician() AND technician_bag_id IN (SELECT id FROM technician_bags WHERE technician_id = auth.uid()))`. لا INSERT/UPDATE مباشر — فقط عبر RPC. |
| `sales` | INSERT: عبر RPC فقط (REST INSERT مباشر مرفوض بعدم منح صلاحية INSERT للجدول أصلاً — فقط لـ `service_role`/الدوال). SELECT: `is_admin() OR technician_id = auth.uid()`. |
| `maintenance_requests` | SELECT: `is_admin() OR customer_id = auth.uid() OR assigned_technician_id = auth.uid()`. INSERT: العميل لنفسه فقط (`customer_id = auth.uid()`). UPDATE status: عبر RPC فقط، والـ RPC تتحقق أن الصنايعي المستدعي = `assigned_technician_id`. |
| `customer_account_transactions` | SELECT: `is_admin() OR customer_id = auth.uid()`. لا INSERT/UPDATE/DELETE مباشر أبدًا (RPC فقط عبر `security definer`). |
| `technician_account_transactions` | SELECT: `is_admin() OR technician_id = auth.uid()`. لا كتابة مباشرة. |
| `cash_transactions` | SELECT: `is_admin()` فقط. لا INSERT/UPDATE/DELETE مباشر من أي عميل REST — فقط عبر RPC داخلي تستدعيه دوال أخرى. |
| `expenses` | SELECT/INSERT: `is_admin()` فقط. لا UPDATE/DELETE (تصحيح بمصروف عكسي جديد فقط إن لزم، عبر عملية adjustment موثقة). |
| `audit_logs` | SELECT: `is_admin()` فقط. **لا** INSERT/UPDATE/DELETE من أي مستخدم — تُدرَج فقط عبر Triggers بصلاحية `security definer`. |
| `users` | SELECT: المستخدم لنفسه، أو `is_admin()` للكل. UPDATE: المستخدم لبياناته الأساسية (name, avatar) فقط، **باستثناء عمود `role`** الممنوع تعديله إلا عبر Function خاصة بصلاحية Admin (`rpc_admin_set_role`) — يُفرض عبر `REVOKE UPDATE(role) ON users FROM authenticated` + `GRANT` فقط لدالة `security definer`. |
| `notifications` | SELECT/UPDATE(is_read): `user_id = auth.uid()` فقط. INSERT: من Triggers فقط. |

### منع تصعيد الصلاحيات (Role Escalation)
- عمود `users.role` محمي بـ `REVOKE UPDATE` عام + `GRANT UPDATE` فقط عبر Function `security definer` تتحقق أن المستدعي `is_admin()`.
- `auth.users.raw_app_meta_data` لا يمكن تعديله من طرف العميل عبر REST (Supabase تمنع ذلك افتراضيًا؛ فقط `service_role` يعدّله)، لذلك تحديث الـ `role` في الـ JWT يتم فقط داخل Edge Function/Trigger على السيرفر.

## 3. RPC Functions كطبقة الحماية الحقيقية

كل عملية "حساسة" (بيع، صرف بضاعة، توريد، مصروف، جرد، صيانة) **لا تُعرَّض كـ INSERT/UPDATE مباشر على REST API إطلاقًا** — الجداول المعنية تُمنَح صلاحيات `SELECT` فقط لـ `authenticated`، والكتابة حصرًا عبر:

```sql
grant execute on function rpc_technician_sale(...) to authenticated;
```

مع تحقق داخلي صريح من الهوية والدور في بداية كل دالة:

```sql
if auth.uid() is null then raise exception 'unauthorized'; end if;
if not (is_admin() or (is_technician() and technician_id = auth.uid())) then
  raise exception 'forbidden';
end if;
```

هذا يعني: حتى لو تم تجاوز واجهة Flutter بالكامل (مثلاً عبر Postman بتوكن صنايعي حقيقي)، لا يمكن تنفيذ أي عملية تتجاوز صلاحياته — **الأمان بالكامل على مستوى قاعدة البيانات، وليس افتراضًا في الواجهة.**

## 4. Storage Security

Buckets: `products` (public read), `maintenance` (private), `avatars` (public read), `attachments` (private — مرفقات مصروفات).

```sql
-- products: قراءة عامة، كتابة Admin فقط
create policy "products read" on storage.objects for select
  using (bucket_id = 'products');
create policy "products admin write" on storage.objects for insert
  with check (bucket_id = 'products' and is_admin());

-- maintenance: خاص بصاحب الطلب + الصنايعي المسند + الأدمن
create policy "maintenance owner rw" on storage.objects for select using (
  bucket_id = 'maintenance' and (
    is_admin() or
    (storage.foldername(name))[1] = auth.uid()::text or -- المسار: maintenance/{customer_id}/...
    exists (select 1 from maintenance_requests mr
            where mr.id::text = (storage.foldername(name))[2]
            and mr.assigned_technician_id = auth.uid())
  )
);

-- avatars: كل مستخدم يكتب في مجلده فقط
create policy "avatar own write" on storage.objects for insert
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
```

التفصيل الكامل في `supabase/migrations/0012_storage_buckets_policies.sql`.

## 5. Input Validation

- كل RPC Function تتحقق من: قيم موجبة (`quantity > 0`, `amount > 0`)، وجود الـ FK فعليًا، حالة الكيان تسمح بالانتقال (مثال: لا يمكن `complete_maintenance` على طلب `status='cancelled'`).
- Flutter Forms تُطبِّق نفس القيود كـ UX سريع (رسائل خطأ فورية)، لكنها **ليست** خط الدفاع الوحيد أبدًا — التكرار مقصود (Defense in Depth).
- لا SQL خام يُبنى من نصوص المستخدم في أي مكان — استخدام Supabase Client/PostgREST/RPC بمعاملات مُلزَمة (Parameterized) دائمًا، مما يمنع SQL Injection ببنية الأداة نفسها.

## 6. Secrets

| السر | أين يُخزَّن |
|---|---|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | داخل Flutter عبر `--dart-define` وقت الـ Build (ليست سرًا حقيقيًا — الـ anon key محمي بـ RLS أصلاً) |
| `SUPABASE_SERVICE_ROLE_KEY` | **فقط** كـ Environment Variable داخل Supabase Edge Functions. لا يظهر في أي كود Flutter أو Git repo |
| مفاتيح خرائط/إشعارات (إن استُخدمت) | Edge Functions أو `.env` غير مرفوع لـ Git |

`.gitignore` يجب أن يشمل `.env`, `*.g.dart` (اختياري)، ومفاتيح التوقيع.

## 7. Race Conditions & Duplicate Transactions

راجع القسم 12 في `03-business-logic.md`: `SELECT ... FOR UPDATE` + Constraints + `client_request_id UNIQUE` كطبقة حماية ثلاثية:
1. القفل الذري يمنع التزامن الخاطئ.
2. الـ CHECK constraints (`quantity >= 0`) تمنع أي تسرب نظري.
3. `client_request_id` يمنع تكرار نفس الطلب عند إعادة الإرسال بسبب ضعف الشبكة.

## 8. Audit Logs — التنفيذ

Trigger عام يُرفَق على الجداول الحساسة (`products`, `users`, `expenses`, `technician_bag_stock` تغييرات عبر stock_movements فقط، إلخ):

```sql
create or replace function audit_trigger() returns trigger
language plpgsql security definer as $$
begin
  insert into audit_logs(actor_id, action, table_name, record_id, old_data, new_data)
  values (
    auth.uid(), TG_OP, TG_TABLE_NAME,
    coalesce(new.id, old.id),
    case when TG_OP != 'INSERT' then to_jsonb(old) end,
    case when TG_OP != 'DELETE' then to_jsonb(new) end
  );
  return coalesce(new, old);
end;
$$;
```

`audit_logs` نفسه بلا أي صلاحية DML للمستخدمين — الكتابة فقط عبر هذه الدالة بصلاحية `security definer`، والقراءة `is_admin()` فقط.

## 9. Checklist أمان قبل أي Production Deploy

- [ ] RLS مفعّل على كل جدول (`select tablename from pg_tables where schemaname='public' and rowsecurity=false` يجب أن يرجع صفرًا).
- [ ] لا صلاحية `INSERT/UPDATE/DELETE` مباشرة لـ `authenticated` على جداول Ledger (`stock_movements`, `cash_transactions`, `*_account_transactions`, `audit_logs`).
- [ ] `service_role key` غير موجود في أي مكان بمستودع Flutter.
- [ ] كل RPC حساسة تتحقق من `auth.uid()` والدور داخليًا.
- [ ] Storage policies مختبرة (محاولة قراءة صورة صيانة لعميل آخر يجب أن تفشل).
- [ ] اختبار Race Condition فعليًا (طلبان متزامنان لآخر قطعة) قبل الإطلاق.
