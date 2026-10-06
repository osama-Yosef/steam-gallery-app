// tool/db_tests/phase18_invoice_edit_assembly_purchase_test.mjs
//
// 0075: editable/deletable walk-in invoices, assembly products, purchase
// invoices with suppliers and deferred payment.
//
//   cd tool/db_tests && npm install && node phase18_invoice_edit_assembly_purchase_test.mjs

import { randomUUID } from 'node:crypto';
import { setup, ADMIN, TECH } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

const till = async (kind) => {
  await asSuper();
  const r = await one(
    `select coalesce(sum(ct.amount), 0)::numeric as b
     from public.cash_transactions ct join public.cashboxes cb on cb.id = ct.cashbox_id
     where cb.kind = $1 and cb.is_active`, [kind]);
  await as(ADMIN);
  return Number(r.b);
};
const stock = async (productId) => {
  await asSuper();
  const r = await one(`select coalesce(sum(quantity), 0)::int as q from public.warehouse_stock where product_id = $1`, [productId]);
  await as(ADMIN);
  return r.q;
};
const sale = async (id) => one(`select subtotal::numeric, discount::numeric, total::numeric, paid_amount::numeric, status from public.sales where id = $1`, [id]);
const held = async (id) => Number((await one(
  `select coalesce(sum(amount), 0)::numeric as h from public.cash_transactions where reference_type = 'sale' and reference_id = $1`, [id])).h);

await as(ADMIN);
const mk = async (sku, name, cost, price) =>
  (await one(`insert into public.products (sku, name, cost_price, selling_price) values ($1, $2, $3, $4) returning id`, [sku, name, cost, price])).id;
const A = await mk('E1', 'مكواة', 50, 100);
const B = await mk('E2', 'خرطوم', 10, 30);
const C = await mk('E3', 'فلتر', 5, 20);
for (const p of [A, B, C]) await q(`select public.rpc_receive_purchase($1, 20, (select cost_price from public.products where id = $1), 'seed')`, [p]);
await q(`select public.rpc_cashbox_deposit(1000, 'float', 'cash')`);
await q(`select public.rpc_cashbox_deposit(1000, 'float', 'transfer')`);

const walkIn = async (items, discount = 0, method = 'cash') =>
  (await one(`select public.rpc_admin_walk_in_sale(null, null, $1, $2, $3, $4, null) as id`,
    [JSON.stringify(items), method, discount, randomUUID()])).id;

