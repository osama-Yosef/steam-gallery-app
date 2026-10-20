// tool/db_tests/phase27_technician_sale_edit_limits_test.mjs
//
// 0088: a technician edits his own invoice for 3 days only (admin any
// time), and no edit or delete may push «المطلوب توريده» below zero.
//
//   cd tool/db_tests && npm install && node phase27_technician_sale_edit_limits_test.mjs

import { setup, ADMIN, TECH } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

const items = arr => JSON.stringify(arr);
const due = async () => {
  await asSuper();
  return Number((await one(`select amount_due from public.technician_account_summary where technician_id = $1`, [TECH])).amount_due);
};
const bag = async p => {
  await asSuper();
  return Number((await one(`select coalesce(sum(s.quantity), 0) as n from public.technician_bag_stock s
    join public.technician_bags b on b.id = s.technician_bag_id where b.technician_id = $1 and s.product_id = $2`, [TECH, p])).n);
};
const sell = async (qty, paid) => {
  await as(TECH);
  return (await one(`select public.rpc_technician_sale($1, null, 'walk', null, $2, 'cash', 0, $3, null, null, null) as id`,
    [TECH, items([{ product_id: P, quantity: qty }]), paid])).id;
};
const age = async (id, days) => {
  await asSuper();
  await q(`update public.sales set created_at = now() - make_interval(days => $2) where id = $1`, [id, days]);
};

await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T27', 'مكواة', 100, 200) returning id`)).id;
await q(`select public.rpc_admin_opening_stock($1, null)`, [items([{ product_id: P, quantity: 20, unit_cost: 100 }])]);
await q(`select public.rpc_issue_stock_to_technician($1, $2, null)`, [TECH, items([{ product_id: P, quantity: 10 }])]);

console.log('\n== 3 days for the technician ==');
{
  const s = await sell(2, 400);
  await age(s, 2);
  await as(TECH);
  ok('2 days old: he can edit it', !(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [s, items([{ product_id: P, quantity: 3 }])])));

  await age(s, 4);
  const bag0 = await bag(P), due0 = await due();
  await as(TECH);
  ok('4 days old: edit refused', /EDIT_WINDOW_EXPIRED/.test(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [s, items([{ product_id: P, quantity: 1 }])]) ?? ''));
  await as(TECH);
  ok('4 days old: delete refused', /EDIT_WINDOW_EXPIRED/.test(await err(`select public.rpc_delete_technician_sale($1, null)`, [s]) ?? ''));
  ok('nothing moved by the refusals', await bag(P) === bag0 && await due() === due0);

  await as(ADMIN);
  const e = await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [s, items([{ product_id: P, quantity: 1 }])]);
  ok('admin still can', !e, e);
}

console.log('\n== «المطلوب توريده» never below zero ==');
{
  // Remit everything owed, then try to lower an invoice.
  const s = await sell(2, 400);
  const owed = await due();
  await as(ADMIN);
  await q(`select public.rpc_technician_supply($1, $2, 'توريد')`, [TECH, owed]);
  ok('remitted all: owes 0', await due() === 0);

  const bag0 = await bag(P);
  await as(TECH);
  ok('lowering the price refused', /TECHNICIAN_DUE_NEGATIVE/.test(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`,
    [s, items([{ product_id: P, quantity: 2, unit_price: 150, reprice: true }])]) ?? ''));
  await as(TECH);
  ok('taking an item off refused', /TECHNICIAN_DUE_NEGATIVE/.test(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`,
    [s, items([{ product_id: P, quantity: 1 }])]) ?? ''));
  await as(ADMIN);
  ok('deleting refused, for admin too', /TECHNICIAN_DUE_NEGATIVE/.test(await err(`select public.rpc_delete_technician_sale($1, null)`, [s]) ?? ''));
  ok('stock and dues untouched', await bag(P) === bag0 && await due() === 0);

  await as(TECH);
  ok('raising it is fine', !(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [s, items([{ product_id: P, quantity: 3 }])])));
  ok('now owes 200', await due() === 200);
  await as(TECH);
  ok('lowering back within what he owes is fine',
    !(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [s, items([{ product_id: P, quantity: 2 }])])));
  ok('owes 0 again, never below', await due() === 0);
}

finish();
