// tool/db_tests/phase17_order_shipping_fee_test.mjs
//
// 0065: admin/sales must propose a shipping fee on a pending order, and the
// customer must explicitly approve it before rpc_confirm_order will
// succeed at all. orders.total only counts the fee once approved — a
// merely-proposed or rejected fee never changes what the customer owes.
//
//   cd tool/db_tests && npm install && npm test

import { setup, ADMIN, CUST_A, CUST_B } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

await as(ADMIN);
const cairo = (await one(`select id from public.cities where name_ar = 'القاهرة'`)).id;
const addrA = (await as(CUST_A).then(() => one(`select public.rpc_save_my_address(
  p_address_id => null, p_city_id => $1, p_label => 'المنزل', p_address_line => 'addr',
  p_latitude => 30.0561, p_longitude => 31.3301) as r`, [cairo]))).r.id;

await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('SF1', 'مكواة', 50, 100) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 20, 50, 'seed')`, [P]);

const createOrder = () => as(CUST_A).then(() => one(
  `select public.rpc_create_order($1, $2, $3, null, null) as id`,
  [CUST_A, JSON.stringify([{ product_id: P, quantity: 1 }]), addrA]));
const orderRow = async (id) => { await asSuper(); return one(`select * from public.orders where id = $1`, [id]); };

// ---------------------------------------------------------------- proposing does not change what's owed yet
console.log('\n== Proposing a shipping fee does not change the total until approved ==');
const o1 = (await createOrder()).id;
ok('fresh order total is just the product price', Number((await orderRow(o1)).total) === 100);
await as(ADMIN);
await q(`select public.rpc_admin_set_shipping_fee($1, 25)`, [o1]);
let row = await orderRow(o1);
ok('shipping_fee is recorded', Number(row.shipping_fee) === 25);
ok('status is pending_approval', row.shipping_fee_status === 'pending_approval');
ok('total is untouched while pending approval', Number(row.total) === 100);

// ---------------------------------------------------------------- confirming is blocked until approved
console.log('\n== Confirming is refused until the customer approves ==');
ok('confirm refused: SHIPPING_FEE_NOT_APPROVED',
  (await as(ADMIN).then(() => err(`select public.rpc_confirm_order($1)`, [o1])))?.includes('SHIPPING_FEE_NOT_APPROVED'));

// ---------------------------------------------------------------- only the order's own customer can respond
console.log('\n== Only the order\'s own customer can respond ==');
ok('another customer responding is refused',
  (await as(CUST_B).then(() => err(`select public.rpc_customer_respond_shipping_fee($1, true)`, [o1])))?.includes('ORDER_CUSTOMER_MISMATCH'));
ok('rejecting without a reason is refused',
  (await as(CUST_A).then(() => err(`select public.rpc_customer_respond_shipping_fee($1, false)`, [o1])))?.includes('REASON_REQUIRED'));

// ---------------------------------------------------------------- approval
console.log('\n== Approving folds the fee into the total, and unblocks confirm ==');
await as(CUST_A);
await q(`select public.rpc_customer_respond_shipping_fee($1, true)`, [o1]);
row = await orderRow(o1);
ok('status is approved', row.shipping_fee_status === 'approved');
ok('total now includes the fee (100 + 25)', Number(row.total) === 125);
ok('re-responding once already approved is refused',
  (await as(CUST_A).then(() => err(`select public.rpc_customer_respond_shipping_fee($1, true)`, [o1])))?.includes('SHIPPING_FEE_NOT_PENDING'));

await as(ADMIN);
await q(`select public.rpc_confirm_order($1)`, [o1]);
row = await orderRow(o1);
ok('order confirms successfully once approved', row.status === 'confirmed');
ok('the customer was charged the full 125 (product + shipping)',
  (await one(`select amount from public.customer_account_transactions where order_id = $1 and transaction_type = 'order_charge'`, [o1])).amount == 125);

// ---------------------------------------------------------------- rejection
console.log('\n== Rejecting a fee keeps the total unchanged and lets admin re-propose ==');
const o2 = (await createOrder()).id;
await as(ADMIN);
await q(`select public.rpc_admin_set_shipping_fee($1, 50)`, [o2]);
await as(CUST_A);
await q(`select public.rpc_customer_respond_shipping_fee($1, false, 'غالي أوي')`, [o2]);
row = await orderRow(o2);
ok('status is rejected', row.shipping_fee_status === 'rejected');
ok('the rejection reason is recorded', row.shipping_fee_rejection_reason === 'غالي أوي');
ok('the rejected amount is still visible for admin reference', Number(row.shipping_fee) === 50);
ok('total is untouched by a rejected fee', Number(row.total) === 100);
ok('confirming a rejected order is still refused',
  (await as(ADMIN).then(() => err(`select public.rpc_confirm_order($1)`, [o2])))?.includes('SHIPPING_FEE_NOT_APPROVED'));

await as(ADMIN);
await q(`select public.rpc_admin_set_shipping_fee($1, 30)`, [o2]);
row = await orderRow(o2);
ok('re-proposing resets to pending_approval', row.shipping_fee_status === 'pending_approval');
ok('re-proposing clears the old rejection reason', row.shipping_fee_rejection_reason === null);
ok('re-proposing updates the amount', Number(row.shipping_fee) === 30);

// ---------------------------------------------------------------- validation
console.log('\n== Validation ==');
ok('a negative amount is refused',
  (await as(ADMIN).then(() => err(`select public.rpc_admin_set_shipping_fee($1, -5)`, [o2])))?.includes('INVALID_AMOUNT'));
ok('a customer cannot set a shipping fee',
  (await as(CUST_A).then(() => err(`select public.rpc_admin_set_shipping_fee($1, 10)`, [o2])))?.includes('FORBIDDEN'));
const o3 = (await createOrder()).id;
ok('cannot confirm without ever proposing a fee',
  (await as(ADMIN).then(() => err(`select public.rpc_confirm_order($1)`, [o3])))?.includes('SHIPPING_FEE_NOT_APPROVED'));
ok('responding with nothing pending is refused',
  (await as(CUST_A).then(() => err(`select public.rpc_customer_respond_shipping_fee($1, true)`, [o3])))?.includes('SHIPPING_FEE_NOT_PENDING'));

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
