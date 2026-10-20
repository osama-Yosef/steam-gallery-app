// tool/db_tests/phase26_edit_invoices_expenses_test.mjs
//
// 0087: a technician (or admin) edits and deletes a technician invoice —
// stock between the sale and the bag, money on the technician's or the
// customer's account; any invoice line can be re-priced; admin and sales
// edit an expense, the difference going through its till; and a user moved
// off the technician role stops being an active technician.
//
//   cd tool/db_tests && npm install && node phase26_edit_invoices_expenses_test.mjs

import { setup, uid, ADMIN, TECH, TECH2, CUST_A } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err, mkUser, roleOf } = await setup(process.argv[2]);

const SALES = uid(9);
await mkUser(SALES, 'sales', '+201000000009', 'Sales');
roleOf[SALES] = 'sales';

const items = arr => JSON.stringify(arr);
const num = v => Number(v);
const due = async (t = TECH) => {
  await asSuper();
  return num((await one(`select amount_due from public.technician_account_summary where technician_id = $1`, [t])).amount_due);
};
const bag = async (p, t = TECH) => {
  await asSuper();
  return num((await one(`select coalesce(sum(s.quantity), 0) as n from public.technician_bag_stock s
    join public.technician_bags b on b.id = s.technician_bag_id where b.technician_id = $1 and s.product_id = $2`, [t, p])).n);
};
const wh = async p => {
  await asSuper();
  return num((await one(`select coalesce(sum(quantity), 0) as n from public.warehouse_stock where product_id = $1`, [p])).n);
};
const sale = async id => { await asSuper(); return one(`select * from public.sales where id = $1`, [id]); };
const till = async kind => {
  await asSuper();
  return num((await one(`select balance from public.cashbox_balances where kind = $1`, [kind])).balance);
};
const debt = async c => {
  await asSuper();
  return num((await one(`select coalesce(sum(amount), 0) as n from public.customer_account_transactions where customer_id = $1`, [c])).n);
};
const onInvoice = async id => {
  await asSuper();
  return q(`select product_id, unit_price_snapshot::numeric as price, (quantity - returned_quantity) as qty
    from public.sale_items_with_returns where sale_id = $1 and quantity > returned_quantity order by price`, [id]);
};

console.log('\n== Seed ==');
await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T26', 'مكواة', 100, 200) returning id`)).id;
const SVC = (await one(`insert into public.products (sku, name, cost_price, selling_price, is_service) values ('S26', 'تركيب', 0, 0, true) returning id`)).id;
await q(`select public.rpc_admin_opening_stock($1, null)`, [items([{ product_id: P, quantity: 30, unit_cost: 100 }])]);
await q(`select public.rpc_issue_stock_to_technician($1, $2, null)`, [TECH, items([{ product_id: P, quantity: 10 }])]);
await q(`select public.rpc_cashbox_deposit(5000, 'عهدة', 'cash')`);
const CAT = (await one(`insert into public.expense_categories (name) values ('كهرباء 26') returning id`)).id;
const CAT2 = (await one(`insert into public.expense_categories (name) values ('مواصلات 26') returning id`)).id;
ok('seeded', true);

