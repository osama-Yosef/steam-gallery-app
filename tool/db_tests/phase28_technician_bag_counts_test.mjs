// tool/db_tests/phase28_technician_bag_counts_test.mjs
//
// 0089: جرد شنطة الصنايعي — the technician counts his own bag and sends it
// for review; admin/sales approve, and only then does the bag change.
//
//   cd tool/db_tests && npm install && node phase28_technician_bag_counts_test.mjs

import { setup, uid, ADMIN, TECH, TECH2 } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err, mkUser, roleOf } = await setup(process.argv[2]);

const SALES = uid(9);
await mkUser(SALES, 'sales', '+201000000009', 'Sales');
roleOf[SALES] = 'sales';

const items = arr => JSON.stringify(arr);
const bag = async p => {
  await asSuper();
  return Number((await one(`select coalesce(sum(s.quantity), 0) as n from public.technician_bag_stock s
    join public.technician_bags b on b.id = s.technician_bag_id where b.technician_id = $1 and s.product_id = $2`, [TECH, p])).n);
};
const lineOf = async (count, p) => {
  await asSuper();
  return (await one(`select id from public.inventory_count_items where inventory_count_id = $1 and product_id = $2`, [count, p])).id;
};

await as(ADMIN);
const A = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T28A', 'خرطوم', 50, 80) returning id`)).id;
const B = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T28B', 'جلبة', 10, 20) returning id`)).id;
const C = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T28C', 'مسمار', 1, 2) returning id`)).id;
await q(`select public.rpc_admin_opening_stock($1, null)`, [items([
  { product_id: A, quantity: 20, unit_cost: 50 }, { product_id: B, quantity: 20, unit_cost: 10 }, { product_id: C, quantity: 20, unit_cost: 1 },
])]);
await q(`select public.rpc_issue_stock_to_technician($1, $2, null)`, [TECH, items([{ product_id: A, quantity: 5 }, { product_id: B, quantity: 3 }])]);

console.log('\n== technician counts his own bag ==');
let count;
{
  await as(TECH);
  count = (await one(`select public.rpc_start_bag_count($1) as id`, [TECH])).id;
  ok('starts a count of his bag', !!count);
  const lines = await q(`select product_id, system_quantity from public.inventory_count_items where inventory_count_id = $1`, [count]);
  ok('lines = what is in the bag', lines.length === 2);

  await as(TECH);
  ok('starting again reopens the same count', (await one(`select public.rpc_start_bag_count($1) as id`, [TECH])).id === count);

  await as(TECH);
  ok("can't count another technician's bag", /FORBIDDEN/.test(await err(`select public.rpc_start_bag_count($1)`, [TECH2]) ?? ''));
  await as(TECH2);
  ok("other technician can't see it", (await q(`select id from public.inventory_counts where id = $1`, [count])).length === 0);
  await as(TECH2);
  ok("other technician can't edit it", /FORBIDDEN/.test(await err(`select public.rpc_save_inventory_count_item($1, 1, 'x', null)`, [await lineOf(count, A)]) ?? ''));

  const lineA = await lineOf(count, A), lineB = await lineOf(count, B);
  await as(TECH);
  ok('a shortage needs a reason', /COUNT_REASON_REQUIRED/.test(await err(`select public.rpc_save_inventory_count_item($1, 3, '  ', null)`, [lineA]) ?? ''));
  await as(TECH);
  ok('shortage with reason saved', !(await err(`select public.rpc_save_inventory_count_item($1, 3, 'اتكسر في شغلانة', null)`, [lineA])));

  await as(TECH);
  ok("can't submit with an uncounted line", /COUNT_INCOMPLETE/.test(await err(`select public.rpc_submit_inventory_count($1)`, [count]) ?? ''));
  await as(TECH);
  ok('matching line saved without a reason', !(await err(`select public.rpc_save_inventory_count_item($1, 3, null, null)`, [lineB])));

  await as(TECH);
  const lineC = (await one(`select public.rpc_add_inventory_count_item($1, $2) as id`, [count, C])).id;
  ok('adds a product not in the bag', !!lineC);
  await as(TECH);
  ok('surplus saved', !(await err(`select public.rpc_save_inventory_count_item($1, 4, 'لقيتهم في العربية', null)`, [lineC])));

  ok('bag untouched before approval', await bag(A) === 5 && await bag(C) === 0);

  await as(TECH);
  ok('technician sends it for review', !(await err(`select public.rpc_submit_inventory_count($1)`, [count])));
  await as(TECH);
  ok('read-only for him after that', /COUNT_ALREADY_SUBMITTED/.test(await err(`select public.rpc_save_inventory_count_item($1, 5, null, null)`, [lineA]) ?? ''));
  await as(TECH);
  ok("technician can't approve", /FORBIDDEN/.test(await err(`select public.rpc_complete_inventory_count($1)`, [count]) ?? ''));
  await as(TECH);
  ok('he still sees his count lines', (await q(`select id from public.inventory_count_items where inventory_count_id = $1`, [count])).length === 3);
}

console.log('\n== sales approves ==');
{
  await as(SALES);
  ok('sales can still correct it', !(await err(`select public.rpc_save_inventory_count_item($1, 4, 'اتكسر واحدة بس', null)`, [await lineOf(count, A)])));
  await as(SALES);
  const e = await err(`select public.rpc_complete_inventory_count($1)`, [count]);
  ok('sales approves', !e, e);
  ok('shortage taken off the bag', await bag(A) === 4);
  ok('matching line unchanged', await bag(B) === 3);
  ok('surplus added to the bag', await bag(C) === 4);
  const mv = await q(`select notes from public.stock_movements where reference_id = $1 order by notes`, [count]);
  ok('movements carry the reasons', mv.length === 2 && mv.some(m => m.notes === 'اتكسر واحدة بس') && mv.some(m => m.notes === 'لقيتهم في العربية'));
  await asSuper();
  const owed = await one(`select count(*)::int as n from public.technician_account_transactions where technician_id = $1`, [TECH]);
  ok('no money charged to the technician', owed.n === 0);
}

console.log('\n== admin counts a bag directly ==');
{
  await as(ADMIN);
  const c2 = (await one(`select public.rpc_start_bag_count($1) as id`, [TECH])).id;
  ok('new count after the last was approved', c2 && c2 !== count);
  await as(ADMIN);
  ok('admin can approve without submitting', !(await err(`select public.rpc_save_inventory_count_item($1, 2, 'جرد مفاجئ', null)`, [await lineOf(c2, B)])));
  await as(ADMIN);
  ok('approved', !(await err(`select public.rpc_complete_inventory_count($1)`, [c2])));
  ok('bag adjusted', await bag(B) === 2);
}

finish();
