// tool/db_tests/phase23_sales_back_office_test.mjs
//
// 0083: the sales role runs the back office like admin — warehouse,
// purchase invoices and suppliers, products, employees, customers and
// wallets, plus everything its dashboard reads — while users/roles,
// settings, the audit log and expense categories stay admin-only, and a
// technician or customer gains nothing.
//
//   cd tool/db_tests && npm install && node phase23_sales_back_office_test.mjs

import { randomUUID } from 'node:crypto';
import { setup, uid, ADMIN, TECH, CUST_A } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err, mkUser, roleOf } = await setup(process.argv[2]);

const SALES = uid(9);
await mkUser(SALES, 'sales', '+201000000009', 'Sales');
roleOf[SALES] = 'sales';

const forbidden = e => /FORBIDDEN/.test(e ?? '');
const items = arr => JSON.stringify(arr);

console.log('\n== Seed (admin) ==');
await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price, min_stock)
  values ('S23', 'مكواة بخار', 100, 250, 50) returning id`)).id;
await q(`select public.rpc_admin_opening_stock($1, null)`, [items([{ product_id: P, quantity: 5, unit_cost: 100 }])]);
await q(`select public.rpc_cashbox_deposit(5000, 'عهدة', 'main')`);
ok('seeded a low-stock product and cash in the main safe', true);

console.log('\n== Sales reads the back office ==');
{
  const tables = [
    'users', 'customers', 'customer_accounts', 'customer_account_transactions', 'wallets', 'wallet_transactions',
    'warehouses', 'stock_movements', 'technicians', 'technician_bags', 'technician_bag_stock',
    'technician_accounts', 'technician_account_transactions', 'technician_supplies',
    'purchase_invoices', 'purchase_invoice_items', 'suppliers', 'supplier_payments',
    'employees', 'employee_attendance', 'employee_advances', 'employee_payrolls',
    'inventory_counts', 'inventory_count_items',
    // the dashboard
    'cashbox_balances', 'daily_sales_summary', 'expenses', 'low_stock_products',
    'customer_account_summary', 'technician_account_summary', 'warehouse_stock_value', 'wallet_liability_summary',
    // the screens' own views
    'purchase_invoices_summary', 'supplier_balances', 'employee_balances', 'wallet_summary', 'technician_bag_value',
  ];
  for (const t of tables) {
    await as(ADMIN);
    const adminRows = (await q(`select count(*)::int as n from public.${t}`))[0].n;
    await as(SALES);
    const e = await err(`select 1 from public.${t} limit 1`);
    const salesRows = e ? -1 : (await q(`select count(*)::int as n from public.${t}`))[0].n;
    ok(`sales sees what admin sees in ${t} (${adminRows})`, salesRows === adminRows, `sales=${salesRows} ${e ?? ''}`);
  }
  await as(SALES);
  ok('low stock shows the seeded product', (await q(`select 1 from public.low_stock_products where product_id = $1`, [P])).length === 1);
}

console.log('\n== Sales works the warehouse ==');
{
  await as(SALES);
  ok('opening stock', !(await err(`select public.rpc_admin_opening_stock($1, null)`, [items([{ product_id: P, quantity: 2, unit_cost: 100 }])])));
  ok('receive purchase', !(await err(`select public.rpc_receive_purchase($1, 1, 100, null)`, [P])));
  const inv = await err(`select public.rpc_create_purchase_invoice(null, 'مورد المبيعات', null, $1, 0, 0, null, null, null, null, $2)`,
    [items([{ product_id: P, quantity: 3, unit_cost: 100 }]), randomUUID()]);
  ok('purchase invoice on credit', !inv, inv);
  const supplier = (await one(`select id from public.suppliers where name = 'مورد المبيعات'`)).id;
  const pay = await err(`select public.rpc_pay_supplier($1, 100, 'main', null, null, $2)`, [supplier, randomUUID()]);
  ok('pays the supplier', !pay, pay);
  const issue = await err(`select public.rpc_issue_stock_to_technician($1, $2, null)`, [TECH, items([{ product_id: P, quantity: 1 }])]);
  ok('issues stock to a technician', !issue, issue);

  await asSuper();
  const wh = (await one(`select id from public.warehouses where type = 'main' and is_active limit 1`)).id;
  await as(SALES);
  const count = await one(`select public.rpc_start_inventory_count('warehouse', $1, $2) as id`, [wh, [P]]).catch(e => ({ error: e.message }));
  ok('starts a stock count', count?.id, JSON.stringify(count));
  if (count?.id) {
    const item = await one(`select id from public.inventory_count_items where inventory_count_id = $1 limit 1`, [count.id]);
    ok('records a counted quantity', !(await err(`select public.rpc_save_inventory_count_item($1, 10, null, null)`, [item.id])));
    ok('completes the count', !(await err(`select public.rpc_complete_inventory_count($1)`, [count.id])));
  }
  const supply = await err(`select public.rpc_technician_supply($1, 1, null)`, [TECH]);
  ok('reaches technician supply (not refused for its role)', !forbidden(supply), supply);
}

console.log('\n== Sales manages products and employees ==');
{
  await as(SALES);
  const N = await one(`insert into public.products (sku, name, cost_price, selling_price) values ('S23-B', 'فلتر', 5, 20) returning id`)
    .catch(e => ({ error: e.message }));
  ok('adds a product', N?.id, JSON.stringify(N));
  ok('edits a product', !(await err(`update public.products set selling_price = 30 where id = $1`, [P])));
  ok('adds a category', !(await err(`insert into public.product_categories (name) values ('مكاوي المبيعات')`)));

  const E = (await one(`insert into public.employees (full_name, monthly_salary) values ('بائع', 3000) returning id`)).id;
  ok('adds an employee', !!E);
  ok('records attendance', !(await err(`insert into public.employee_attendance (employee_id, work_date, status) values ($1, current_date, 'present')`, [E])));
  ok('gives an advance', !(await err(`select public.rpc_employee_advance($1, 100, null, 'main', null)`, [E])));
  ok('previews payroll', !(await err(`select public.rpc_payroll_preview($1, current_date)`, [E])));
  ok('pays a salary', !(await err(`select public.rpc_pay_salary($1, current_date, 0, 0, 100, 'main', null)`, [E])));
}

console.log('\n== Still admin-only ==');
{
  await as(SALES);
  ok('cannot change a user role', forbidden(await err(`select public.rpc_admin_set_role($1, 'admin')`, [TECH])));
  ok('cannot change app settings', forbidden(await err(`select public.rpc_admin_set_setting('require_verified_phone', true)`)));
  ok('cannot read the audit log', (await q(`select * from public.audit_logs`)).length === 0);
  ok('cannot add expense categories', (await err(`insert into public.expense_categories (name) values ('x')`)) !== null);
}

console.log('\n== Nobody else gained anything ==');
{
  for (const [who, id] of [['technician', TECH], ['customer', CUST_A]]) {
    await as(id);
    ok(`${who}: no purchase invoice`, forbidden(await err(`select public.rpc_create_purchase_invoice(null, 'x', null, $1, 0, 0, null, null, null, null, $2)`,
      [items([{ product_id: P, quantity: 1, unit_cost: 1 }]), randomUUID()])));
    ok(`${who}: no payroll`, forbidden(await err(`select public.rpc_payroll_preview($1, current_date)`, [uid(99)])));
    ok(`${who}: sees no employees`, (await q(`select * from public.employees`)).length === 0);
    ok(`${who}: sees only their own user row`, (await q(`select * from public.users`)).every(r => r.id === id));
    ok(`${who}: cannot edit products`, (await q(`update public.products set selling_price = 1 where id = $1 returning id`, [P]).catch(() => [])).length === 0);
  }
}

await asSuper();
finish();
