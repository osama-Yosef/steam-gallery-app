# المرحلة 6 — خريطة الشاشات (Screen Map) والتنقل

## 1. عام (كل الأدوار)

```
/splash        -> يقرر الوجهة حسب الجلسة + role
/login
/register      (عميل فقط — Self Sign-up)
```

---

## 2. تطبيق العميل — `/customer/*` (Bottom Nav: الرئيسية، الصيانة، الطلبات، حسابي)

```
/customer/home
  - بانر/أقسام، منتجات جديدة، بحث سريع
/customer/search?q=
/customer/category/:id
/customer/product/:id
  -> زر: أضف للسلة | اشترِ الآن
/customer/cart
  -> زر: تأكيد الطلب -> /customer/checkout
/customer/checkout
  - عنوان التوصيل + تحديد Location + ملاحظات -> تأكيد -> rpc_create_order
  -> /customer/orders/:id (نجاح)
/customer/orders                 (قائمة طلباتي)
/customer/orders/:id             (تفاصيل + Realtime لحالة الطلب)

/customer/maintenance
  - إن وجد طلب نشط: بطاقة "رقم دورك: 7 — يوجد قبلك 3 عملاء" (Realtime)
  - زر: طلب صيانة جديد -> /customer/maintenance/new
/customer/maintenance/new
  - نموذج: الاسم، الهاتف، العنوان + زر تحديد الموقع (GPS)، نوع الجهاز،
    وصف المشكلة، صور (اختياري)، ملاحظات -> إرسال -> rpc_create_maintenance_request
  -> /customer/maintenance/:id (نجاح، يعرض رقم الدور)
/customer/maintenance/:id        (تفاصيل + حالة + الدور Realtime)
/customer/maintenance/history    (طلبات سابقة)

/customer/account
  - بيانات البروفايل
  -> /customer/account/statement  (كشف حساب: مشتريات/مدفوع/متبقي)
  -> /customer/account/edit-profile
  -> /customer/notifications
  -> تسجيل خروج
```

---

## 3. تطبيق الصنايعي — `/technician/*` (Bottom Nav: الصيانة، شنطتي، حسابي)

```
/technician/maintenance
  - قائمة مرتبة بالدور (كل الـ waiting + المسندة له) — Realtime
  -> فلتر: الكل / المسندة لي / قيد التنفيذ
/technician/maintenance/:id
  - كل التفاصيل + زر "فتح الموقع" (url_launcher -> Google Maps)
  - أزرار حسب الحالة: بدء التنفيذ -> rpc_start_maintenance
                       تم التنفيذ -> rpc_complete_maintenance (+ملاحظات)
                       إلغاء -> rpc_cancel_maintenance

/technician/bag
  - جدول: المنتج / الكمية المتاحة في الشنطة / قيمتها
  -> زر: بيع -> /technician/bag/sell
/technician/bag/sell
  - اختيار منتجات من الشنطة (مع تحقق فوري من الكمية المتاحة)
  - عميل (اختياري: بحث عن عميل مسجل أو اسم/هاتف حر)
  - طريقة الدفع، خصم، المبلغ المدفوع -> تنفيذ -> rpc_technician_sale
  -> /technician/bag/sales/:id  (إيصال البيع)
/technician/bag/sales            (سجل مبيعاتي)

/technician/account
  - ملخص: قيمة البضاعة، إجمالي المبيعات، التحصيل، المطلوب توريده
  -> /technician/account/supply   (تسجيل توريد -> rpc_technician_supply)
  -> /technician/account/history  (كل الحركات بالتفصيل)
  -> /technician/notifications
  -> تسجيل خروج
```

---

## 4. تطبيق الأدمن — `/admin/*` (Navigation Rail/Drawer لاتساع الشاشة)

