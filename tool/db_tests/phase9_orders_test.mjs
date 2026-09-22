// tool/db_tests/phase9_orders_test.mjs
//
// Phase 9 (0037): payment_status is independent of order status — advanced
// by payments, set to 'refunded' by a cancellation that hands cash back, and
// never writable by anyone except through those two RPCs.
//
//   cd tool/db_tests && npm install && npm test

import { setup, ADMIN, CUST_A } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

await as(ADMIN);
const cairo = (await one(`select id from public.cities where name_ar = 'القاهرة'`)).id;
await as(CUST_A);
const addrA = (await one(`select public.rpc_save_my_address(
  p_address_id => null, p_city_id => $1, p_label => 'المنزل', p_address_line => 'addr',
  p_latitude => 30.0561, p_longitude => 31.3301) as r`, [cairo])).r.id;

await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('O1', 'مكواة', 50, 100) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 20, 50, 'seed')`, [P]);
await q(`select public.rpc_cashbox_deposit(1000, 'float')`);

const createOrder = () => as(CUST_A).then(() => one(
  `select public.rpc_create_order($1, $2, $3, null, null) as id`,
  [CUST_A, JSON.stringify([{ product_id: P, quantity: 1 }]), addrA]));
const payOrder = (orderId, amount) => as(ADMIN).then(() => q(
  `select public.rpc_record_customer_payment($1, $2, $3, 'دفعة')`,
  [CUST_A, amount, orderId]));
const orderRow = async (id) => { await asSuper(); return one(`select * from public.orders where id = $1`, [id]); };

// ---------------------------------------------------------------- lifecycle
console.log('\n== A fresh order starts unpaid ==');
const o1 = (await createOrder()).id;
ok('new order is unpaid', (await orderRow(o1)).payment_status === 'unpaid');
ok('order status is independently pending', (await orderRow(o1)).status === 'pending');

console.log('\n== Partial payment advances to partially_paid, not paid ==');
await payOrder(o1, 40);
let row = await orderRow(o1);
ok('paid_amount tracks the payment', Number(row.paid_amount) === 40);
ok('payment_status is partially_paid', row.payment_status === 'partially_paid');
ok('order status is untouched by paying (still pending)', row.status === 'pending');

console.log('\n== Paying the remainder marks it paid ==');
await payOrder(o1, 60);
row = await orderRow(o1);
ok('paid in full', Number(row.paid_amount) === 100 && row.payment_status === 'paid');

console.log('\n== A second order paid in one shot goes straight to paid ==');
const o2 = (await createOrder()).id;
await payOrder(o2, 100);
ok('single full payment is paid, no partially_paid step needed', (await orderRow(o2)).payment_status === 'paid');

// ---------------------------------------------------------------- cancellation
console.log('\n== Cancelling an unpaid order leaves payment_status unpaid ==');
const o3 = (await createOrder()).id;
await as(ADMIN);
await q(`select public.rpc_cancel_order($1, 'العميل غيّر رأيه')`, [o3]);
row = await orderRow(o3);
ok('cancelled order status is cancelled', row.status === 'cancelled');
ok('an order nobody paid for is not "refunded"', row.payment_status === 'unpaid');

console.log('\n== Cancelling a paid order marks payment_status refunded ==');
const o4 = (await createOrder()).id;
await payOrder(o4, 100);
// 0065: confirming now requires an approved shipping fee first — zero,
// so it doesn't disturb this file's payment-total assertions.
await as(ADMIN);
await q(`select public.rpc_admin_set_shipping_fee($1, 0)`, [o4]);
await as(CUST_A);
await q(`select public.rpc_customer_respond_shipping_fee($1, true)`, [o4]);
await as(ADMIN);
await q(`select public.rpc_confirm_order($1)`, [o4]);
await q(`select public.rpc_cancel_order($1, 'نفاذ المخزون')`, [o4]);
row = await orderRow(o4);
ok('order status is cancelled', row.status === 'cancelled');
ok('payment status becomes refunded once cash goes back', row.payment_status === 'refunded');
ok('order and payment status disagree on purpose (cancelled + refunded is two different facts)',
  row.status === 'cancelled' && row.payment_status === 'refunded');

console.log('\n== Cancelling a partially paid order also refunds it ==');
const o5 = (await createOrder()).id;
await payOrder(o5, 30);
await as(ADMIN);
await q(`select public.rpc_cancel_order($1, 'إلغاء')`, [o5]);
ok('a partial payment still triggers refunded on cancel', (await orderRow(o5)).payment_status === 'refunded');

// ---------------------------------------------------------------- no direct writes
console.log('\n== payment_status is never directly writable ==');
await as(CUST_A);
ok('customer cannot set their own order to paid',
  (await err(`update public.orders set payment_status = 'paid' where id = $1`, [o1]))?.includes('permission denied'));
await as(ADMIN);
ok('admin cannot set payment_status by direct UPDATE either (RPC-only, same as status)',
  (await err(`update public.orders set payment_status = 'paid' where id = $1`, [o3]))?.includes('permission denied'));

// ---------------------------------------------------------------- grants
console.log('\n== Grants ==');
await asSuper();
const leaked = await q(`
  select p.oid::regprocedure::text as f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind = 'f'
    and not exists (select 1 from pg_depend d where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
    and (has_function_privilege('anon', p.oid, 'execute')
         or (has_function_privilege('authenticated', p.oid, 'execute')
             and p.proname not in (select function_name from private.rpc_allowlist)))`);
ok('no function executable beyond the allowlist', leaked.length === 0, JSON.stringify(leaked));

finish();
