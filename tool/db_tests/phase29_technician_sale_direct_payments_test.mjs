// tool/db_tests/phase29_technician_sale_direct_payments_test.mjs
//
// 0090: a technician's customer pays by bank / wallet transfer straight
// into the shop's accounts — it lands in that till, counts as paid, and is
// never added to what the technician owes.
//
//   cd tool/db_tests && npm install && node phase29_technician_sale_direct_payments_test.mjs

import { setup, ADMIN, TECH } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

const items = arr => JSON.stringify(arr);
const due = async () => {
  await asSuper();
  return Number((await one(`select amount_due from public.technician_account_summary where technician_id = $1`, [TECH])).amount_due);
};
const till = async kind => {
  await asSuper();
  return Number((await one(`select coalesce(sum(t.amount), 0) as n from public.cash_transactions t
    join public.cashboxes c on c.id = t.cashbox_id where c.kind = $1 and c.is_active`, [kind])).n);
};
const sale = async id => {
  await asSuper();
  return await one(`select total, paid_amount, transfer_amount, wallet_amount, status from public.sales where id = $1`, [id]);
};
// cash = what the technician collected; transfer / wallet = straight to the shop.
const sell = async (qty, method, cash, transfer = 0, wallet = 0) => {
  await as(TECH);
  return (await one(`select public.rpc_technician_sale($1, null, 'عميل', null, $2, $3, 0, $4, null, null, null, $5, $6) as id`,
    [TECH, items([{ product_id: P, quantity: qty }]), method, cash, transfer, wallet])).id;
};

await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T29', 'سخان', 500, 1000) returning id`)).id;
await q(`select public.rpc_admin_opening_stock($1, null)`, [items([{ product_id: P, quantity: 20, unit_cost: 500 }])]);
await q(`select public.rpc_issue_stock_to_technician($1, $2, null)`, [TECH, items([{ product_id: P, quantity: 15 }])]);

console.log('\n== all by bank transfer ==');
{
  const bank0 = await till('transfer'), due0 = await due();
  const s = await sell(1, 'transfer', 0, 1000);
  const r = await sale(s);
  ok('counts as paid in full', Number(r.paid_amount) === 1000 && Number(r.transfer_amount) === 1000);
  ok('lands in the bank account', await till('transfer') === bank0 + 1000);
  ok('nothing added to what the technician owes', await due() === due0);
}

console.log('\n== all by wallet ==');
{
  const w0 = await till('wallet'), due0 = await due();
  await sell(1, 'wallet', 0, 0, 1000);
  ok('lands in the wallet', await till('wallet') === w0 + 1000);
  ok('nothing added to what the technician owes', await due() === due0);
}

console.log('\n== split: 1000 bank + 1000 cash ==');
let split;
{
  const bank0 = await till('transfer'), cash0 = await till('cash'), due0 = await due();
  split = await sell(2, 'cash', 1000, 1000);
  const r = await sale(split);
  ok('paid 2000 of 2000', Number(r.paid_amount) === 2000);
  ok('bank +1000', await till('transfer') === bank0 + 1000);
  ok('drawer untouched until he remits', await till('cash') === cash0);
  ok('technician owes only the 1000 cash', await due() === due0 + 1000);
}

console.log('\n== limits ==');
{
  await as(TECH);
  ok('more than the total refused', /PAYMENT_EXCEEDS_TOTAL/.test(await err(
    `select public.rpc_technician_sale($1, null, null, null, $2, 'cash', 0, 600, null, null, null, 600, 0)`,
    [TECH, items([{ product_id: P, quantity: 1 }])]) ?? ''));
  await as(TECH);
  ok('negative transfer refused', /INVALID_AMOUNT/.test(await err(
    `select public.rpc_technician_sale($1, null, null, null, $2, 'cash', 0, 0, null, null, null, -1, 0)`,
    [TECH, items([{ product_id: P, quantity: 1 }])]) ?? ''));
  await as(TECH);
  const old = await err(`select public.rpc_technician_sale($1, null, null, null, $2, 'cash', 0, 1000, null, null, null)`,
    [TECH, items([{ product_id: P, quantity: 1 }])]);
  ok('an older app (no transfer args) still works', !old, old);
}

console.log('\n== editing a split invoice ==');
{
  const due0 = await due(), bank0 = await till('transfer');
  await as(TECH);
  ok('raise to 3 pieces', !(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [split, items([{ product_id: P, quantity: 3 }])])));
  let r = await sale(split);
  ok('still paid in full: 3000', Number(r.paid_amount) === 3000);
  ok('the extra 1000 is on the technician (cash)', await due() === due0 + 1000);
  ok('bank part unchanged', await till('transfer') === bank0);

  await as(TECH);
  ok('back to 2 pieces', !(await err(`select public.rpc_edit_technician_sale($1, $2, null, null)`, [split, items([{ product_id: P, quantity: 2 }])])));
  ok('technician back where he was', await due() === due0);

  await as(ADMIN);
  ok("can't go below what was transferred", /TOTAL_BELOW_DIRECT_PAYMENT/.test(await err(
    `select public.rpc_edit_technician_sale($1, $2, null, null)`,
    [split, items([{ product_id: P, quantity: 1, unit_price: 800, reprice: true }])]) ?? ''));
}

console.log('\n== deleting a split invoice ==');
{
  await as(TECH);
  ok('technician can\'t (money in the bank)', /DIRECT_PAYMENT_ADMIN_ONLY/.test(await err(`select public.rpc_delete_technician_sale($1, null)`, [split]) ?? ''));
  const due0 = await due(), bank0 = await till('transfer');
  await as(ADMIN);
  const e = await err(`select public.rpc_delete_technician_sale($1, 'العميل رجع')`, [split]);
  ok('admin deletes it', !e, e);
  const r = await sale(split);
  ok('cancelled', r.status === 'cancelled');
  ok('bank part refunded', await till('transfer') === bank0 - 1000);
  ok('cash part off the technician', await due() === due0 - 1000);
}

finish();