// ------------------------------------------------------------------ edit
console.log('\n== Editing an invoice: more of one, remove another, add a new one ==');
{
  const cash0 = await till('cash');
  const s = await walkIn([{ product_id: A, quantity: 2 }, { product_id: B, quantity: 1 }]);
  ok('sale credited 230', await till('cash') === cash0 + 230);
  const sA = await stock(A), sB = await stock(B), sC = await stock(C);

  await q(`select public.rpc_admin_edit_sale($1, $2, null, 'تعديل')`,
    [s, JSON.stringify([{ product_id: A, quantity: 3 }, { product_id: C, quantity: 2 }])]);
  const row = await sale(s);
  ok('total is now 3*100 + 2*20 = 340', Number(row.total) === 340, JSON.stringify(row));
  ok('paid_amount follows the total', Number(row.paid_amount) === 340);
  ok('cash ledger for the sale holds 340', await held(s) === 340);
  ok('cash till moved by +110', await till('cash') === cash0 + 340);
  ok('A stock -1', await stock(A) === sA - 1);
  ok('B restocked', await stock(B) === sB + 1);
  ok('C stock -2', await stock(C) === sC - 2);
  ok('still completed', row.status === 'completed');

  // Replaying the same edit (offline queue retry) changes nothing.
  await q(`select public.rpc_admin_edit_sale($1, $2, null, 'تعديل')`,
    [s, JSON.stringify([{ product_id: A, quantity: 3 }, { product_id: C, quantity: 2 }])]);
  ok('replay is a no-op (cash)', await till('cash') === cash0 + 340);
  ok('replay is a no-op (stock)', await stock(A) === sA - 1);

  // Lower quantity + discount.
  await q(`select public.rpc_admin_edit_sale($1, $2, 40, 'خصم')`,
    [s, JSON.stringify([{ product_id: A, quantity: 1 }, { product_id: C, quantity: 2 }])]);
  const row2 = await sale(s);
  ok('total = 140 - 40 = 100', Number(row2.total) === 100, JSON.stringify(row2));
  ok('cash ledger for the sale holds 100', await held(s) === 100);
  ok('till nets to +100', await till('cash') === cash0 + 100);

  ok('emptying the invoice through edit is refused', /EMPTY_ORDER/.test(await err(
    `select public.rpc_admin_edit_sale($1, '[]', null, 'x')`, [s]) ?? ''));
  ok('more than in stock is refused', /INSUFFICIENT_STOCK/.test(await err(
    `select public.rpc_admin_edit_sale($1, $2, null, 'x')`, [s, JSON.stringify([{ product_id: A, quantity: 999 }])]) ?? ''));

  // Partial return through the old screen keeps total == ledger.
  const item = await one(`select id from public.sale_items_with_returns where sale_id = $1 and product_id = $2 and returned_quantity < quantity limit 1`, [s, C]);
  await q(`select public.rpc_return_sale_item($1, 1, 'مرتجع', 'cash')`, [item.id]);
  const row3 = await sale(s);
  ok('after a line return, total still equals the cash held', Number(row3.total) === await held(s), `${row3.total} vs ${await held(s)}`);

  // Delete.
  await q(`select public.rpc_admin_delete_sale($1, 'حذف', 'cash')`, [s]);
  ok('deleted invoice is cancelled', (await sale(s)).status === 'cancelled');
  ok('all money back out', await held(s) === 0);
  ok('till back to baseline', await till('cash') === cash0);
  await q(`select public.rpc_admin_delete_sale($1, 'حذف', 'cash')`, [s]);
  ok('delete replay is a no-op', await till('cash') === cash0);
  ok('editing a cancelled invoice is refused', /SALE_NOT_EDITABLE/.test(await err(
    `select public.rpc_admin_edit_sale($1, $2, null, 'x')`, [s, JSON.stringify([{ product_id: A, quantity: 1 }])]) ?? ''));
}

console.log('\n== Sale-level discount keeps returns consistent ==');
{
  const s = await walkIn([{ product_id: A, quantity: 2 }, { product_id: B, quantity: 2 }], 26);
  const lines = await q(`select id, product_id from public.sale_items where sale_id = $1`, [s]);
  for (const l of lines) await q(`select public.rpc_return_sale_item($1, 1, 'r', 'cash')`, [l.id]);
  const r = await sale(s);
  ok('total == held after two partial returns with a discount', Number(r.total) === await held(s), `${r.total} vs ${await held(s)}`);
  for (const l of lines) await q(`select public.rpc_return_sale_item($1, 1, 'r', 'cash')`, [l.id]);
  ok('fully returned -> returned, nothing held', (await sale(s)).status === 'returned' && await held(s) === 0);
}

