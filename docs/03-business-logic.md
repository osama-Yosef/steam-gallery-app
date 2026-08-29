# المرحلة 3 — منطق العمل (Business Logic)

مبدأ عام: **أي عملية تُغيّر مخزونًا أو رصيدًا ماليًا تُنفَّذ حصرًا عبر RPC Function واحدة (`SECURITY DEFINER`) تُنفِّذ كل الخطوات داخل Transaction واحدة**. لا تُنفَّذ هذه الخطوات كسلسلة `INSERT`/`UPDATE` منفصلة من Flutter، حتى لا يحدث تعليق منتصف العملية أو Race Condition.

---

## 1. دورة البيع (Order من العميل)

**الحالات:** `pending → confirmed → preparing → delivered → completed` (أو `cancelled` / `returned` من أي نقطة قبل `completed`)

1. العميل يبني السلة محليًا في Flutter (لا تُكتب في DB إلا عند التأكيد).
2. عند "تأكيد الطلب": استدعاء `rpc_create_order(customer_id, items[], delivery_address, lat, lng, notes, client_request_id)`.
3. داخل الـ Function (Transaction واحدة):
   - التحقق من `client_request_id` غير مستخدم سابقًا (Idempotency) → إن كان مستخدمًا، إرجاع الطلب الموجود بدل الإنشاء المكرر.
   - لكل عنصر: قراءة `selling_price`, `cost_price` الحاليين من `products` (Snapshot)، **لا** يُحجز مخزون في هذه المرحلة (الطلب لسه `pending`، الحجز الفعلي يحدث عند `confirmed` بواسطة Admin — Assumption B1).
   - إدراج `orders` + `order_items`.
   - حالة أولية: `pending`.
4. Admin يفتح الطلب → "تأكيد" → `rpc_confirm_order(order_id)`:
   - يتحقق من توفر الكمية بالمخزن الرئيسي لكل عنصر (`FOR UPDATE`).
   - ينشئ `stock_movements` (type=`sale`, from=warehouse, to=external) لكل عنصر، بسعر `unit_cost_snapshot` المحفوظ بالطلب (وليس السعر الحالي).
   - يُنقص `warehouse_stock.quantity`.
   - `status = confirmed`.
   - إن فشل توفر أي منتج → ترجع الدالة خطأ واضحًا بالمنتج الناقص، دون تنفيذ أي جزء (Atomic كامل أو لا شيء).
5. Admin يحدّث الحالة تباعًا (`preparing` → `delivered`) عبر `rpc_update_order_status`.
6. عند `delivered`/الدفع: تسجيل الدفعات عبر `rpc_record_customer_payment(customer_id, amount, order_id, notes)`:
   - `customer_account_transactions` (type=`payment`, amount سالب).
   - `cash_transactions` (type=`sale`, amount موجب) في نفس الوقت إن كان الدفع نقدًا فوريًا.
   - عند إنشاء الطلب المؤكَّد، يُسجَّل تلقائيًا `customer_account_transactions` (type=`order_charge`, amount = total الطلب) لإضافته كمديونية أولية، ثم الدفعات تُخفِّضها.
7. `completed` تُضبط يدويًا من Admin بعد التأكد من التسليم والتحصيل الكامل (أو جزئيًا مع مديونية متبقية — مسموح).
8. **الإلغاء/الإرجاع:** `rpc_cancel_order` / `rpc_return_order`:
   - إن كانت الحالة `confirmed` أو أبعد (مخزون خُصم فعليًا) → تُنشأ حركة `return_from_customer` تعيد الكمية للمخزن.
   - إن كان هناك مبلغ مدفوع → `cash_transactions` (type=`refund`, amount سالب) و`customer_account_transactions` (type=`return_credit`).

**Assumption B1:** الحجز الفعلي للمخزون يحدث عند تأكيد الأدمن للطلب (`confirmed`) وليس عند إنشائه (`pending`)، لتفادي حجز مخزون لطلبات قد تُهمَل. إن كنت تفضل حجزًا فوريًا عند الطلب أخبرني.