console.log('\n== Technician edits his own invoice ==');
let S1;
{
  const d0 = await due();
  await as(TECH);
  S1 = (await one(`select public.rpc_technician_sale($1, null, 'walk', null, $2, 'cash', 0, 400, null, null, null) as id`,
    [TECH, items([{ product_id: P, quantity: 2 }])])).id;
  ok('sold 2 × 200, technician owes 400', await due() === d0 + 400);
  ok('bag 8', await bag(P) === 8);

  await as(TECH);
  let e = await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [S1, items([{ product_id: P, quantity: 1 }])]);
  ok('one taken off', !e, e);
  ok('back in the bag (9)', await bag(P) === 9);
  let s = await sale(S1);
  ok('total 200, paid 200', num(s.total) === 200 && num(s.paid_amount) === 200, JSON.stringify(s));
  ok('technician owes 200', await due() === d0 + 200);

  await as(TECH);
  e = await err(`select public.rpc_edit_technician_sale($1, $2, null, 'سعر غلط')`,
    [S1, items([{ product_id: P, quantity: 1, unit_price: 250, reprice: true }])]);
  ok('re-priced to 250', !e, e);
  ok('bag untouched by a price change', await bag(P) === 9);
  s = await sale(S1);
  ok('total 250, paid 250', num(s.total) === 250 && num(s.paid_amount) === 250, JSON.stringify(s));
  ok('technician owes 250', await due() === d0 + 250);
  const lines = await onInvoice(S1);
  ok('one line of 1 at 250 on the invoice', lines.length === 1 && num(lines[0].price) === 250 && num(lines[0].qty) === 1, JSON.stringify(lines));

  await as(TECH);
  e = await err(`select public.rpc_edit_technician_sale($1, $2, 50, null)`,
    [S1, items([{ product_id: P, quantity: 3, unit_price: 250, reprice: true }, { product_id: SVC, quantity: 1, unit_price: 100 }])]);
  ok('two more, a service and a discount', !e, e);
  ok('bag 7', await bag(P) === 7);
  s = await sale(S1);
  ok('total 3×250 + 100 − 50 = 800', num(s.total) === 800, JSON.stringify(s));
  ok('technician owes 800', await due() === d0 + 800);

  await as(TECH);
  e = await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [S1, items([{ product_id: P, quantity: 3, unit_price: 250, reprice: true }, { product_id: SVC, quantity: 1, unit_price: 100 }])]);
  ok('the same edit again changes nothing', !e && await due() === d0 + 800 && await bag(P) === 7, e);

  await as(TECH);
  ok('more than the bag holds refused',
    /INSUFFICIENT_STOCK/.test(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [S1, items([{ product_id: P, quantity: 30 }])]) ?? ''));
  ok('emptying it refused (delete instead)',
    /EMPTY_ORDER/.test(await err(`select public.rpc_edit_technician_sale($1, '[]', null, null)`, [S1]) ?? ''));
  ok('a zero price refused',
    /INVALID_AMOUNT/.test(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [S1, items([{ product_id: P, quantity: 3, unit_price: 0, reprice: true }])]) ?? ''));
  ok('nothing changed by the refused edits', await due() === d0 + 800 && await bag(P) === 7);

  await as(TECH);
  const items1 = await q(`select quantity, returned_quantity from public.sale_items_display where sale_id = $1`, [S1]);
  const left = items1.reduce((n, r) => n + r.quantity - r.returned_quantity, 0);
  ok('the technician sees what is on it now (3 + 1 service)', left === 4, JSON.stringify(items1));
}

console.log('\n== Who may edit ==');
{
  await as(TECH2);
  ok('another technician: forbidden', /FORBIDDEN/.test(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [S1, items([{ product_id: P, quantity: 1 }])]) ?? ''));
  ok('another technician can not delete it', /FORBIDDEN/.test(await err(`select public.rpc_delete_technician_sale($1, null)`, [S1]) ?? ''));
  await as(CUST_A);
  ok('a customer: forbidden', /FORBIDDEN/.test(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [S1, items([{ product_id: P, quantity: 1 }])]) ?? ''));
  await as(SALES);
  ok('sales: forbidden', /FORBIDDEN/.test(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [S1, items([{ product_id: P, quantity: 1 }])]) ?? ''));
  await as(ADMIN);
  const e = await err(`select public.rpc_edit_technician_sale($1, $2, 0, 'admin')`, [S1, items([{ product_id: P, quantity: 3, unit_price: 250, reprice: true }, { product_id: SVC, quantity: 1 }])]);
  ok('admin may (removes the discount)', !e, e);
  ok('total 850', num((await sale(S1)).total) === 850);
}

