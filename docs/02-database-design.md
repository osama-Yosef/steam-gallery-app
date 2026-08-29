# المرحلة 2 — تصميم قاعدة البيانات (PostgreSQL / Supabase)

كل الجداول أدناه منفَّذة فعليًا في `supabase/migrations/`. هذا المستند هو المرجع المنطقي (ERD + شرح) — راجع ملفات SQL للتنفيذ الدقيق (Types, Defaults, Constraints).

---

## 1. ERD منطقي (نصي)

```
auth.users (Supabase) ──1:1── users ──1:1── customers
                                  ├──1:1── technicians ──1:1── technician_bags ──1:N── technician_bag_stock ──N:1── products
                                  └── (role = admin: لا جدول امتداد)

product_categories (self-ref parent_id) ──1:N── products ──1:N── product_images
products ──1:N── warehouse_stock ──N:1── warehouses
products ──1:N── stock_movements

customers ──1:N── orders ──1:N── order_items ──N:1── products
customers ──1:N── maintenance_requests ──1:N── maintenance_images
maintenance_requests ──1:N── maintenance_status_history
maintenance_requests ──N:1── technicians (assigned_technician_id)

technicians ──1:N── sales ──1:N── sale_items ──N:1── products
technicians ──1:N── technician_supplies
technicians ──1:1── technician_accounts ──1:N── technician_account_transactions

customers ──1:1── customer_accounts ──1:N── customer_account_transactions

cashboxes ──1:N── cash_transactions

expense_categories ──1:N── expenses

warehouses|technician_bags ──1:N── inventory_counts ──1:N── inventory_count_items ──N:1── products

users ──1:N── notifications
users ──1:N── audit_logs (actor)
```

---

## 2. الجداول بالتفصيل

### 2.1 `users` (امتداد `auth.users`)
> كل مستخدم في auth.users له صف مطابق هنا (يُنشأ تلقائيًا بـ Trigger عند Signup).

| العمود | النوع | ملاحظات |
|---|---|---|
| id | uuid PK | = auth.users.id |
| role | user_role (enum) | admin / technician / customer — **يُضبط فقط عبر Function خاصة، ليس UPDATE مباشر** |
| full_name | text NOT NULL | |
| phone | text UNIQUE | |
| email | text | Mirror من auth.users للعرض السريع |
| avatar_url | text | Storage path |
| is_active | boolean DEFAULT true | تعطيل الحساب دون حذف |
| created_at, updated_at | timestamptz | |

**لماذا:** فصل بيانات البروفايل عن `auth.users` (لا يمكن إضافة أعمدة لجدول auth مباشرة)، ويحمل `role` الذي تعتمد عليه كل سياسات RLS.

### 2.2 `customers` (امتداد لـ users حيث role=customer)
| العمود | النوع |
|---|---|
| id | uuid PK == users.id |
| default_address | text |
| default_latitude / default_longitude | numeric |
| notes | text (ملاحظات إدارية داخلية) |
| created_at | timestamptz |

### 2.3 `technicians`
| العمود | النوع |
|---|---|
| id | uuid PK == users.id |
| employee_code | text UNIQUE |
| hire_date | date |
| is_active | boolean DEFAULT true |
| created_by | uuid FK users (الأدمن الذي أنشأه) |
| created_at | timestamptz |

### 2.4 `product_categories`
| العمود | النوع |
|---|---|
| id | uuid PK |
| parent_id | uuid FK self NULL |
| name | text NOT NULL |
| image_url | text |
| sort_order | int DEFAULT 0 |
| is_active | boolean DEFAULT true |

### 2.5 `products`
| العمود | النوع | ملاحظات |
|---|---|---|
| id | uuid PK | |
| sku | text UNIQUE NOT NULL | |
| barcode | text UNIQUE NULL | |
| category_id | uuid FK product_categories | |
| name | text NOT NULL | |
| description | text | |
| specs | jsonb DEFAULT '{}' | مواصفات ديناميكية (لون/سعة/موديل...) |
| cost_price | numeric(12,2) NOT NULL CHECK ≥ 0 | السعر **الحالي** فقط — التاريخي في الحركات |
| selling_price | numeric(12,2) NOT NULL CHECK ≥ 0 | |
| min_stock | int DEFAULT 0 | لتنبيه المخزون المنخفض |
| is_active | boolean DEFAULT true | |
| created_by | uuid FK users | |
| created_at, updated_at | timestamptz | |

