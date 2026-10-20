// tool/db_tests/phase25_technician_sale_price_test.mjs
//
// 0086: a technician selling from his bag can charge a stock product more or
// less than its price; with no price sent the catalogue price applies.
//
//   cd tool/db_tests && npm install && node phase25_technician_sale_price_test.mjs

import { setup, ADMIN, TECH } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

const items = arr => JSON.stringify(arr);
const due = async () => {
  await asSuper();
  return Number((await one(`select amount_due from public.technician_account_summary where technician_id = $1`, [TECH])).amount_due);
};
const sell = async (lines, paid) => {
  await as(TECH);
  return (await one(`select public.rpc_technician_sale($1, null, 'walk', null, $2, 'cash', 0, $3, null, null, null) as id`,
    [TECH, items(lines), paid])).id;
};
const line = async saleId => {
  await asSuper();
  return one(`select unit_price_snapshot::numeric as price, unit_cost_snapshot::numeric as cost from public.sale_items where sale_id = $1`, [saleId]);
};

await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T25', 'مكواة', 100, 200) returning id`)).id;
await q(`select public.rpc_admin_opening_stock($1, null)`, [items([{ product_id: P, quantity: 10, unit_cost: 100 }])]);
await q(`select public.rpc_issue_stock_to_technician($1, $2, null)`, [TECH, items([{ product_id: P, quantity: 5 }])]);

console.log('\n== No price sent: the catalogue price, as before ==');
{
  const d0 = await due();
  const s = await sell([{ product_id: P, quantity: 1 }], 200);
  const l = await line(s);
  ok('charged 200', Number(l.price) === 200);
  ok('technician owes 200 more', await due() === d0 + 200);
}

console.log('\n== Priced up ==');
{
  const d0 = await due();
  const s = await sell([{ product_id: P, quantity: 1, unit_price: 250 }], 250);
  const l = await line(s);
  ok('charged 250', Number(l.price) === 250);
  ok('cost stays 100 (real margin)', Number(l.cost) === 100);
  ok('technician owes the 250 he charged', await due() === d0 + 250);
}

console.log('\n== Priced down ==');
{
  const d0 = await due();
  const s = await sell([{ product_id: P, quantity: 2, unit_price: 150 }], 300);
  ok('charged 150 each', Number((await line(s)).price) === 150);
  ok('technician owes 300', await due() === d0 + 300);
}

console.log('\n== Bad prices refused ==');
await as(TECH);
ok('zero refused', (await err(`select public.rpc_technician_sale($1, null, 'walk', null, $2, 'cash', 0, 0, null, null, null)`,
  [TECH, items([{ product_id: P, quantity: 1, unit_price: 0 }])]))?.includes('INVALID_AMOUNT'));
ok('negative refused', (await err(`select public.rpc_technician_sale($1, null, 'walk', null, $2, 'cash', 0, 10, null, null, null)`,
  [TECH, items([{ product_id: P, quantity: 1, unit_price: -5 }])]))?.includes('INVALID_AMOUNT'));

finish();
