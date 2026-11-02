// tool/db_tests/phase33_technician_bag_transfer_test.mjs
//
// 0094: the technician moves stock himself between the warehouse and his
// own bag, both ways, with no approval — never below zero on either side.
//
//   cd tool/db_tests && npm install && node phase33_technician_bag_transfer_test.mjs

import { setup, uid, ADMIN, TECH, TECH2 } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err, mkUser, roleOf } = await setup(process.argv[2]);

const SALES = uid(9);
await mkUser(SALES, 'sales', '+201000000009', 'Sales');
roleOf[SALES] = 'sales';

const items = arr => JSON.stringify(arr);
const bagOf = async (tech, p) => {
  await asSuper();
  return Number((await one(`select coalesce(sum(s.quantity), 0) as n from public.technician_bag_stock s
    join public.technician_bags b on b.id = s.technician_bag_id where b.technician_id = $1 and s.product_id = $2`, [tech, p])).n);
};
const bag = p => bagOf(TECH, p);
const wh = async p => {
  await asSuper();
  return Number((await one(`select coalesce(sum(ws.quantity), 0) as n from public.warehouse_stock ws
    join public.warehouses w on w.id = ws.warehouse_id and w.type = 'main' where ws.product_id = $1`, [p])).n);
};
const move = (dir, arr, rid = null) =>
  err(`select public.rpc_technician_bag_transfer($1, $2, null, $3)`, [dir, items(arr), rid]);

await as(ADMIN);
const A = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T33A', 'خرطوم', 50, 80) returning id`)).id;
const B = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T33B', 'جلبة', 10, 20) returning id`)).id;
await q(`select public.rpc_admin_opening_stock($1, null)`, [items([
  { product_id: A, quantity: 10, unit_cost: 50 }, { product_id: B, quantity: 4, unit_cost: 10 },
])]);

console.log('\n== who can do it ==');
{
  await as(ADMIN);
  ok('admin is not a technician here', /FORBIDDEN/.test(await move('to_bag', [{ product_id: A, quantity: 1 }]) ?? ''));
  await as(SALES);
  ok('sales refused', /FORBIDDEN/.test(await move('to_bag', [{ product_id: A, quantity: 1 }]) ?? ''));
  await as(SALES);
  ok("sales can't read the technician stock list", /FORBIDDEN/.test(await err(`select * from public.rpc_technician_warehouse_stock()`) ?? ''));
}

console.log('\n== technician sees warehouse stock to pick from ==');
{
  await as(TECH);
  const rows = await q(`select * from public.rpc_technician_warehouse_stock()`);
  const a = rows.find(r => r.product_id === A);
  ok('lists warehouse quantities', a && Number(a.quantity) === 10 && rows.some(r => r.product_id === B));
  ok('no prices in it', a && !('cost_price' in a) && !('selling_price' in a));
  await as(TECH);
  ok('still no direct read of warehouse_stock', (await q(`select 1 from public.warehouse_stock`)).length === 0);
}

console.log('\n== warehouse → bag ==');
{
  await as(TECH);
  const e = await move('to_bag', [{ product_id: A, quantity: 3 }, { product_id: B, quantity: 4 }]);
  ok('moves at once, no approval', !e, e);
  ok('bag got them', await bag(A) === 3 && await bag(B) === 4);
  ok('warehouse lost them', await wh(A) === 7 && await wh(B) === 0);

  await as(TECH);
  ok("can't take more than the warehouse has", /INSUFFICIENT_STOCK/.test(await move('to_bag', [{ product_id: B, quantity: 1 }]) ?? ''));
  ok('nothing moved on refusal', await bag(B) === 4 && await wh(B) === 0);

  await as(TECH);
  ok('all lines or none', /INSUFFICIENT_STOCK/.test(await move('to_bag', [{ product_id: A, quantity: 1 }, { product_id: B, quantity: 1 }]) ?? ''));
  ok('first line rolled back', await bag(A) === 3 && await wh(A) === 7);

  await as(TECH);
  const mv = await q(`select movement_type, created_by from public.stock_movements where product_id = $1 and reference_type = 'technician_transfer'`, [A]);
  ok('recorded as صرف by the technician', mv.length === 1 && mv[0].movement_type === 'issue_to_technician' && mv[0].created_by === TECH);
}

console.log('\n== bag → warehouse ==');
{
  await as(TECH);
  const e = await move('to_warehouse', [{ product_id: A, quantity: 2 }]);
  ok('returns to the warehouse', !e, e);
  ok('balances moved back', await bag(A) === 1 && await wh(A) === 9);

  await as(TECH);
  ok("can't return more than the bag has", /INSUFFICIENT_STOCK/.test(await move('to_warehouse', [{ product_id: A, quantity: 2 }]) ?? ''));
  ok('nothing moved on refusal', await bag(A) === 1 && await wh(A) === 9);

  await as(ADMIN);
  const mv = await q(`select movement_type, from_location_type, to_location_type from public.stock_movements
    where product_id = $1 and movement_type = 'transfer'`, [A]);
  ok('admin sees it as نقل bag→warehouse', mv.length === 1 && mv[0].from_location_type === 'technician_bag' && mv[0].to_location_type === 'warehouse');
}

console.log('\n== only his own bag ==');
{
  await as(TECH2);
  ok("another technician's bag untouched", !(await move('to_bag', [{ product_id: A, quantity: 1 }])));
  ok('it went to TECH2 only', await bagOf(TECH2, A) === 1 && await bag(A) === 1);
  await as(TECH2);
  ok("TECH2 can't return TECH's units", /INSUFFICIENT_STOCK/.test(await move('to_warehouse', [{ product_id: B, quantity: 1 }]) ?? ''));
}

console.log('\n== a retried request moves once ==');
{
  const rid = uid(77);
  await as(TECH);
  ok('first send', !(await move('to_bag', [{ product_id: A, quantity: 2 }], rid)));
  await as(TECH);
  ok('same request again is accepted', !(await move('to_bag', [{ product_id: A, quantity: 2 }], rid)));
  ok('but moved only once', await bag(A) === 3);

  const rid2 = uid(78);
  await as(TECH);
  ok('a refused request…', /INSUFFICIENT_STOCK/.test(await move('to_bag', [{ product_id: B, quantity: 5 }], rid2) ?? ''));
  await as(ADMIN);
  await q(`select public.rpc_admin_opening_stock($1, null)`, [items([{ product_id: B, quantity: 5, unit_cost: 10 }])]);
  await as(TECH);
  ok('…can be sent again once stock is there', !(await move('to_bag', [{ product_id: B, quantity: 5 }], rid2)));
  ok('and it moved', await bag(B) === 9);
}

console.log('\n== bad input ==');
{
  await as(TECH);
  ok('unknown direction', /INVALID_INPUT/.test(await move('sideways', [{ product_id: A, quantity: 1 }]) ?? ''));
  await as(TECH);
  ok('empty list', /EMPTY_ORDER/.test(await move('to_bag', []) ?? ''));
  await as(TECH);
  ok('zero quantity', /INVALID_QUANTITY/.test(await move('to_bag', [{ product_id: A, quantity: 0 }]) ?? ''));
  await as(TECH);
  ok('not a product', /INVALID_ITEM/.test(await move('to_bag', [{ product_id: 'x', quantity: 1 }]) ?? ''));
}

finish();
