// tool/db_tests/phase34_inventory_count_live_test.mjs
//
// 0095: a count compares what was counted with the stock at the time it was
// counted, not when the count was started — selling while a count is open
// no longer shows (or approves) a false shortage.
//
//   cd tool/db_tests && npm install && node phase34_inventory_count_live_test.mjs

import { randomUUID } from 'node:crypto';
import { setup, ADMIN, TECH } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

const items = arr => JSON.stringify(arr);
const stock = async p => {
  await asSuper();
  return Number((await one(`select coalesce(sum(quantity), 0) as n from public.warehouse_stock where product_id = $1`, [p])).n);
};
const line = async (count, p) => {
  await asSuper();
  return await one(`select * from public.inventory_count_items where inventory_count_id = $1 and product_id = $2`, [count, p]);
};
const sell = async (p, qty) => {
  await as(ADMIN);
  await q(`select public.rpc_admin_walk_in_sale(null, null, $1, 'cash', 0, $2, null)`,
    [items([{ product_id: p, quantity: qty }]), randomUUID()]);
};

await as(ADMIN);
const A = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T34A', 'بذبوذ', 10, 20) returning id`)).id;
const B = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T34B', 'بكر', 10, 20) returning id`)).id;
const C = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T34C', 'بلاشر', 10, 20) returning id`)).id;
await q(`select public.rpc_admin_opening_stock($1, null)`, [items([
  { product_id: A, quantity: 45, unit_cost: 10 }, { product_id: B, quantity: 5, unit_cost: 10 },
])]);
await asSuper();
const WH = (await one(`select id from public.warehouses where type = 'main' and is_active limit 1`)).id;

console.log('\n== the shop keeps selling while a count is open ==');
await as(ADMIN);
const K = (await one(`select public.rpc_start_inventory_count('warehouse', $1, null) as id`, [WH])).id;
ok('started at 45 and 5', (await line(K, A)).system_quantity === 45 && (await line(K, B)).system_quantity === 5);

await sell(A, 1);
await sell(B, 2);
await as(ADMIN);
await q(`select public.rpc_admin_opening_stock($1, null)`, [items([{ product_id: C, quantity: 7, unit_cost: 10 }])]);

await as(ADMIN);
ok('refresh', !(await err(`select public.rpc_refresh_inventory_count($1)`, [K])));
ok('uncounted lines show today\'s stock (44, 3)', (await line(K, A)).system_quantity === 44 && (await line(K, B)).system_quantity === 3);
ok('a product that came in since is added', (await line(K, C))?.system_quantity === 7);

await as(ADMIN);
ok('counting 44 is no shortage', !(await err(`select public.rpc_save_inventory_count_item($1, 44, null, null)`, [(await line(K, A)).id])));
ok('saved as matching', (await line(K, A)).difference === 0);

console.log('\n== a line counted against a stale figure ==');
{
  await asSuper();
  // As a count saved before 0095 would hold it: stale system quantity.
  await q(`update public.inventory_count_items set system_quantity = 5 where id = $1`, [(await line(K, B)).id]);
  await as(ADMIN);
  ok('re-saving compares with today (3): 3 needs no reason', !(await err(`select public.rpc_save_inventory_count_item($1, 3, null, null)`, [(await line(K, B)).id])));
  ok('system quantity is today\'s', (await line(K, B)).system_quantity === 3);
  await as(ADMIN);
  ok('2 is a shortage and needs a reason', /COUNT_REASON_REQUIRED/.test(await err(`select public.rpc_save_inventory_count_item($1, 2, null, null)`, [(await line(K, B)).id]) ?? ''));
  await as(ADMIN);
  ok('with a reason it is saved', !(await err(`select public.rpc_save_inventory_count_item($1, 2, 'كسر', null)`, [(await line(K, B)).id])));
}

console.log('\n== selling after counting ==');
{
  await sell(A, 4); // 44 counted, then 4 sold: 40 in the warehouse
  await as(ADMIN);
  ok('refreshing keeps a counted line', !(await err(`select public.rpc_refresh_inventory_count($1)`, [K])) && (await line(K, A)).actual_quantity === 44);
  await as(ADMIN);
  ok('reopening returns the same count', (await one(`select public.rpc_start_inventory_count('warehouse', $1, null) as id`, [WH])).id === K);
  await as(ADMIN);
  const e = await err(`select public.rpc_complete_inventory_count($1)`, [K]);
  ok('approved', !e, e);
  ok('the sale after counting is not a shortage: A stays 40', await stock(A) === 40);
  ok('the real shortage is applied: B 3 → 2', await stock(B) === 2);
  ok('uncounted C untouched', await stock(C) === 7);
}

console.log('\n== a closed count is left alone ==');
{
  await as(ADMIN);
  ok('refresh on an approved count is a no-op', !(await err(`select public.rpc_refresh_inventory_count($1)`, [K])));
  ok('its lines kept', (await line(K, A)).system_quantity === 44);
  await as(TECH);
  ok('a technician refreshing a warehouse count changes nothing', !(await err(`select public.rpc_refresh_inventory_count($1)`, [K])));
}

finish();