// ------------------------------------------------------------------ assembly
console.log('\n== Assembly products ==');
{
  const K = await mk('K1', 'طقم مكواة', 0, 150);
  await q(`select public.rpc_admin_set_assembly($1, true, $2)`, [K, JSON.stringify([{ product_id: A, quantity: 1 }, { product_id: C, quantity: 2 }])]);
  const k = await one(`select is_assembly, cost_price::numeric from public.products where id = $1`, [K]);
  ok('flagged as assembly, cost = 50 + 2*5', k.is_assembly === true && Number(k.cost_price) === 60);
  const avail = await one(`select available from public.assembly_availability where product_id = $1`, [K]);
  const sA = await stock(A), sC = await stock(C);
  ok('availability = min(A/1, C/2)', avail.available === Math.min(sA, Math.floor(sC / 2)), JSON.stringify(avail));

  const s = await walkIn([{ product_id: K, quantity: 2 }]);
  ok('selling 2 kits takes 2 A', await stock(A) === sA - 2);
  ok('… and 4 C', await stock(C) === sC - 4);
  const line = await one(`select id, unit_cost_snapshot::numeric, components from public.sale_items where sale_id = $1`, [s]);
  ok('line cost = component cost', Number(line.unit_cost_snapshot) === 60);
  ok('components snapshotted', Array.isArray(line.components) && line.components.length === 2);

  await q(`select public.rpc_return_sale_item($1, 1, 'r', 'cash')`, [line.id]);
  ok('returning a kit restocks its components', await stock(A) === sA - 1 && await stock(C) === sC - 2);

  // Short component blocks the sale with its name.
  await asSuper();
  const wh = (await one(`select id from public.warehouses where type = 'main' and is_active limit 1`)).id;
  const cLeft = await one(`select quantity from public.warehouse_stock where product_id = $1`, [C]);
  await q(`insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, created_by)
           values ($1, 'damage', $2, 'warehouse', $3, 'external', 5, $4)`, [C, cLeft.quantity, wh, ADMIN]);
  await as(ADMIN);
  const e = await err(`select public.rpc_admin_walk_in_sale(null, null, $1, 'cash', 0, $2, null)`,
    [JSON.stringify([{ product_id: K, quantity: 1 }]), randomUUID()]);
  ok('sale refused when a component is missing, naming it', /INSUFFICIENT_COMPONENT: فلتر/.test(e ?? ''), e);
  ok('nothing taken from A on refusal', await stock(A) === sA - 1);

  ok('a service cannot be a component', /INVALID_COMPONENT/.test(await err(
    `select public.rpc_admin_set_assembly($1, true, $2)`,
    [K, JSON.stringify([{ product_id: (await one(`select id from public.products where is_service limit 1`)).id, quantity: 1 }])]) ?? ''));
  ok('purchase invoice refuses an assembly product', /NOT_A_STOCK_PRODUCT/.test(await err(
    `select public.rpc_create_purchase_invoice(null, 'مورد', null, $1, 0, 0, null, null, null, null, $2)`,
    [JSON.stringify([{ product_id: K, quantity: 1, unit_cost: 1 }]), randomUUID()]) ?? ''));
}

// ------------------------------------------------------------------ purchase invoices
console.log('\n== Purchase invoices ==');
{
  const cash0 = await till('cash'), transfer0 = await till('transfer');
  const sA = await stock(A), sB = await stock(B);
  const req = randomUUID();
  const inv = (await one(
    `select public.rpc_create_purchase_invoice(null, 'الأمل للتوريدات', '0100', $1, 10, 100, 'transfer', null, 'F-77', null, $2) as id`,
    [JSON.stringify([{ product_id: A, quantity: 5, unit_cost: 55 }, { product_id: B, quantity: 10, unit_cost: 12 }]), req])).id;
  const summary = await one(`select total::numeric, paid_amount::numeric, remaining_amount::numeric, supplier_name from public.purchase_invoices_summary where id = $1`, [inv]);
  ok('total = 275 + 120 - 10 = 385', Number(summary.total) === 385, JSON.stringify(summary));
  ok('paid 100, remaining 285 (partly deferred)', Number(summary.paid_amount) === 100 && Number(summary.remaining_amount) === 285);
  ok('supplier created from name', summary.supplier_name === 'الأمل للتوريدات');
  ok('stock in', await stock(A) === sA + 5 && await stock(B) === sB + 10);
  ok('cost price updated', Number((await one(`select cost_price::numeric from public.products where id = $1`, [A])).cost_price) === 55);
  ok('transfer till paid 100', await till('transfer') === transfer0 - 100);
  ok('cash till untouched', await till('cash') === cash0);

  const again = (await one(
    `select public.rpc_create_purchase_invoice(null, 'الأمل للتوريدات', null, $1, 10, 100, 'transfer', null, null, null, $2) as id`,
    [JSON.stringify([{ product_id: A, quantity: 5, unit_cost: 55 }]), req])).id;
  ok('same client_request_id returns the same invoice', again === inv);
  ok('… without paying twice', await till('transfer') === transfer0 - 100);

  const supplierId = (await one(`select supplier_id from public.purchase_invoices where id = $1`, [inv])).supplier_id;
  const inv2 = (await one(
    `select public.rpc_create_purchase_invoice($1, null, null, $2, 0, 0, null, null, null, null, $3) as id`,
    [supplierId, JSON.stringify([{ product_id: C, quantity: 4, unit_cost: 5 }]), randomUUID()])).id;
  let bal = await one(`select balance::numeric from public.supplier_balances where supplier_id = $1`, [supplierId]);
  ok('fully deferred invoice adds to the supplier balance', Number(bal.balance) === 305);

  const payReq = randomUUID();
  await q(`select public.rpc_pay_supplier($1, 290, 'cash', null, 'سداد', $2)`, [supplierId, payReq]);
  await q(`select public.rpc_pay_supplier($1, 290, 'cash', null, 'سداد', $2)`, [supplierId, payReq]);
  ok('payment out of the cash till, once', await till('cash') === cash0 - 290);
  const r1 = await one(`select remaining_amount::numeric from public.purchase_invoices_summary where id = $1`, [inv]);
  const r2 = await one(`select remaining_amount::numeric from public.purchase_invoices_summary where id = $1`, [inv2]);
  ok('oldest invoice settled first', Number(r1.remaining_amount) === 0 && Number(r2.remaining_amount) === 15);
  ok('overpaying is refused', /AMOUNT_EXCEEDS_BALANCE/.test(await err(
    `select public.rpc_pay_supplier($1, 16, 'cash', null, null, $2)`, [supplierId, randomUUID()]) ?? ''));
  ok('paying more than the till holds is refused', /INSUFFICIENT_CASH/.test(await err(
    `select public.rpc_create_purchase_invoice($1, null, null, $2, 0, 999999, 'cash', null, null, null, $3)`,
    [supplierId, JSON.stringify([{ product_id: C, quantity: 1, unit_cost: 999999 }]), randomUUID()]) ?? ''));

  await as(TECH);
  ok('a technician cannot create purchase invoices', /FORBIDDEN/.test(await err(
    `select public.rpc_create_purchase_invoice(null, 'x', null, $1, 0, 0, null, null, null, null, null)`,
    [JSON.stringify([{ product_id: C, quantity: 1, unit_cost: 1 }])]) ?? ''));
  ok('a technician cannot see suppliers', (await q(`select * from public.suppliers`)).length === 0);
  await as(ADMIN);
}