---

## 2. دورة صرف بضاعة للصنايعي

`rpc_issue_stock_to_technician(technician_id, items[{product_id, quantity}], notes)` — Admin فقط:

1. لكل عنصر: `SELECT quantity FROM warehouse_stock WHERE product_id=... FOR UPDATE`.
2. التحقق `quantity >= requested` وإلا خطأ فوري بالمنتج تحديدًا (لا تنفيذ جزئي).
3. إدراج `stock_movements` (type=`issue_to_technician`, from=warehouse, to=technician_bag, unit_cost = `products.cost_price` الحالي وقت الصرف).
4. Trigger على `stock_movements` يُحدِّث `warehouse_stock -= qty` و`technician_bag_stock += qty` (upsert إن لم يوجد صف).
5. تسجيل Audit Log تلقائي (Trigger عام على `stock_movements` من هذا النوع).

---

## 3. دورة بيع الصنايعي من شنطته

`rpc_technician_sale(technician_id, customer_id?, customer_name, customer_phone, items[], payment_method, discount, paid_amount, client_request_id)`:

1. تحقق أن `technician_id` = المستخدم الحالي (أو Admin بالنيابة) عبر RLS/Function.
2. تحقق Idempotency عبر `client_request_id`.
3. لكل عنصر: `SELECT quantity FROM technician_bag_stock WHERE technician_bag_id=... AND product_id=... FOR UPDATE`؛ إن `quantity < requested` → خطأ "الكمية غير كافية في الشنطة" بدون أي تنفيذ جزئي.
4. إدراج `sales` + `sale_items` (Snapshot `unit_price`, `unit_cost` وقت البيع).
5. إدراج `stock_movements` (type=`technician_sale`, from=technician_bag, to=external) لكل عنصر → Trigger يُنقص `technician_bag_stock`.
6. إن `payment_method = cash` (أو أي طريقة تُحصَّل فورًا لدى الصنايعي وليست تحويلًا مباشرًا للمعرض): إدراج `technician_account_transactions` (type=`sale_credit`, amount = `paid_amount`) → يزيد "المطلوب توريده".
   - إن `payment_method = deferred` (آجل على العميل): تُنشأ بدلاً منها `customer_account_transactions` (type=`order_charge`) لتسجيل مديونية العميل، ولا تُحسب على الصنايعي كمبلغ واجب توريده حتى يُحصِّله.
7. **لا** يُسجَّل `cash_transactions` هنا مباشرة — نقدية الصنايعي تدخل خزنة المعرض فقط عند "التوريد" الفعلي (القسم التالي)، وليس عند البيع، لأن النقد لا يزال بحوزة الصنايعي.

---

## 4. دورة توريد الصنايعي للخزنة

`rpc_technician_supply(technician_id, amount, notes)` — الصنايعي لنفسه، أو Admin لأي صنايعي:

1. إدراج `technician_supplies`.
2. إدراج `technician_account_transactions` (type=`supply_debit`, amount) → يُخفِّض "المطلوب توريده".
3. إدراج `cash_transactions` (cashbox الافتراضية, type=`technician_deposit`, amount موجب, reference=technician_supplies.id) → يزيد رصيد خزنة المعرض فعليًا.

**حساب "المطلوب توريده" لصنايعي:**
```
SUM(technician_account_transactions WHERE type='sale_credit') 
- SUM(technician_account_transactions WHERE type='supply_debit')
± adjustments
```
هذا محسوب في `technician_account_summary` View، معروض في القسم 6 من طلب المستخدم (مثال محمد: بضاعة 15,000 / مبيعات 30,000 / تحصيل 25,000 / مطلوب توريد 5,000).

---

## 5. دورة الصيانة — Queue System (الأهم من ناحية Realtime)

### 5.1 الترتيب
لا يُخزَّن `queue_position` كعمود ثابت. يُحسَب حيًّا عبر View:

```sql
create view maintenance_queue_view as
select *,
  row_number() over (
    partition by (status in ('waiting','assigned','in_progress'))
    order by created_at asc
  ) as queue_position
from maintenance_requests
where status in ('waiting','assigned','in_progress')
order by created_at asc;
```

الفائدة: عند اكتمال/إلغاء طلب، **لا حاجة لأي تحديث يدوي لبقية الصفوف** — الترتيب يُعاد حسابه تلقائيًا في كل قراءة. العميل والصنايعي يشتركان (`subscribe`) في Realtime Channel على جدول `maintenance_requests` (فلتر `status`)، وعند أي `UPDATE`/`INSERT`/`DELETE` يُعاد جلب الـ View فيتحدث الترتيب فورًا في كل الأجهزة بدون Refresh يدوي.

### 5.2 دورة الحياة
1. عميل يرسل طلب (`rpc_create_maintenance_request`) → `status='waiting'`, `created_at=now()` → يدخل الـ Queue تلقائيًا بموضعه الزمني الصحيح.
2. Admin (أو Auto-assign لاحقًا) يسند لصنايعي → `rpc_assign_maintenance(request_id, technician_id)` → `status='assigned'`, `assigned_technician_id`, `assigned_at=now()` + سجل في `maintenance_status_history`.
   - **ملاحظة:** الطلب يبقى ظاهرًا في الـ Queue العام (لأن `status` لا يزال ضمن النشطة)، لكنه الآن مرتبط بصنايعي محدد.
3. الصنايعي يفتح الطلب ويضغط "بدء التنفيذ" → `rpc_start_maintenance(request_id)` → `status='in_progress'`, `started_at`.
4. عند "تم التنفيذ" → `rpc_complete_maintenance(request_id, notes?)`:
   - `status='completed'`, `completed_at=now()`, يسجل الصنايعي المنفِّذ (`assigned_technician_id` موجود مسبقًا).
   - يخرج تلقائيًا من `maintenance_queue_view` (شرط الـ WHERE أعلاه).
   - يُدرَج سجل `maintenance_status_history`.
   - Trigger يُنشئ `notifications` للعميل (type=`maintenance_completed`).
   - Realtime يدفع التحديث لكل من يشترك في القناة → يعاد حساب ترتيب الباقين تلقائيًا (لأن الـ View تُعاد حسابها لحظيًا، ليست بحاجة "تحديث ترتيب" منفصل — هذا يُبسّط التنفيذ فعليًا مقارنة بتحديث كل صف يدويًا).
5. الإلغاء: `rpc_cancel_maintenance(request_id, reason)` → `status='cancelled'`، يخرج من الـ Queue بنفس الآلية.

### 5.3 مثال حي (يطابق طلب المستخدم)
- Queue حاليًا: أحمد(1) محمد(2) محمود(3) علي(4).
- عند اكتمال أحمد → `status='completed'` → الـ View تلقائيًا: محمد(1) محمود(2) علي(3) — دون أي `UPDATE` إضافي على صفوفهم.
- شاشة العميل مشتركة realtime بـ:
  `supabase.channel('maintenance_queue').on('postgres_changes', {event:'*', table:'maintenance_requests'}, refetchMyPosition)`.

---

## 6. دورة المصروفات

`rpc_record_expense(category_id, amount, expense_date, notes, attachment_url)` — Admin فقط:
1. إدراج `expenses`.
2. إدراج `cash_transactions` (type=`expense`, amount **سالب**, reference=expenses.id).

---

## 7. دورة الجرد

1. `rpc_start_inventory_count(location_type, location_id, product_ids[]?)`:
   - ينشئ `inventory_counts` (status=`draft`).
   - ينشئ `inventory_count_items` لكل منتج بـ `system_quantity` = القيمة الحالية في `warehouse_stock`/`technician_bag_stock` وقت البدء (Snapshot لحظي حتى لو تغيّر المخزون أثناء الجرد بحركة أخرى — يُعرض تحذير عند الاعتماد إن حدث تعارض).