### 2.6 `product_images`
| العمود | النوع |
|---|---|
| id | uuid PK |
| product_id | uuid FK products ON DELETE CASCADE |
| image_url | text NOT NULL |
| sort_order | int DEFAULT 0 |
| is_primary | boolean DEFAULT false |

### 2.7 `warehouses`
| العمود | النوع | ملاحظات |
|---|---|---|
| id | uuid PK |
| name | text | مثال: "المخزن الرئيسي" |
| type | warehouse_type enum('main') | قابل للتوسع لاحقًا لأكثر من فرع |
| is_active | boolean DEFAULT true |

### 2.8 `warehouse_stock`
| العمود | النوع |
|---|---|
| id | uuid PK |
| warehouse_id | uuid FK warehouses |
| product_id | uuid FK products |
| quantity | int NOT NULL DEFAULT 0 CHECK ≥ 0 |
| UNIQUE(warehouse_id, product_id) | |

### 2.9 `technician_bags`
| العمود | النوع |
|---|---|
| id | uuid PK |
| technician_id | uuid FK technicians UNIQUE |
| created_at | timestamptz |

### 2.10 `technician_bag_stock`
| العمود | النوع |
|---|---|
| id | uuid PK |
| technician_bag_id | uuid FK technician_bags |
| product_id | uuid FK products |
| quantity | int NOT NULL DEFAULT 0 CHECK ≥ 0 |
| UNIQUE(technician_bag_id, product_id) | |

### 2.11 `stock_movements` — **Ledger المخزون (Immutable)**
| العمود | النوع | ملاحظات |
|---|---|---|
| id | uuid PK |
| movement_number | bigserial UNIQUE | رقم تسلسلي بشري |
| product_id | uuid FK products |
| movement_type | stock_movement_type enum | purchase, sale, issue_to_technician, technician_sale, return_from_customer, return_to_supplier, damage, inventory_adjustment, transfer |
| quantity | int NOT NULL CHECK > 0 | القيمة دائمًا موجبة، الاتجاه من from/to |
| from_location_type | location_type enum NULL | warehouse / technician_bag / external |
| from_location_id | uuid NULL | |
| to_location_type | location_type enum NULL | |
| to_location_id | uuid NULL | |
| unit_cost | numeric(12,2) NOT NULL | Snapshot سعر التكلفة وقت الحركة |
| total_cost | numeric(12,2) GENERATED ALWAYS AS (quantity * unit_cost) STORED | |
| reference_type | text NULL | 'sale','order','inventory_count',... |
| reference_id | uuid NULL | |
| notes | text | |
| created_by | uuid FK users | |
| created_at | timestamptz DEFAULT now() | |

**لماذا Ledger واحد:** بدلاً من تعديل `quantity` في `warehouse_stock`/`technician_bag_stock` مباشرة من كل شاشة، كل تغيير **يجب** أن يمر عبر `stock_movements` (بواسطة RPC Function)، والـ Trigger على هذا الجدول هو من يُحدّث الأرصدة. هذا يضمن أن كل تغيير مخزون قابل للمراجعة الكاملة (Point 9 من متطلبات المستخدم).

### 2.12 `orders`
| العمود | النوع |
|---|---|
| id | uuid PK |
| order_number | bigserial UNIQUE |
| customer_id | uuid FK customers |
| status | order_status enum | pending, confirmed, preparing, delivered, completed, cancelled, returned |
| subtotal | numeric(12,2) | |
| discount | numeric(12,2) DEFAULT 0 | |
| total | numeric(12,2) GENERATED (subtotal - discount) STORED | |
| paid_amount | numeric(12,2) DEFAULT 0 | |
| delivery_address | text | |
| delivery_latitude/longitude | numeric NULL | |
| notes | text | |
| confirmed_by | uuid FK users NULL | |
| cancelled_reason | text NULL | |
| client_request_id | uuid UNIQUE NULL | Idempotency |
| created_at, updated_at | timestamptz | |

