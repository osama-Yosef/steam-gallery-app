// tool/db_tests/phase35_stock_value_and_count_values_test.mjs
//
// 0096: the stock's value at the start and end of a month, rebuilt from the
// movement ledger, and each count's value, shortage and surplus.
//
//   cd tool/db_tests && npm install && node phase35_stock_value_and_count_values_test.mjs

import { randomUUID } from 'node:crypto';
import { setup, uid, ADMIN, TECH, TECH2 } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err, mkUser, roleOf } = await setup(process.argv[2]);

const SALES = uid(9);
await mkUser(SALES, 'sales', '+201000000009', 'Sales');
roleOf[SALES] = 'sales';

const items = arr => JSON.stringify(arr);
const monthStock = async m => {
  await as(ADMIN);
  return (await one(`select public.rpc_month_stock($1) as r`, [m])).r;
};
const backdate = async (sql, at) => {
  await asSuper();
  await q(`alter table public.stock_movements disable trigger user`);
  await q(sql, [at]);
  await q(`alter table public.stock_movements enable trigger user`);
};

await as(ADMIN);
const A = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T35A', 'سخان', 100, 150) returning id`)).id;
const B = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T35B', 'زرار', 10, 20) returning id`)).id;

console.log('\n== the stock\'s value in the past ==');
{
  // September: 10 A at 100 into the warehouse, 2 of them to a bag.
  await as(ADMIN);
  await q(`select public.rpc_admin_opening_stock($1, null)`, [items([{ product_id: A, quantity: 10, unit_cost: 100 }])]);
  await as(ADMIN);
  await q(`select public.rpc_issue_stock_to_technician($1, $2, null)`, [TECH, items([{ product_id: A, quantity: 2 }])]);
  await backdate(`update public.stock_movements set created_at = $1 where product_id = '${A}'`, '2026-09-15T10:00:00Z');

  // October: 3 A sold, 20 B at 10 in, A's cost goes up to 120 with a purchase of 5.
  await as(ADMIN);
  await q(`select public.rpc_admin_walk_in_sale(null, null, $1, 'cash', 0, $2, null)`, [items([{ product_id: A, quantity: 3 }]), randomUUID()]);
  await as(ADMIN);
  await q(`select public.rpc_admin_opening_stock($1, null)`, [items([{ product_id: B, quantity: 20, unit_cost: 10 }])]);
  await as(ADMIN);
  await q(`select public.rpc_receive_purchase($1, 5, 120, 'شراء')`, [A]);
  await backdate(`update public.stock_movements set created_at = $1 where created_at > '2026-09-30'`, '2026-10-20T10:00:00Z');

  const oct = await monthStock('2026-10-01');
  ok('1 Oct: 8 in the warehouse at 100', Number(oct.start.warehouse) === 800, JSON.stringify(oct.start));
  ok('1 Oct: 2 in the bag at 100', Number(oct.start.bags) === 200);
  ok('1 Nov: 10 A at 120 + 20 B at 10', Number(oct.end.warehouse) === 1400, JSON.stringify(oct.end));
  ok('1 Nov: the bag at A\'s new cost', Number(oct.end.bags) === 240);
  ok('the start of a month is the end of the one before', Number((await monthStock('2026-09-01')).end.warehouse) === 800);
  ok('before anything: nothing', Number((await monthStock('2026-08-01')).start.warehouse) === 0);

  const now = await monthStock(null);
  await asSuper();
  const live = Number((await one(`select coalesce(sum(stock_value), 0) as v from public.warehouse_stock_value`)).v);
  ok('this month ends now, matching today\'s stock value', Number(now.end.warehouse) === live, `${now.end.warehouse} vs ${live}`);

  await as(SALES);
  ok('sales: forbidden', /FORBIDDEN/.test(await err(`select public.rpc_month_stock(null)`) ?? ''));
}

console.log('\n== a count\'s value ==');
{
  await asSuper();
  const WH = (await one(`select id from public.warehouses where type = 'main' and is_active limit 1`)).id;
  await as(ADMIN);
  const K = (await one(`select public.rpc_start_inventory_count('warehouse', $1, null) as id`, [WH])).id;
  const line = async p => { await asSuper(); return (await one(`select id from public.inventory_count_items where inventory_count_id = $1 and product_id = $2`, [K, p])).id; };
  await as(ADMIN);
  await q(`select public.rpc_save_inventory_count_item($1, 9, 'كسر', null)`, [await line(A)]);   // 10 → 9
  await as(ADMIN);
  await q(`select public.rpc_save_inventory_count_item($1, 23, 'وصل زيادة', null)`, [await line(B)]); // 20 → 23

  const vals = async () => { await as(ADMIN); return await one(`select * from public.inventory_count_values where inventory_count_id = $1`, [K]); };
  let v = await vals();
  ok('as the system had it: 10×120 + 20×10', Number(v.system_value) === 1400, JSON.stringify(v));
  ok('as counted: 9×120 + 23×10', Number(v.counted_value) === 1310);
  ok('shortage 1 at 120', Number(v.shortage_value) === 120 && v.shortage_count === 1);
  ok('surplus 3 at 10', Number(v.surplus_value) === 30 && v.surplus_count === 1);

  await as(ADMIN);
  await q(`select public.rpc_complete_inventory_count($1)`, [K]);
  await as(ADMIN);
  await q(`update public.products set cost_price = 200 where id = $1`, [A]);
  v = await vals();
  ok('an approved count keeps the cost it was booked at', Number(v.shortage_value) === 120, JSON.stringify(v));

  await as(TECH2);
  ok('another technician sees no warehouse count values', (await q(`select * from public.inventory_count_values where inventory_count_id = $1`, [K])).length === 0);
}

finish();
