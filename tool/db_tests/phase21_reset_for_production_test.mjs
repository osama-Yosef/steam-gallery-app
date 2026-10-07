// tool/db_tests/phase21_reset_for_production_test.mjs
//
// supabase/scripts/reset_for_production.sql: after a trial period full of
// sales, purchases, expenses and requests, the script leaves every ledger,
// the stock and the catalogue empty, both tills at 0, every number starting
// again at 1 — and every account, the cities, the tills, the warehouse and
// the app settings untouched.
//
//   cd tool/db_tests && npm install && node phase21_reset_for_production_test.mjs

import { randomUUID } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { setup, ADMIN, TECH, CUST_A } from './harness.mjs';

const { db, ok, finish, as, asSuper, q, one } = await setup(process.argv[2]);
const root = process.argv[2] ?? path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const script = fs.readFileSync(path.join(root, 'supabase', 'scripts', 'reset_for_production.sql'), 'utf8');

const count = async (table) => Number((await one(`select count(*)::int as n from ${table}`)).n);
const tillTotal = async () =>
  Number((await one(`select coalesce(sum(balance), 0)::numeric as b from public.cashbox_balances`)).b);

// ---------------------------------------------------------------- trial data
console.log('\n== A trial period ==');
await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('R1', 'مكواة', 40, 100) returning id`)).id;
await q(`select public.rpc_create_purchase_invoice(null, 'مورد', null, $1, 0, 0, null, null, null, null, $2)`,
  [JSON.stringify([{ product_id: P, quantity: 10, unit_cost: 40 }]), randomUUID()]);
for (let i = 0; i < 3; i++) {
  await q(`select public.rpc_admin_walk_in_sale(null, null, $1, 'cash', 0, $2, null)`,
    [JSON.stringify([{ product_id: P, quantity: 1 }]), randomUUID()]);
}
const cat = (await one(`select id from public.expense_categories order by name limit 1`)).id;
await q(`select public.rpc_record_expense($1, 50, current_date, 'فاتورة', null)`, [cat]);

await asSuper();
const city = (await one(`select id from public.cities limit 1`))?.id
  ?? (await one(`insert into public.cities (country_id, name_ar) select id, 'القاهرة' from public.countries limit 1 returning id`)).id;
const area = (await one(`insert into public.service_areas (city_id, name_ar, center_latitude, center_longitude, radius_km)
  values ($1, 'منطقة التجربة', 30.05, 31.33, 5) returning id`, [city])).id;
await q(`insert into public.customer_addresses (customer_id, city_id, service_area_id, label, address_line, latitude, longitude)
  values ($1, $2, $3, 'البيت', 'شارع', 30.05, 31.33)`, [CUST_A, city, area]);
await q(`insert into public.wallets (customer_id, balance) values ($1, 150)
  on conflict (customer_id, currency) do update set balance = 150`, [CUST_A]);
await q(`insert into public.maintenance_requests (customer_id, customer_name, phone, problem_description)
  values ($1, 'أ', '01012345678', 'عطل')`, [CUST_A]);
await q(`insert into public.notifications (user_id, type, title) values ($1, 'test', 'x')`, [ADMIN]);

const before = {
  users: await count('public.users'),
  technicians: await count('public.technicians'),
  cities: await count('public.cities'),
  cashboxes: await count('public.cashboxes'),
  warehouses: await count('public.warehouses'),
  bags: await count('public.technician_bags'),
  settings: await count('private.app_settings'),
  addresses: await count('public.customer_addresses'),
};
ok('trial data is there', (await count('public.sales')) === 3 && (await count('public.expenses')) === 1
  && (await count('public.stock_movements')) > 0 && (await count('public.audit_logs')) > 0
  && (await tillTotal()) !== 0);

// ---------------------------------------------------------------- reset
console.log('\n== Running the reset script ==');
await asSuper();
await db.exec(script);

for (const t of ['sales', 'sale_items', 'orders', 'order_items', 'payments', 'maintenance_requests',
  'cash_transactions', 'expenses', 'purchase_invoices', 'purchase_invoice_items', 'supplier_payments',
  'suppliers', 'stock_movements', 'warehouse_stock', 'technician_bag_stock', 'inventory_counts',
  'products', 'product_categories', 'offers', 'home_banners', 'service_areas', 'notifications',
  'audit_logs', 'wallet_transactions', 'customer_account_transactions', 'technician_account_transactions',
  'technician_supplies', 'cart_items']) {
  ok(`${t} is empty`, (await count(`public.${t}`)) === 0);
}
ok('both tills read 0', (await tillTotal()) === 0);
ok('wallets are back to 0',
  Number((await one(`select coalesce(sum(balance), 0)::numeric as b from public.wallets`)).b) === 0);
ok('the seven standard expense categories are back', (await count('public.expense_categories')) === 7);

ok('every account kept', (await count('public.users')) === before.users);
ok('technicians kept', (await count('public.technicians')) === before.technicians);
ok('cities kept', (await count('public.cities')) === before.cities);
ok('tills and warehouse kept', (await count('public.cashboxes')) === before.cashboxes
  && (await count('public.warehouses')) === before.warehouses);
ok("technicians' bags kept (empty)", (await count('public.technician_bags')) === before.bags);
ok('app settings kept', (await count('private.app_settings')) === before.settings);
ok('saved addresses kept, area cleared', (await count('public.customer_addresses')) === before.addresses
  && (await count('public.customer_addresses where service_area_id is not null')) === 0);

// ---------------------------------------------------------------- live again
console.log('\n== First day live: every number starts at 1 ==');
await as(ADMIN);
const P2 = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('L1', 'فلتر', 10, 30) returning id`)).id;
await q(`select public.rpc_create_purchase_invoice(null, 'مورد جديد', null, $1, 0, 0, null, null, null, null, $2)`,
  [JSON.stringify([{ product_id: P2, quantity: 5, unit_cost: 10 }]), randomUUID()]);
await q(`select public.rpc_admin_walk_in_sale(null, null, $1, 'cash', 0, $2, null)`,
  [JSON.stringify([{ product_id: P2, quantity: 1 }]), randomUUID()]);
const cat2 = (await one(`select id from public.expense_categories limit 1`)).id;
await q(`select public.rpc_record_expense($1, 20, current_date, null, null)`, [cat2]);
await asSuper();
await q(`insert into public.maintenance_requests (customer_id, customer_name, phone, problem_description)
  values ($1, 'أ', '01012345678', 'عطل')`, [CUST_A]);

ok('first sale is #1', Number((await one(`select sale_number from public.sales`)).sale_number) === 1);
ok('first purchase invoice is #1', Number((await one(`select invoice_number from public.purchase_invoices`)).invoice_number) === 1);
ok('first expense is #1', Number((await one(`select expense_number from public.expenses`)).expense_number) === 1);
ok('first maintenance ticket is #1', Number((await one(`select ticket_number from public.maintenance_requests`)).ticket_number) === 1);
ok('first stock movement is #1', Number((await one(`select min(movement_number) as n from public.stock_movements`)).n) === 1);
ok('the till holds only today\'s money', (await tillTotal()) === 30 - 20, String(await tillTotal()));
ok('stock is only what came in today', Number((await one(`select quantity from public.warehouse_stock where product_id = $1`, [P2])).quantity) === 4);

void TECH;
finish();