### 2.13 `order_items`
| العمود | النوع |
|---|---|
| id | uuid PK |
| order_id | uuid FK orders ON DELETE CASCADE |
| product_id | uuid FK products |
| product_name_snapshot | text | حماية من تغيّر اسم المنتج مستقبلًا |
| quantity | int CHECK > 0 |
| unit_price_snapshot | numeric(12,2) | سعر البيع وقت الطلب |
| unit_cost_snapshot | numeric(12,2) | سعر التكلفة وقت الطلب (للربح) |
| discount | numeric(12,2) DEFAULT 0 |
| line_total | numeric GENERATED (quantity*unit_price_snapshot - discount) STORED |

### 2.14 `maintenance_requests`
| العمود | النوع |
|---|---|
| id | uuid PK |
| ticket_number | bigserial UNIQUE | رقم الدور المعروض للعميل |
| customer_id | uuid FK customers |
| customer_name, phone | text (Snapshot، حتى لو تغيّر بروفايل العميل) |
| address | text |
| latitude, longitude | numeric NULL |
| device_type | text |
| problem_description | text NOT NULL |
| notes | text |
| status | maintenance_status enum | waiting, assigned, in_progress, completed, cancelled |
| assigned_technician_id | uuid FK technicians NULL |
| created_at | timestamptz DEFAULT now() | **أساس ترتيب الـ Queue** |
| assigned_at, started_at, completed_at, cancelled_at | timestamptz NULL |
| cancelled_reason | text NULL |

### 2.15 `maintenance_images`
| العمود | النوع |
|---|---|
| id | uuid PK |
| maintenance_request_id | uuid FK ON DELETE CASCADE |
| image_url | text |
| uploaded_at | timestamptz |

### 2.16 `maintenance_status_history`
| العمود | النوع |
|---|---|
| id | uuid PK |
| maintenance_request_id | uuid FK |
| old_status, new_status | maintenance_status |
| changed_by | uuid FK users |
| notes | text |
| changed_at | timestamptz DEFAULT now() |

### 2.17 `sales` (مبيعات الصنايعي من شنطته)
| العمود | النوع |
|---|---|
| id | uuid PK |
| sale_number | bigserial UNIQUE |
| technician_id | uuid FK technicians |
| customer_id | uuid FK customers NULL | اختياري (قد يكون عميل غير مسجل) |
| customer_name, customer_phone | text | Snapshot/عميل غير مسجل |
| payment_method | payment_method enum | cash, card, transfer, deferred |
| subtotal, discount | numeric(12,2) |
| total | numeric GENERATED STORED |
| paid_amount | numeric(12,2) DEFAULT 0 |
| status | sale_status enum | completed, returned, cancelled |
| client_request_id | uuid UNIQUE NULL | Idempotency |
| created_at | timestamptz |

### 2.18 `sale_items`
مطابق لـ `order_items` لكن مرتبط بـ `sales`.

### 2.19 `technician_accounts`
| العمود | النوع |
|---|---|
| id | uuid PK == technicians.id |
| created_at | timestamptz |

> جدول Anchor خفيف — الرصيد الفعلي محسوب من `technician_account_transactions` عبر View، وليس مخزَّنًا هنا (تفاديًا لعدم الاتساق).

### 2.20 `technician_account_transactions` — Ledger
| العمود | النوع |
|---|---|
| id | uuid PK |
| technician_id | uuid FK technicians |
| transaction_type | tech_txn_type enum | sale_credit (مديونية عليه من بيع نقدي), supply_debit (توريد يقلل المديونية), adjustment |
| amount | numeric(12,2) NOT NULL | موجب دائمًا؛ الاتجاه من `transaction_type` |
| sale_id | uuid FK sales NULL |
| supply_id | uuid FK technician_supplies NULL |
| notes | text |
| created_by | uuid FK users |
| created_at | timestamptz |

