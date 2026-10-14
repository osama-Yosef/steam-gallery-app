// tool/db_tests/phase24_walk_in_credit_and_bag_test.mjs
//
// 0084: the register sells on credit (آجل) or part-paid (جزئي) to a
// registered customer, and from a technician's bag; returns and invoice
// edits cancel the customer's debt before refunding cash.
//
//   cd tool/db_tests && npm install && node phase24_walk_in_credit_and_bag_test.mjs

import { randomUUID } from 'node:crypto';
import { setup, uid, ADMIN, TECH, CUST_A } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err, mkUser, roleOf } = await setup(process.argv[2]);

const SALES = uid(9);
await mkUser(SALES, 'sales', '+201000000009', 'Sales');
roleOf[SALES] = 'sales';

const items = arr => JSON.stringify(arr);
const till = async kind => {
  await asSuper();
  return Number((await one(`select coalesce(sum(ct.amount), 0)::numeric as b from public.cash_transactions ct
    join public.cashboxes cb on cb.id = ct.cashbox_id where cb.kind = $1 and cb.is_active`, [kind])).b);
};
const debt = async () => {
  await asSuper();
  return Number((await one(`select coalesce(sum(amount), 0)::numeric as d from public.customer_account_transactions where customer_id = $1`, [CUST_A])).d);
};
const whStock = async p => {
  await asSuper();
  return Number((await one(`select coalesce(sum(quantity), 0)::int as n from public.warehouse_stock where product_id = $1`, [p])).n);
};
const bagStock = async p => {
  await asSuper();
  return Number((await one(`select coalesce(sum(s.quantity), 0)::int as n from public.technician_bag_stock s
    join public.technician_bags b on b.id = s.technician_bag_id where b.technician_id = $1 and s.product_id = $2`, [TECH, p])).n);
};
const sell = async (who, { customer = null, paid = null, method = 'cash', tech = null, lines, discount = 0 }) => {
  await as(who);
  return one(`select public.rpc_admin_walk_in_sale(null, null, $1, $2, $3, $4, null, $5, $6, $7) as id`,
    [items(lines), method, discount, randomUUID(), customer, paid, tech]);
};
const sellErr = async (who, opts) => {
  try { await sell(who, opts); return null; } catch (e) { return e.message; }
};

