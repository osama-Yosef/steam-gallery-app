// tool/db_tests/phase14_refunds_test.mjs
//
// Phase 14 (0041): channel-aware refunds. Before this, rpc_cancel_order
// always pulled the full paid_amount out of the physical cashbox — wrong for
// any order paid via wallet or InstaPay (Phase 12/13), neither of which ever
// puts money in the cashbox. private.fn_apply_order_refund now splits the
// refund by the channel that actually paid: wallet payments go back to the
// wallet, InstaPay payments become wallet store credit (no automated bank
// reversal exists), and only the leftover manually-recorded cash portion
// touches the cashbox. rpc_admin_return_order is the same machinery for a
// post-delivery return instead of a pre-fulfilment cancellation.
//
//   cd tool/db_tests && npm install && npm test

import { setup, ADMIN, CUST_A, CUST_B } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

await as(ADMIN);
const cairo = (await one(`select id from public.cities where name_ar = 'القاهرة'`)).id;
const saveAddress = (customer) => as(customer).then(() => one(
  `select public.rpc_save_my_address(
     p_address_id => null, p_city_id => $1, p_label => 'المنزل', p_address_line => 'addr',
     p_latitude => 30.0561, p_longitude => 31.3301) as r`, [cairo])).then(r => r.r.id);
const addrA = await saveAddress(CUST_A);
const addrB = await saveAddress(CUST_B);