2. المستخدم يُدخل `actual_quantity` لكل صنف (يمكن حفظ مسودة تدريجيًا، `status` يبقى `draft`).
3. `rpc_complete_inventory_count(count_id)`:
   - لكل صف بفرق ≠ 0: **يُلزَم `reason`** (Constraint على مستوى الدالة، ترفض الاعتماد بدون سبب لأي فرق).
   - تُنشأ حركة `inventory_adjustment` واحدة لكل صنف بفرق (موجب = زيادة، سالب = نقص) تُحدِّث الرصيد الفعلي مباشرة (وليس عبر from/to عادي، بل حركة تسوية على نفس الموقع).
   - `status='completed'`, `completed_at=now()`.

---

## 8. حسابات العملاء

`customer_account_summary` (View):
```
total_purchases = SUM(order_charge amounts) -- من customer_account_transactions
total_paid      = SUM(payment amounts) + SUM(return_credit)  -- بالقيمة المطلقة
remaining       = total_purchases - total_paid
```
هذا هو "كشف الحساب الكامل" (Point 13)، ويُعرض تفصيليًا كسجل زمني لكل الحركات (order_charge / payment / return_credit / adjustment).

---

## 9. حسابات الصنايعية

`technician_account_summary` (View) يجمع:
- `bag_value` = SUM(technician_bag_stock.quantity * products.cost_price)
- `total_sales` = SUM(sales.total WHERE technician_id=...)
- `total_collected` = SUM(sales.paid_amount)
- `amount_due` = SUM(sale_credit) - SUM(supply_debit) *(من `technician_account_transactions`)*

يطابق تمامًا مثال المستخدم (محمد: بضاعة 15,000 / مبيعات 30,000 / تحصيل 25,000 / مطلوب توريد 5,000).

---

## 10. حساب الخزنة

```
balance = SUM(cash_transactions.amount) WHERE cashbox_id = X
```
لا استثناء، لا حقل يُعدَّل يدويًا. كل عملية (بيع مؤكَّد، توريد صنايعي، مصروف، مرتجع، تسوية) تمر عبر هذا الجدول فقط من خلال الـ RPC Functions أعلاه.

---

## 11. حساب الأرباح (تقرير الأرباح)

لفترة زمنية [من، إلى]:
```
Revenue          = SUM(order_items.line_total WHERE order confirmed/completed في الفترة)
                  + SUM(sale_items.line_total WHERE sale completed في الفترة)
COGS             = SUM(order_items.quantity * order_items.unit_cost_snapshot)
                  + SUM(sale_items.quantity * sale_items.unit_cost_snapshot)
Gross Profit     = Revenue - COGS
Expenses         = SUM(expenses.amount في الفترة)
Net Profit       = Gross Profit - Expenses
```
لاحظ استخدام `unit_cost_snapshot` المحفوظ وقت البيع/الطلب — **وليس** `products.cost_price` الحالي — تحقيقًا لمطلب دقة الربح التاريخي (البند 11 من طلب المستخدم).

---

## 12. منع Race Conditions — القاعدة العامة

كل RPC Function أعلاه تتبع النمط التالي إلزاميًا:

```sql
create or replace function rpc_example(...)
returns ... language plpgsql security definer as $$
begin
  -- 1) التحقق من الصلاحية يدويًا (auth.uid() + role) إن لزم تجاوز RLS
  -- 2) قفل الصفوف المتأثرة: SELECT ... FOR UPDATE
  -- 3) التحقق من الشرط (qty >= x) بعد القفل مباشرة
  -- 4) كل عمليات INSERT/UPDATE داخل نفس Transaction الضمنية للـ function
  -- 5) أي فشل → RAISE EXCEPTION يُلغي كل شيء تلقائيًا (atomicity من PL/pgSQL)
end;
$$;
```

هذا يضمن أن بيع "آخر قطعة" من عميلين متزامنين: الأول يحصل على القفل وينجح، الثاني ينتظر القفل، وعند تحريره يرى `quantity=0` فيفشل بخطأ واضح — لا مخزون سالب أبدًا (CHECK constraint كحارس أخير).
