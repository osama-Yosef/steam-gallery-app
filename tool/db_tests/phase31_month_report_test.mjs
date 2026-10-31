// tool/db_tests/phase31_month_report_test.mjs
//
// 0092: rpc_month_report — sales after discounts and returns, what they
// cost, expenses, purchases, supplier payments and debts, stock, profits.
//
//   cd tool/db_tests && npm install && node phase31_month_report_test.mjs

import { randomUUID } from 'node:crypto';
import { setup, uid, ADMIN, TECH, CUST_A } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err, mkUser, roleOf } = await setup(process.argv[2]);

const SALES = uid(9);
await mkUser(SALES, 'sales', '+201000000009', 'Sales');
roleOf[SALES] = 'sales';

const items = arr => JSON.stringify(arr);
const report = async month => {
  await as(ADMIN);
  return (await one(`select public.rpc_month_report($1) as r`, [month])).r;
};
const walkIn = async (qty, discount = 0) => {
  await as(ADMIN);
  return (await one(`select public.rpc_admin_walk_in_sale(null, null, $1, 'cash', $2, $3, null) as id`,
    [items([{ product_id: P, quantity: qty }]), discount, randomUUID()])).id;
};

await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T31', 'مكواة', 40, 100) returning id`)).id;
const CAT = (await one(`insert into public.expense_categories (name) values ('تصنيف الاختبار') returning id`)).id;
const EMP = (await one(`insert into public.employees (full_name, monthly_salary) values ('موظف', 100) returning id`)).id;
await q(`select public.rpc_cashbox_deposit(5000, 'رصيد', 'cash')`);

const now = await one(`select to_char((now() at time zone 'Africa/Cairo')::date, 'YYYY-MM-DD') as d,
                              to_char(date_trunc('month', (now() at time zone 'Africa/Cairo')::date), 'YYYY-MM-DD') as m`);
const MONTH = now.m;

// 20 × 40 = 800 from a supplier, 300 paid with it, 100 more afterwards.
await as(ADMIN);
await q(`select public.rpc_create_purchase_invoice(null, 'مورد', null, $1, 0, 300, 'cash', $2, null, null, $3)`,
  [items([{ product_id: P, quantity: 20, unit_cost: 40 }]), now.d, randomUUID()]);
await asSuper();
const SUP = (await one(`select id from public.suppliers where name = 'مورد'`)).id;
await as(ADMIN);
await q(`select public.rpc_pay_supplier($1, 100, 'cash', null, null, $2)`, [SUP, randomUUID()]);

await walkIn(2, 20);                 // 180, cost 80
const returned = await walkIn(2);    // 200 - a return of 1 = 100, cost 40
await asSuper();
const line = await one(`select id from public.sale_items where sale_id = $1`, [returned]);
await as(ADMIN);
await q(`select public.rpc_return_sale_item($1, 1, 'مرتجع')`, [line.id]);

// A technician: 100 sold, cost 40; a cancelled invoice doesn't count.
await as(ADMIN);
await q(`select public.rpc_issue_stock_to_technician($1, $2, null)`, [TECH, items([{ product_id: P, quantity: 3 }])]);
const sellBag = async () => {
  await as(TECH);
  return (await one(`select public.rpc_technician_sale($1, null, 'عميل', null, $2, 'cash', 0, 100, null, null, null) as id`,
    [TECH, items([{ product_id: P, quantity: 1 }])])).id;
};
await sellBag();
const cancelled = await sellBag();
await as(ADMIN);
await q(`select public.rpc_delete_technician_sale($1, 'غلط')`, [cancelled]);

// Online: a confirmed order counts (100 + 25 shipping, cost 40), a pending
// one doesn't.
await asSuper();
const cairo = (await one(`select id from public.cities where name_ar = 'القاهرة'`)).id;
await as(CUST_A);
const addr = (await one(`select public.rpc_save_my_address(
  p_address_id => null, p_city_id => $1, p_label => 'المنزل', p_address_line => 'addr',
  p_latitude => 30.0561, p_longitude => 31.3301) as r`, [cairo])).r.id;