### 2.21 `technician_supplies` (توريد الصنايعي)
| العمود | النوع |
|---|---|
| id | uuid PK |
| supply_number | bigserial UNIQUE |
| technician_id | uuid FK technicians |
| amount | numeric(12,2) CHECK > 0 |
| notes | text |
| recorded_by | uuid FK users |
| created_at | timestamptz |

### 2.22 `cashboxes`
| العمود | النوع |
|---|---|
| id | uuid PK |
| name | text | "خزنة المعرض الرئيسية" (صف افتراضي واحد Seed) |
| is_active | boolean DEFAULT true |

### 2.23 `cash_transactions` — **Ledger المالي (Immutable, مصدر الحقيقة الوحيد للرصيد)**
| العمود | النوع | ملاحظات |
|---|---|---|
| id | uuid PK |
| cashbox_id | uuid FK cashboxes |
| transaction_type | cash_txn_type enum | sale, technician_deposit, expense, refund, adjustment, purchase, other_income, other_expense |
| amount | numeric(12,2) NOT NULL | **موجب = دخل، سالب = مصروف** (مُلزَم عبر Trigger/Function وليس إدخال حر) |
| reference_type | text NULL | 'order','sale','expense','technician_supply',... |
| reference_id | uuid NULL |
| notes | text |
| created_by | uuid FK users |
| created_at | timestamptz DEFAULT now() |

### 2.24 `customer_accounts`
| العمود | النوع |
|---|---|
| id | uuid PK == customers.id |
| created_at | timestamptz |

### 2.25 `customer_account_transactions` — Ledger
| العمود | النوع |
|---|---|
| id | uuid PK |
| customer_id | uuid FK customers |
| transaction_type | cust_txn_type enum | order_charge, payment, return_credit, adjustment |
| amount | numeric(12,2) NOT NULL | موجب = زيادة مديونية العميل، سالب = تخفيضها (دفع) |
| order_id | uuid FK orders NULL |
| notes | text |
| created_by | uuid FK users |
| created_at | timestamptz |

### 2.26 `expense_categories`
| العمود | النوع |
|---|---|
| id | uuid PK |
| name | text UNIQUE | كهرباء، إيجار، نقل، مرتبات... |
| is_active | boolean DEFAULT true |

### 2.27 `expenses`
| العمود | النوع |
|---|---|
| id | uuid PK |
| expense_number | bigserial UNIQUE |
| category_id | uuid FK expense_categories |
| amount | numeric(12,2) CHECK > 0 |
| expense_date | date NOT NULL |
| notes | text |
| attachment_url | text NULL |
| created_by | uuid FK users |
| created_at | timestamptz |

### 2.28 `inventory_counts`
| العمود | النوع |
|---|---|
| id | uuid PK |
| count_number | bigserial UNIQUE |
| location_type | location_type enum | warehouse / technician_bag |
| location_id | uuid NOT NULL |
| status | inventory_count_status enum | draft, completed |
| started_by | uuid FK users |
| started_at | timestamptz |
| completed_at | timestamptz NULL |
| notes | text |

### 2.29 `inventory_count_items`
| العمود | النوع |
|---|---|
| id | uuid PK |
| inventory_count_id | uuid FK ON DELETE CASCADE |
| product_id | uuid FK products |
| system_quantity | int NOT NULL | الكمية حسب النظام وقت بدء الجرد |
| actual_quantity | int NULL | تُملأ أثناء الجرد |
| difference | int GENERATED (actual_quantity - system_quantity) STORED |
| reason | text NULL | إلزامي إذا difference ≠ 0 (Constraint) |
| notes | text |

### 2.30 `notifications`
| العمود | النوع |
|---|---|
| id | uuid PK |
| user_id | uuid FK users |
| type | text | order_status, maintenance_queue, low_stock, maintenance_new,... |
| title | text |
| body | text |
| data | jsonb DEFAULT '{}' | (order_id, maintenance_id,...) |
| is_read | boolean DEFAULT false |
| created_at | timestamptz |