await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('W24', 'مكواة', 100, 200) returning id`)).id;
await q(`select public.rpc_admin_opening_stock($1, null)`, [items([{ product_id: P, quantity: 20, unit_cost: 100 }])]);
await q(`select public.rpc_issue_stock_to_technician($1, $2, null)`, [TECH, items([{ product_id: P, quantity: 5 }])]);

console.log('\n== Paid in full, as before ==');
{
  const c0 = await till('cash');
  const s = await sell(ADMIN, { lines: [{ product_id: P, quantity: 1 }] });
  ok('a cash sale needs no customer', !!s.id);
  ok('the drawer takes the whole 200', await till('cash') === c0 + 200);
}

console.log('\n== Credit needs a customer ==');
{
  ok('آجل without a customer is refused', /DEFERRED_REQUIRES_CUSTOMER/.test(await sellErr(ADMIN, { method: 'deferred', lines: [{ product_id: P, quantity: 1 }] })));
  ok('part-paid without a customer is refused', /DEFERRED_REQUIRES_CUSTOMER/.test(await sellErr(ADMIN, { paid: 50, lines: [{ product_id: P, quantity: 1 }] })));
  ok('paying more than the total is refused', /PAYMENT_EXCEEDS_TOTAL/.test(await sellErr(ADMIN, { customer: CUST_A, paid: 500, lines: [{ product_id: P, quantity: 1 }] })));
  ok('آجل with money paid is refused', /INVALID_AMOUNT/.test(await sellErr(ADMIN, { customer: CUST_A, method: 'deferred', paid: 10, lines: [{ product_id: P, quantity: 1 }] })));
  ok('an unknown customer is refused', /CUSTOMER_NOT_FOUND/.test(await sellErr(ADMIN, { customer: uid(77), method: 'deferred', lines: [{ product_id: P, quantity: 1 }] })));
}

console.log('\n== آجل ==');
let creditSale;
{
  const c0 = await till('cash'), t0 = await till('transfer'), d0 = await debt();
  creditSale = (await sell(SALES, { customer: CUST_A, method: 'deferred', lines: [{ product_id: P, quantity: 2 }] })).id;
  ok('no till moves', await till('cash') === c0 && await till('transfer') === t0);
  ok('the customer owes 400', await debt() === d0 + 400);
  await asSuper();
  const s = await one(`select paid_amount, total, customer_id, customer_name from public.sales where id = $1`, [creditSale]);
  ok('the invoice: total 400, paid 0, the customer named', Number(s.total) === 400 && Number(s.paid_amount) === 0 && s.customer_id === CUST_A && s.customer_name === 'Cust A', JSON.stringify(s));
  await as(SALES);
  const summary = await one(`select remaining_balance from public.customer_account_summary where customer_id = $1`, [CUST_A]);
  ok('shows under ديون العملاء', Number(summary.remaining_balance) === d0 + 400);
}

console.log('\n== جزئي ==');
let partSale;
{
  const c0 = await till('cash'), d0 = await debt();
  partSale = (await sell(ADMIN, { customer: CUST_A, paid: 150, lines: [{ product_id: P, quantity: 2 }] })).id;
  ok('the drawer takes the 150 paid', await till('cash') === c0 + 150);
  ok('the customer owes the other 250', await debt() === d0 + 250);
}

console.log('\n== Returns cancel debt first ==');
{
  await asSuper();
  const line = await one(`select id from public.sale_items where sale_id = $1`, [creditSale]);
  const c0 = await till('cash'), d0 = await debt(), w0 = await whStock(P);
  await as(ADMIN);
  const e = await err(`select public.rpc_return_sale_item($1, 1, 'مرتجع')`, [line.id]);
  ok('returning one from the credit sale works', !e, e);
  ok('the debt drops 200', await debt() === d0 - 200);
  ok('no cash leaves the till', await till('cash') === c0);
  ok('the iron is back in the warehouse', await whStock(P) === w0 + 1);

  // Pay everything off, then return from the part-paid sale: cash refund.
  await as(ADMIN);
  await q(`select public.rpc_record_customer_payment($1, $2, null, 'سداد', null, 'cash')`, [CUST_A, await debt()]);
  ok('the customer is paid up', await debt() === 0);
  await asSuper();
  const pl = await one(`select id from public.sale_items where sale_id = $1`, [partSale]);
  const c1 = await till('cash');
  await as(ADMIN);
  await q(`select public.rpc_return_sale_item($1, 1, 'مرتجع')`, [pl.id]);
  ok('with nothing owed, the refund is cash', await till('cash') === c1 - 200 && await debt() === 0);
}

console.log('\n== Editing a credit invoice ==');
{
  const s = (await sell(ADMIN, { customer: CUST_A, method: 'deferred', lines: [{ product_id: P, quantity: 1 }] })).id;
  const d0 = await debt(), c0 = await till('cash');
  await as(ADMIN);
  let e = await err(`select public.rpc_admin_edit_sale($1, $2, 0, 'زيادة', null)`, [s, items([{ product_id: P, quantity: 3 }])]);
  ok('adding two more works', !e, e);
  ok('the customer owes 400 more, the till is untouched', await debt() === d0 + 400 && await till('cash') === c0);
  e = await err(`select public.rpc_admin_edit_sale($1, $2, 0, 'نقص', null)`, [s, items([{ product_id: P, quantity: 1 }])]);
  ok('taking two off works', !e, e);
  ok('the debt goes back down', await debt() === d0 && await till('cash') === c0);
}

console.log('\n== From a technician\'s bag ==');
{
  const b0 = await bagStock(P), w0 = await whStock(P), c0 = await till('cash');
  await asSuper();
  const due0 = Number((await one(`select amount_due from public.technician_account_summary where technician_id = $1`, [TECH])).amount_due);
  const s = await sell(SALES, { tech: TECH, lines: [{ product_id: P, quantity: 2, unit_price: 180 }] });
  ok('sales sells from the bag', !!s.id);
  ok('two leave the bag', await bagStock(P) === b0 - 2);
  ok('the warehouse is untouched', await whStock(P) === w0);
  ok('the shop till takes the re-priced 360', await till('cash') === c0 + 360);
  await asSuper();
  const row = await one(`select technician_id, source_bag_id from public.sales where id = $1`, [s.id]);
  ok('a shop sale (no technician) that records its bag', row.technician_id === null && row.source_bag_id !== null);
  const due1 = Number((await one(`select amount_due from public.technician_account_summary where technician_id = $1`, [TECH])).amount_due);
  ok('the technician owes nothing for it', due1 === due0);
  ok('more than the bag holds is refused', /INSUFFICIENT_STOCK/.test(await sellErr(ADMIN, { tech: TECH, lines: [{ product_id: P, quantity: 99 }] })));
  ok('a bag sale on credit works too', !(await sellErr(ADMIN, { tech: TECH, customer: CUST_A, method: 'deferred', lines: [{ product_id: P, quantity: 1 }] })));
  ok('an unknown technician is refused', /TECHNICIAN_BAG_NOT_FOUND/.test(await sellErr(ADMIN, { tech: uid(77), lines: [{ product_id: P, quantity: 1 }] })));
}

console.log('\n== Nobody else ==');
{
  ok('a technician cannot use the register', /FORBIDDEN/.test(await sellErr(TECH, { lines: [{ product_id: P, quantity: 1 }] })));
  ok('nor a customer', /FORBIDDEN/.test(await sellErr(CUST_A, { lines: [{ product_id: P, quantity: 1 }] })));
}

await asSuper();
finish();