// ------------------------------------------------------------------ offline replay (0076)
console.log('\n== rpc_replay runs a non-idempotent RPC once per request id ==');
{
  const cash0 = await till('cash');
  const id = randomUUID();
  const params = JSON.stringify({ p_amount: 75, p_notes: 'إيداع أوفلاين', p_kind: 'cash' });
  const first = await one(`select public.rpc_replay($1, 'rpc_cashbox_deposit', $2) as r`, [id, params]);
  const second = await one(`select public.rpc_replay($1, 'rpc_cashbox_deposit', $2) as r`, [id, params]);
  ok('first call runs', first.r.replayed === false);
  ok('second call is a no-op', second.r.replayed === true);
  ok('deposited once', await till('cash') === cash0 + 75);

  const failId = randomUUID();
  const tooMuch = JSON.stringify({ p_amount: 99999999, p_notes: 'x', p_kind: 'cash' });
  ok('a failing call raises', /INSUFFICIENT_CASH/.test(await err(`select public.rpc_replay($1, 'rpc_cashbox_withdraw', $2)`, [failId, tooMuch]) ?? ''));
  const okAmount = JSON.stringify({ p_amount: 5, p_notes: 'x', p_kind: 'cash' });
  const retried = await one(`select public.rpc_replay($1, 'rpc_cashbox_withdraw', $2) as r`, [failId, okAmount]);
  ok('… and does not burn its request id', retried.r.replayed === false && await till('cash') === cash0 + 70);

  ok('unknown RPCs are refused', /UNSUPPORTED_RPC/.test(await err(`select public.rpc_replay($1, 'rpc_admin_set_role', '{}')`, [randomUUID()]) ?? ''));
  await as(TECH);
  ok('wrapped RPCs keep their own role check', /FORBIDDEN/.test(await err(`select public.rpc_replay($1, 'rpc_cashbox_deposit', $2)`, [randomUUID(), params]) ?? ''));
  await as(ADMIN);
}

finish();