await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('R1', 'مكواة', 50, 100) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 200, 50, 'seed')`, [P]);
await q(`select public.rpc_cashbox_deposit(1000, 'float')`);

const cashboxBalance = async () => {
  await asSuper();
  return Number((await one(`select coalesce(sum(amount), 0)::numeric as b from public.cash_transactions`)).b);
};
const createOrder = (customer, addr, qty = 1) => as(customer).then(() => one(
  `select public.rpc_create_order($1, $2, $3, null, null) as id`,
  [customer, JSON.stringify([{ product_id: P, quantity: qty }]), addr]));
const orderRow = async (id) => { await asSuper(); return one(`select * from public.orders where id = $1`, [id]); };
const wallet = async (customer) => { await as(customer); return one(`select public.rpc_get_my_wallet() as w`).then(r => r.w); };
const topupAndVerify = async (customer, amount, ref) => {
  const p = await as(customer).then(() => one(
    `select public.rpc_wallet_topup_via_instapay($1, $2, $3) as id`,
    [amount, ref, `${customer}/${Math.random().toString(36).slice(2)}.jpg`]));
  await as(ADMIN);
  await q(`select public.rpc_admin_verify_instapay($1, true)`, [p.id]);
};
const payFromWallet = (customer, orderId, amount) => as(customer).then(() => q(
  `select public.rpc_pay_order_from_wallet($1, $2)`, [orderId, amount]));
const payViaInstapayAndVerify = async (customer, orderId, amount, ref) => {
  const p = await as(customer).then(() => one(
    `select public.rpc_submit_instapay_payment($1, $2, $3, $4) as id`,
    [orderId, amount, ref, `${customer}/${Math.random().toString(36).slice(2)}.jpg`]));
  await as(ADMIN);
  await q(`select public.rpc_admin_verify_instapay($1, true)`, [p.id]);
  return p.id;
};
const cancelOrder = (orderId, reason = 'اختبار') => as(ADMIN).then(() => q(
  `select public.rpc_cancel_order($1, $2)`, [orderId, reason]));
const returnOrder = (orderId, reason = 'اختبار استرجاع') => as(ADMIN).then(() => q(
  `select public.rpc_admin_return_order($1, $2)`, [orderId, reason]));
const advanceToDelivered = async (orderId) => {
  await as(ADMIN);
  await q(`select public.rpc_confirm_order($1)`, [orderId]);
  await q(`select public.rpc_update_order_status($1, 'preparing')`, [orderId]);
  await q(`select public.rpc_update_order_status($1, 'delivered')`, [orderId]);
};

// ---------------------------------------------------------------- wallet-paid cancellation
console.log('\n== Cancelling a wallet-paid order refunds the wallet, not the cashbox ==');
await topupAndVerify(CUST_A, 500, 'REF-A-1');
const o1 = (await createOrder(CUST_A, addrA)).id;
await as(ADMIN);
await q(`select public.rpc_confirm_order($1)`, [o1]);
await payFromWallet(CUST_A, o1, 100);
let w = await wallet(CUST_A);
ok('wallet debited by the order amount', Number(w.balance) === 400);
const cashBefore1 = await cashboxBalance();

await cancelOrder(o1, 'نفاذ المخزون');
let row = await orderRow(o1);
ok('order is cancelled and payment_status is refunded', row.status === 'cancelled' && row.payment_status === 'refunded');
w = await wallet(CUST_A);
ok('wallet balance is restored (refunded, not the cashbox)', Number(w.balance) === 500);
ok('the cashbox is untouched by a wallet refund', await cashboxBalance() === cashBefore1);

await asSuper();
const walletPayRow = await one(`select * from public.payments where order_id = $1 and channel = 'wallet'`, [o1]);
ok('the wallet payment row itself is marked refunded', walletPayRow.status === 'refunded');
const refundTxn = await one(
  `select * from public.wallet_transactions where reference_type = 'order' and reference_id = $1 and type = 'refund_credit'`, [o1]);
ok('a refund_credit ledger row explains the credit', Number(refundTxn.amount) === 100);

// ---------------------------------------------------------------- InstaPay-paid cancellation
console.log('\n== Cancelling an InstaPay-paid order credits the wallet as store credit ==');
const o2 = (await createOrder(CUST_B, addrB)).id;
await as(ADMIN);
await q(`select public.rpc_confirm_order($1)`, [o2]);
const instapayPaymentId = await payViaInstapayAndVerify(CUST_B, o2, 100, 'REF-B-1');
const cashBefore2 = await cashboxBalance();

await cancelOrder(o2, 'العميل غيّر رأيه');
row = await orderRow(o2);
ok('order is cancelled and payment_status is refunded', row.status === 'cancelled' && row.payment_status === 'refunded');
const wB = await wallet(CUST_B);
ok('a customer with no prior wallet gets one, credited with the InstaPay amount', Number(wB.balance) === 100);
ok('the cashbox is untouched — the money never physically arrived there', await cashboxBalance() === cashBefore2);

await asSuper();
const instapayPayRow = await one(`select * from public.payments where id = $1`, [instapayPaymentId]);
ok('the InstaPay payment row is marked refunded', instapayPayRow.status === 'refunded');

// ---------------------------------------------------------------- cash-paid cancellation unaffected
console.log('\n== A manually-recorded cash payment still refunds through the physical cashbox ==');
const o3 = (await createOrder(CUST_A, addrA)).id;
await as(ADMIN);
await q(`select public.rpc_confirm_order($1)`, [o3]);
await q(`select public.rpc_record_customer_payment($1, $2, $3, 'كاش')`, [CUST_A, 100, o3]);
const cashBefore3 = await cashboxBalance();
await cancelOrder(o3, 'إلغاء');
ok('the cashbox balance drops by the refunded cash amount', await cashboxBalance() === cashBefore3 - 100);
await asSuper();
ok('a cash refund row references the order',
  (await one(`select * from public.cash_transactions where reference_type = 'order' and reference_id = $1 and transaction_type = 'refund'`, [o3])).amount == -100);

// ---------------------------------------------------------------- mixed-channel cancellation
console.log('\n== A partly-wallet, partly-cash order splits the refund correctly ==');
const o4 = (await createOrder(CUST_A, addrA)).id;
await as(ADMIN);
await q(`select public.rpc_confirm_order($1)`, [o4]);
await payFromWallet(CUST_A, o4, 40);
await as(ADMIN);
await q(`select public.rpc_record_customer_payment($1, $2, $3, 'كاش')`, [CUST_A, 60, o4]);
row = await orderRow(o4);
ok('order paid in full across two channels', Number(row.paid_amount) === 100 && row.payment_status === 'paid');
const walletBeforeMixed = Number((await wallet(CUST_A)).balance);
const cashBeforeMixed = await cashboxBalance();

await cancelOrder(o4, 'إلغاء مختلط');
ok('the wallet portion (40) comes back to the wallet',
  Number((await wallet(CUST_A)).balance) === walletBeforeMixed + 40);
ok('the cash portion (60) comes back out of the cashbox',
  await cashboxBalance() === cashBeforeMixed - 60);

// ---------------------------------------------------------------- post-delivery return
console.log('\n== Returning a delivered order (rpc_admin_return_order) ==');
await topupAndVerify(CUST_A, 300, 'REF-A-2');
const o5 = (await createOrder(CUST_A, addrA, 2)).id;
await as(ADMIN);
await q(`select public.rpc_confirm_order($1)`, [o5]);
await payFromWallet(CUST_A, o5, 200);

ok('cannot return an order that has not been delivered yet',
  (await as(ADMIN).then(() => err(`select public.rpc_admin_return_order($1, 'مبكر')`, [o5])))?.includes('ORDER_NOT_RETURNABLE'));

await as(ADMIN);
await q(`select public.rpc_update_order_status($1, 'preparing')`, [o5]);
await q(`select public.rpc_update_order_status($1, 'delivered')`, [o5]);
const walletBeforeReturn = Number((await wallet(CUST_A)).balance);
await asSuper();
const stockBefore = (await one(
  `select coalesce(sum(quantity), 0)::int as n from public.stock_movements where product_id = $1 and movement_type = 'return_from_customer'`, [P])).n;

await returnOrder(o5, 'المنتج به عيب');
row = await orderRow(o5);
ok('order status becomes returned', row.status === 'returned');
ok('payment status becomes refunded', row.payment_status === 'refunded');
ok('wallet is credited back the paid amount', Number((await wallet(CUST_A)).balance) === walletBeforeReturn + 200);

await asSuper();
const stockAfter = (await one(
  `select coalesce(sum(quantity), 0)::int as n from public.stock_movements where product_id = $1 and movement_type = 'return_from_customer'`, [P])).n;
ok('the returned items are restocked to the main warehouse', stockAfter === stockBefore + 2);
ok('a return_credit transaction is recorded against the customer account',
  (await one(`select * from public.customer_account_transactions where order_id = $1 and transaction_type = 'return_credit'`, [o5])).amount == -row.total);

console.log('\n== A returned or cancelled order cannot be returned again ==');
ok('returning an already-returned order is refused',
  (await as(ADMIN).then(() => err(`select public.rpc_admin_return_order($1, 'مرتين')`, [o5])))?.includes('ORDER_NOT_RETURNABLE'));
ok('returning a cancelled order is refused',
  (await as(ADMIN).then(() => err(`select public.rpc_admin_return_order($1, 'ملغي')`, [o1])))?.includes('ORDER_NOT_RETURNABLE'));

console.log('\n== A customer cannot return their own order ==');
const o6 = (await createOrder(CUST_A, addrA)).id;
await advanceToDelivered(o6);
ok('only an admin can call rpc_admin_return_order',
  (await as(CUST_A).then(() => err(`select public.rpc_admin_return_order($1, 'أنا أرجعت')`, [o6])))?.includes('FORBIDDEN'));

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
const privateLeaked = await q(`
  select p.oid::regprocedure::text as f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'private' and p.prokind = 'f' and p.proname = 'fn_apply_order_refund'
    and (has_function_privilege('anon', p.oid, 'execute') or has_function_privilege('authenticated', p.oid, 'execute'))`);
ok('the internal refund helper is not directly callable by anon or authenticated', privateLeaked.length === 0, JSON.stringify(privateLeaked));

finish();