console.log('\n== Deleting a technician invoice ==');
{
  const dBefore = await due();
  await as(TECH);
  const e = await err(`select public.rpc_delete_technician_sale($1, 'غلط')`, [S1]);
  ok('deleted', !e, e);
  const s = await sale(S1);
  ok('cancelled, paid 0', s.status === 'cancelled' && num(s.paid_amount) === 0, JSON.stringify(s));
  ok('all 3 back in the bag (10)', await bag(P) === 10);
  ok('dues lose the 850', await due() === dBefore - 850);
  await as(TECH);
  ok('deleting again is a no-op', !(await err(`select public.rpc_delete_technician_sale($1, null)`, [S1])) && await due() === dBefore - 850);
  ok('a cancelled invoice can not be edited',
    /SALE_NOT_EDITABLE/.test(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [S1, items([{ product_id: P, quantity: 1 }])]) ?? ''));
}

console.log('\n== A deferred technician sale moves the customer account ==');
{
  const c0 = await debt(CUST_A);
  await as(ADMIN);
  const S2 = (await one(`select public.rpc_technician_sale($1, $2, null, null, $3, 'deferred', 0, 0, null, null, null) as id`,
    [TECH, CUST_A, items([{ product_id: P, quantity: 1 }])])).id;
  ok('customer owes 200', await debt(CUST_A) === c0 + 200);
  const d0 = await due();
  await as(ADMIN);
  let e = await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [S2, items([{ product_id: P, quantity: 1, unit_price: 150, reprice: true }])]);
  ok('re-priced to 150', !e, e);
  ok('customer owes 150', await debt(CUST_A) === c0 + 150);
  ok('technician dues untouched', await due() === d0);
  await as(ADMIN);
  e = await err(`select public.rpc_delete_technician_sale($1, null)`, [S2]);
  ok('deleted', !e, e);
  ok('customer owes nothing for it', await debt(CUST_A) === c0);
}

console.log('\n== Re-pricing a register invoice ==');
{
  const cash0 = await till('cash');
  const w0 = await wh(P);
  await as(SALES);
  const W = (await one(`select public.rpc_admin_walk_in_sale('زبون', null, $1, 'cash', 0, null, null) as id`,
    [items([{ product_id: P, quantity: 2 }])])).id;
  ok('sold 2 × 200 into the drawer', await till('cash') === cash0 + 400);

  await as(SALES);
  let e = await err(`select public.rpc_admin_edit_sale($1, $2, null, null, null)`, [W, items([{ product_id: P, quantity: 2, unit_price: 999 }])]);
  ok('a price without "reprice" is ignored for a stock product, as before', !e && num((await sale(W)).total) === 400, e);

  await as(SALES);
  e = await err(`select public.rpc_admin_edit_sale($1, $2, null, 'سعر', null)`, [W, items([{ product_id: P, quantity: 2, unit_price: 180, reprice: true }])]);
  ok('re-priced to 180', !e, e);
  ok('total 360', num((await sale(W)).total) === 360);
  ok('40 handed back from the drawer', await till('cash') === cash0 + 360);
  ok('warehouse untouched by a price change', await wh(P) === w0 - 2);

  await as(ADMIN);
  e = await err(`select public.rpc_admin_edit_sale($1, $2, null, null, null)`, [W, items([{ product_id: P, quantity: 3, unit_price: 220, reprice: true }])]);
  ok('one more, all at 220', !e, e);
  ok('total 660, drawer +300', num((await sale(W)).total) === 660 && await till('cash') === cash0 + 660);
  ok('warehouse −3', await wh(P) === w0 - 3);
  const lines = await onInvoice(W);
  ok('3 at 220 on the invoice', lines.every(l => num(l.price) === 220) && lines.reduce((n, l) => n + num(l.qty), 0) === 3, JSON.stringify(lines));

  await asSuper();
  const rev = num((await one(`select coalesce(sum(si.line_total - coalesce(r.refund, 0)), 0) as v from public.sale_items si
    left join (select sale_item_id, sum(refund_amount) as refund from public.sale_item_returns group by sale_item_id) r on r.sale_item_id = si.id
    where si.sale_id = $1`, [W])).v);
  ok('revenue counted for it is its total (660)', rev === 660, String(rev));
}