```
/admin/dashboard
  - بطاقات: رصيد الخزنة، مبيعات اليوم/الشهر، صافي الربح، عدد الصيانة،
    طلبات جديدة، منتجات منخفضة، ديون العملاء، مستحقات الصنايعية
  - Charts: مبيعات آخر 7/30 يوم

/admin/products                  (قائمة + بحث + فلتر قسم)
/admin/products/new | /:id/edit
/admin/categories

/admin/inventory
  - المخزن الرئيسي: كميات + قيمة + منخفض المخزون
  -> /admin/inventory/movements   (سجل كل الحركات، فلاتر متعددة)
  -> /admin/inventory/receive     (استلام بضاعة جديدة -> rpc_receive_purchase)
  -> /admin/inventory/issue       (صرف لصنايعي -> rpc_issue_stock_to_technician)
  -> /admin/inventory/count/new   (بدء جرد -> rpc_start_inventory_count)
  -> /admin/inventory/count/:id   (إدخال الكميات الفعلية -> rpc_save_inventory_count_item
                                    -> اعتماد -> rpc_complete_inventory_count)

/admin/orders                    (كل الطلبات + فلتر حالة/بحث)
/admin/orders/:id
  - تفاصيل + أزرار: تأكيد (rpc_confirm_order) / تحديث حالة / تسجيل دفعة /
    إلغاء / استرجاع

/admin/maintenance
  - القائمة الكاملة مرتبة بالدور + فلاتر (الحالة/الصنايعي)
/admin/maintenance/:id
  - تفاصيل + إسناد لصنايعي (rpc_assign_maintenance) + متابعة الحالة

/admin/technicians                (قائمة الصنايعية)
/admin/technicians/new             (-> Edge Function create-user)
/admin/technicians/:id
  -> نظرة عامة (بضاعة/مبيعات/تحصيل/مطلوب)
  -> /admin/technicians/:id/bag     (محتوى الشنطة)
  -> /admin/technicians/:id/history (كل الحركات)
  -> تعديل / تفعيل / إيقاف

/admin/customers                   (قائمة + بحث)
/admin/customers/:id
  -> كشف حساب كامل (طلبات/مدفوعات/مرتجعات/صيانة)
  -> تسجيل دفعة يدوية (rpc_record_customer_payment)

/admin/cashbox
  - الرصيد الحالي (محسوب) + كل الحركات المالية + فلاتر
/admin/expenses
  - قائمة + تسجيل مصروف جديد (rpc_record_expense) + تصنيفات

/admin/reports
  -> مبيعات | أرباح | مصروفات | مخزن | صنايعية | عملاء
  - فلتر فترة (من/إلى) لكل تقرير + Export PDF/Excel

/admin/audit-log                    (قراءة فقط، فلاتر: مستخدم/جدول/تاريخ)

/admin/users
  - كل المستخدمين (Admin/Technician/Customer) + تغيير الدور (rpc_admin_set_role)
    + تفعيل/إيقاف (rpc_admin_set_active)

/admin/notifications
/admin/settings                      (بيانات المعرض، الأقسام، إلخ)
```

---

## 5. Navigation Flow — أمثلة حرجة

**تدفق الصيانة الكامل (3 شاشات، 3 أدوار):**
```
عميل: /customer/maintenance/new → إرسال → /customer/maintenance/:id (دور: 7)
أدمن: /admin/maintenance/:id → إسناد لمحمد
صنايعي محمد: /technician/maintenance (يرى الطلب) → /technician/maintenance/:id
             → بدء التنفيذ → تم التنفيذ
عميل: (Realtime) الشاشة تتحدث تلقائيًا -> "تم الانتهاء من صيانتك" + إشعار
```

**تدفق بيع الصنايعي:**
```
صنايعي: /technician/bag → بيع → /technician/bag/sell → تنفيذ
         → إيصال + تحديث فوري لكمية الشنطة (Realtime)
أدمن: /admin/technicians/:id (يرى المبيعة الجديدة في نفس اللحظة تقريبًا عبر Polling/Realtime)
```