### 2.31 `audit_logs` — Immutable, Admin-only read
| العمود | النوع |
|---|---|
| id | uuid PK |
| actor_id | uuid FK users NULL |
| action | text | INSERT/UPDATE/DELETE أو اسم عملية منطقية |
| table_name | text |
| record_id | uuid NULL |
| old_data | jsonb NULL |
| new_data | jsonb NULL |
| ip_address | text NULL |
| device_info | text NULL |
| created_at | timestamptz DEFAULT now() |

---

## 3. Indexes الأساسية

- `products(category_id)`, `products(sku)`, `products(barcode)`, `products(name) USING gin (to_tsvector('arabic', name))` *(أو `simple` إن لم يتوفر قاموس عربي)* للبحث النصي.
- `stock_movements(product_id, created_at DESC)`, `stock_movements(reference_type, reference_id)`.
- `orders(customer_id, status, created_at DESC)`.
- `maintenance_requests(status, created_at)` — Partial index على `status IN ('waiting','assigned','in_progress')` لتسريع الـ Queue.
- `sales(technician_id, created_at DESC)`.
- `cash_transactions(cashbox_id, created_at DESC)`, `cash_transactions(reference_type, reference_id)`.
- `customer_account_transactions(customer_id, created_at DESC)`.
- `technician_account_transactions(technician_id, created_at DESC)`.
- `notifications(user_id, is_read, created_at DESC)`.
- `audit_logs(table_name, record_id)`, `audit_logs(actor_id, created_at DESC)`.

كل هذه منفذة في `supabase/migrations/0008_indexes.sql`.

---

## 4. Views الأساسية (تفصيل كامل في `0009_views.sql`)

| View | الغرض |
|---|---|
| `cashbox_balances` | رصيد كل خزنة = SUM(cash_transactions.amount) |
| `customer_account_summary` | إجمالي مشتريات/مدفوع/متبقي لكل عميل |
| `technician_account_summary` | قيمة بضاعة الشنطة + مبيعات + توريد + متبقي لكل صنايعي |
| `technician_bag_value` | قيمة بضاعة كل شنطة بسعر التكلفة الحالي |
| `warehouse_stock_value` | قيمة المخزون الحالي بالمخزن الرئيسي |
| `low_stock_products` | منتجات تحت `min_stock` |
| `maintenance_queue_view` | حساب `queue_position` الحيّ عبر `ROW_NUMBER()` لكل الطلبات النشطة |
| `daily_sales_summary` / `monthly_sales_summary` | لتغذية الـ Dashboard والتقارير |

---

## 5. لماذا هذا التصميم (ملخص القرارات)

1. **جدول Ledger لكل رصيد** (مخزون/خزنة/عميل/صنايعي) بدل حقل رقمي يُعدَّل مباشرة → يحقق NFR-2 وNFR-10 (قابلية المراجعة والتدقيق الكاملة، مطلب صريح من المستخدم في القسم 32).
2. **Snapshot للأسعار** في كل من `order_items`, `sale_items`, `stock_movements.unit_cost` → يحقق مطلب "لا تتغير الطلبات القديمة عند تغيّر السعر" وحساب ربح دقيق تاريخيًا.
3. **فصل `technician_bag_stock` عن `warehouse_stock`** لكن توحيدهما تحت نفس `stock_movements` الملزم بـ `location_type` polymorphic → يمنع تكرار منطق الحركة، ويسمح بالتوسع لمخازن فرعية أخرى مستقبلًا (فروع إضافية) دون تعديل بنيوي.
4. **`bigserial` لأرقام العرض البشرية** (order_number, ticket_number, sale_number...) مع `uuid` كـ PK حقيقي → يجمع بين سهولة العرض للمستخدم النهائي وأمان/توزيع الـ UUID.
5. **لا `DELETE`** مسموح على أي جدول Ledger → يُفرض عبر عدم منح صلاحية DELETE في RLS، والتصحيح دائمًا بقيد جديد (Reversal).
6. **`client_request_id` Idempotency** على العمليات المالية/المخزنية الحساسة (طلبات، مبيعات) → يحقق NFR-11 لمعالجة انقطاع الشبكة أثناء عملية بيع.