console.log('\n== Editing an expense ==');
{
  const cash0 = await till('cash');
  await as(SALES);
  const X = (await one(`select public.rpc_record_expense($1, 100, current_date, 'فاتورة', null, 'cash') as id`, [CAT])).id;
  ok('recorded 100', await till('cash') === cash0 - 100);

  await as(SALES);
  let e = await err(`select public.rpc_edit_expense($1, null, 150, null, 'فاتورة كهرباء')`, [X]);
  ok('sales raises it to 150', !e, e);
  ok('drawer −50 more', await till('cash') === cash0 - 150);
  await asSuper();
  let x = await one(`select * from public.expenses where id = $1`, [X]);
  ok('the expense reads 150 with its new notes', num(x.amount) === 150 && x.notes === 'فاتورة كهرباء');

  await as(ADMIN);
  e = await err(`select public.rpc_edit_expense($1, $2, 80, '2026-01-05', null)`, [X, CAT2]);
  ok('admin lowers it to 80 and moves it', !e, e);
  ok('drawer gets 70 back', await till('cash') === cash0 - 80);
  await asSuper();
  x = await one(`select * from public.expenses where id = $1`, [X]);
  ok('80, other category, other date', num(x.amount) === 80 && x.category_id === CAT2 && String(x.expense_date.toISOString?.() ?? x.expense_date).startsWith('2026-01-0'), JSON.stringify(x));

  await as(TECH);
  ok('a technician: forbidden', /FORBIDDEN/.test(await err(`select public.rpc_edit_expense($1, null, 10, null, null)`, [X]) ?? ''));
  await as(ADMIN);
  ok('zero refused', /INVALID_AMOUNT/.test(await err(`select public.rpc_edit_expense($1, null, 0, null, null)`, [X]) ?? ''));
  await as(ADMIN);
  ok('a direct update is still refused', !!(await err(`update public.expenses set amount = 1 where id = $1`, [X])) || num((await one(`select amount from public.expenses where id = $1`, [X])).amount) === 80);
  await asSuper();
  ok('even for the database owner outside the RPC', /immutable/.test(await err(`update public.expenses set amount = 1 where id = $1`, [X]) ?? ''));
  ok('and nobody can delete one', /immutable/.test(await err(`delete from public.expenses where id = $1`, [X]) ?? ''));

  await as(ADMIN);
  const EMP = (await one(`insert into public.employees (full_name, monthly_salary) values ('موظف', 1000) returning id`)).id;
  await q(`select public.rpc_pay_salary($1, date_trunc('month', current_date)::date, 0, 0, 0, 'cash', null)`, [EMP]);
  await asSuper();
  const PX = (await one(`select expense_id from public.employee_payrolls where employee_id = $1`, [EMP])).expense_id;
  await as(ADMIN);
  ok('a salary\'s expense is refused', !!PX && /EXPENSE_IS_PAYROLL/.test(await err(`select public.rpc_edit_expense($1, null, 5, null, null)`, [PX]) ?? ''));
}

console.log('\n== Role change and the technicians row ==');
{
  const MOVED = uid(20);
  await asSuper();
  await mkUser(MOVED, 'technician', '+201000000020', 'معاذ');
  roleOf[MOVED] = 'technician';
  const active = async () => { await asSuper(); return (await one(`select is_active from public.technicians where id = $1`, [MOVED])).is_active; };
  ok('created as an active technician', await active() === true);
  await as(ADMIN);
  await q(`select public.rpc_admin_set_role($1, 'sales')`, [MOVED]);
  ok('made sales: no longer an active technician', await active() === false);
  await asSuper();
  ok('bag and account kept', !!(await one(`select 1 from public.technician_bags where technician_id = $1`, [MOVED]))
    && !!(await one(`select 1 from public.technician_accounts where id = $1`, [MOVED])));
  await as(ADMIN);
  await q(`select public.rpc_admin_set_role($1, 'technician')`, [MOVED]);
  ok('made a technician again: active', await active() === true);
  await asSuper();
  await q(`update auth.users set raw_app_meta_data = raw_app_meta_data || '{"note": 1}'::jsonb where id = $1`, [TECH]);
  ok('other metadata changes leave the flag alone', (await one(`select is_active from public.technicians where id = $1`, [TECH])).is_active === true);
}

finish();