const order = async () => {
  await as(CUST_A);
  return (await one(`select public.rpc_create_order($1, $2, $3, null, null) as id`,
    [CUST_A, items([{ product_id: P, quantity: 1 }]), addr])).id;
};
const confirmed = await order();
await order();
await as(ADMIN);
await q(`select public.rpc_admin_set_shipping_fee($1, 25)`, [confirmed]);
await as(CUST_A);
await q(`select public.rpc_customer_respond_shipping_fee($1, true)`, [confirmed]);
await as(ADMIN);
await q(`select public.rpc_confirm_order($1)`, [confirmed]);

// Expenses: 50 + a salary of 100; the 30 advance is not an expense.
await as(ADMIN);
await q(`select public.rpc_record_expense($1, 50, $2, 'إيجار', null, 'cash')`, [CAT, now.d]);
await as(ADMIN);
await q(`select public.rpc_employee_advance($1, 30, null, 'cash', null)`, [EMP]);
await as(ADMIN);
await q(`select public.rpc_pay_salary($1, $2, 0, 0, 30, 'cash', null)`, [EMP, MONTH]);

console.log('\n== the month ==');
{
  const r = await report(MONTH);
  const n = k => Number(r[k]);
  ok('sales are invoice totals after discounts and returns', n('sales') === 505, r.sales);
  ok('walk-in', n('sales_walk_in') === 280, r.sales_walk_in);
  ok('technicians', n('sales_technician') === 100, r.sales_technician);
  ok('online', n('sales_online') === 125, r.sales_online);
  ok('4 invoices', n('invoices') === 4, r.invoices);
  ok('cost of what stayed sold', n('cost') === 200, r.cost);
  ok('gross profit', n('gross_profit') === 305, r.gross_profit);
  ok('expenses: the salary earned, no advance', n('expenses') === 150, r.expenses);
  ok('by category', r.expense_categories.length === 2 && Number(r.expense_categories[0].total) === 100, JSON.stringify(r.expense_categories));
  ok('net profit', n('net_profit') === 155, r.net_profit);
  ok('purchases', n('purchases') === 800 && n('purchase_invoices') === 1, r.purchases);
  ok('supplier payments', n('supplier_payments') === 400, r.supplier_payments);
  ok('still owed', n('supplier_debt') === 400, r.supplier_debt);
  ok('per supplier', r.supplier_debts.length === 1 && r.supplier_debts[0].name === 'مورد', JSON.stringify(r.supplier_debts));
  ok('warehouse stock', n('stock_warehouse') === 520, r.stock_warehouse);
  ok('technicians\' bags', n('stock_bags') === 80, r.stock_bags);
}

console.log('\n== another month ==');
{
  const r = await report('2020-03-15');
  ok('any day picks its month', r.month === '2020-03-01', r.month);
  ok('its flows are empty', Number(r.sales) === 0 && Number(r.expenses) === 0 && Number(r.purchases) === 0 && Number(r.net_profit) === 0);
  ok('debts and stock are as of now', Number(r.supplier_debt) === 400 && Number(r.stock_warehouse) === 520);
}

console.log('\n== the Cairo calendar ==');
{
  const s = await walkIn(1);
  await asSuper();
  await q(`alter table public.sales disable trigger user`);
  await q(`update public.sales set created_at = '2026-01-31T22:30:00Z' where id = $1`, [s]); // 00:30, 1 Feb in Cairo
  await q(`alter table public.sales enable trigger user`);
  ok('counts in February', Number((await report('2026-02-01')).sales) === 100);
  ok('not in January', Number((await report('2026-01-01')).sales) === 0);
}

console.log('\n== who can read it ==');
{
  await as(SALES);
  ok('sales: forbidden', /FORBIDDEN/.test(await err(`select public.rpc_month_report(null)`) ?? ''));
  await as(TECH);
  ok('technician: forbidden', /FORBIDDEN/.test(await err(`select public.rpc_month_report(null)`) ?? ''));
  await as(null);
  ok('anon: no access', !!(await err(`select public.rpc_month_report(null)`)));
}

finish();
