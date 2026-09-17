// tool/db_tests/phase13_wallet_test.mjs
//
// Phase 13 (0040): wallet — separate from customer_accounts, topped up via
// InstaPay (Phase 12), spent instantly and atomically, with the FOR UPDATE
// lock making two concurrent spends of the same balance impossible (master
// prompt's Wallet Race Conditions test).
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
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('W1', 'مكواة', 50, 100) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 20, 50, 'seed')`, [P]);

const createOrder = (customer) => as(customer).then(() => one(
  `select public.rpc_create_order($1, $2, $3, null, null) as id`,
  [customer, JSON.stringify([{ product_id: P, quantity: 1 }]), customer === CUST_B ? addrB : addrA]));
const wallet = async (customer) => { await as(customer); return one(`select public.rpc_get_my_wallet() as w`).then(r => r.w); };
const walletRow = async (customer) => { await asSuper(); return one(`select * from public.wallets where customer_id = $1 and currency = 'EGP'`, [customer]); };
const topup = (customer, amount, ref, path) => as(customer).then(() => one(
  `select public.rpc_wallet_topup_via_instapay($1, $2, $3) as id`,
  [amount, ref, path ?? `${customer}/proof.jpg`]));
const proofPath = (c) => `${c}/${Math.random().toString(36).slice(2)}.jpg`;

// ---------------------------------------------------------------- basics
console.log('\n== Getting a wallet ==');
let w = await wallet(CUST_A);
ok('a fresh wallet starts at 0 EGP', Number(w.balance) === 0 && w.currency === 'EGP');
await wallet(CUST_A);
await asSuper();
ok('calling it again does not create a second wallet',
  (await one(`select count(*)::int as n from public.wallets where customer_id = $1`, [CUST_A])).n === 1);

// ---------------------------------------------------------------- top-up via InstaPay
console.log('\n== Top-up via InstaPay ==');
const pay1 = await topup(CUST_A, 500, 'TOPUP-001', proofPath(CUST_A));
let payRow = await asSuper().then(() => one(`select * from public.payments where id = $1`, [pay1.id]));
ok('top-up creates a pending_verification, order-less payment', payRow.status === 'pending_verification' && payRow.order_id === null);
ok('purpose is recorded in metadata', payRow.metadata.purpose === 'wallet_topup');

w = await wallet(CUST_A);
ok('wallet is untouched until an admin verifies', Number(w.balance) === 0);

await as(ADMIN);
await q(`select public.rpc_admin_verify_instapay($1, true)`, [pay1.id]);
w = await wallet(CUST_A);
ok('wallet is credited once approved', Number(w.balance) === 500);

await asSuper();
const wRow = await walletRow(CUST_A);
const txn = await one(`select * from public.wallet_transactions where wallet_id = $1`, [wRow.id]);
ok('a ledger row explains the credit (balance_before/after)', txn.type === 'topup'
  && Number(txn.balance_before) === 0 && Number(txn.balance_after) === 500);

console.log('\n== A second top-up while one is pending is refused ==');
const pendingTopup = await topup(CUST_A, 100, 'TOPUP-002', proofPath(CUST_A));
ok('another submission while the first is pending is refused',
  (await as(CUST_A).then(() => err(`select public.rpc_wallet_topup_via_instapay(100, 'TOPUP-003', $1)`, [proofPath(CUST_A)])))?.includes('VERIFICATION_ALREADY_PENDING'));
// Resolve it (reject) so later tests in this file can submit their own
// top-ups without tripping the same guard.
await as(ADMIN);
await q(`select public.rpc_admin_verify_instapay($1, false, 'اختبار')`, [pendingTopup.id]);

// ---------------------------------------------------------------- spending
console.log('\n== Paying an order from the wallet ==');
const o1 = (await createOrder(CUST_A)).id;
await as(CUST_A);
await q(`select public.rpc_pay_order_from_wallet($1, $2)`, [o1, 100]);
w = await wallet(CUST_A);
ok('wallet debited by the order amount', Number(w.balance) === 400);
await asSuper();
const order1 = await one(`select * from public.orders where id = $1`, [o1]);
ok('order reflects the wallet payment (paid in full)', Number(order1.paid_amount) === 100 && order1.payment_status === 'paid');
const walletPay = await one(`select * from public.payments where order_id = $1 and channel = 'wallet'`, [o1]);
ok('a wallet payment is recorded as succeeded immediately (no admin review needed)', walletPay.status === 'succeeded' && walletPay.paid_at !== null);

console.log('\n== Insufficient balance is refused ==');
// A big order (total 1000) so the amount requested is within the order's
// own bound — the failure must come from the wallet balance (400), not
// AMOUNT_EXCEEDS_REMAINING.
const o2 = (await as(CUST_A).then(() => one(
  `select public.rpc_create_order($1, $2, $3, null, null) as id`,
  [CUST_A, JSON.stringify([{ product_id: P, quantity: 10 }]), addrA]))).id;
ok('cannot spend more than the wallet holds',
  (await as(CUST_A).then(() => err(`select public.rpc_pay_order_from_wallet($1, 1000)`, [o2])))?.includes('INSUFFICIENT_WALLET_BALANCE'));

console.log('\n== A customer with no wallet at all cannot spend one ==');
const oB = (await createOrder(CUST_B)).id;
ok('customer B (never topped up) gets INSUFFICIENT_WALLET_BALANCE, not a crash',
  (await as(CUST_B).then(() => err(`select public.rpc_pay_order_from_wallet($1, 50)`, [oB])))?.includes('INSUFFICIENT_WALLET_BALANCE'));

// ---------------------------------------------------------------- exclusive spending
// PGlite is a single connection, so it cannot exercise genuine concurrent
// transactions — that needs a real Postgres connection pool. The FOR UPDATE
// lock's actual concurrency guarantee is exercised live instead, by
// tool/hardening_check.dart's --run-race-test (same pattern as the existing
// stock race-condition test there). What IS meaningful here: spending more
// than the balance holds, across two sequential attempts, must never let
// the second one succeed once the first has consumed it.
console.log('\n== A balance cannot be spent twice, even sequentially ==');
const preTopup = Number((await wallet(CUST_A)).balance);
const pay2 = await topup(CUST_A, 80, 'TOPUP-SEQ', proofPath(CUST_A));
await as(ADMIN);
await q(`select public.rpc_admin_verify_instapay($1, true)`, [pay2.id]);
const spendable = Number((await wallet(CUST_A)).balance);
ok('wallet increased by exactly the top-up amount', spendable === preTopup + 80);

// Two orders each requiring the wallet's ENTIRE current balance — only one
// spend can possibly succeed.
const qty = Math.ceil(spendable / 100);
const bigOrder = () => as(CUST_A).then(() => one(
  `select public.rpc_create_order($1, $2, $3, null, null) as id`,
  [CUST_A, JSON.stringify([{ product_id: P, quantity: qty }]), addrA]));
const o3 = (await bigOrder()).id;
const o4 = (await bigOrder()).id;
await as(CUST_A);
await q(`select public.rpc_pay_order_from_wallet($1, $2)`, [o3, spendable]);
ok('the second spend of the same balance is refused once the first consumed it',
  (await err(`select public.rpc_pay_order_from_wallet($1, $2)`, [o4, spendable]))?.includes('INSUFFICIENT_WALLET_BALANCE'));
w = await wallet(CUST_A);
ok('final balance is 0, not negative and not double-spent', Number(w.balance) === 0);

// ---------------------------------------------------------------- immutability + isolation
console.log('\n== Ledger immutability and isolation ==');
await asSuper();
const anyTxn = await one(`select id from public.wallet_transactions limit 1`);
ok('a wallet transaction cannot be edited',
  (await err(`update public.wallet_transactions set amount = 999999 where id = $1`, [anyTxn.id]))?.includes('immutable'));
ok('a wallet transaction cannot be deleted',
  (await err(`delete from public.wallet_transactions where id = $1`, [anyTxn.id]))?.includes('immutable'));

await as(CUST_B);
ok('customer B cannot see customer A\'s wallet', (await q(`select id from public.wallets where customer_id = $1`, [CUST_A])).length === 0);
ok('customer B cannot see customer A\'s wallet transactions', (await q(`select * from public.wallet_transactions`)).length === 0);
ok('customer cannot write their own balance directly',
  (await err(`update public.wallets set balance = 999999 where customer_id = $1`, [CUST_B]))?.includes('permission denied'));
ok('customer cannot insert a wallet transaction directly',
  (await err(`insert into public.wallet_transactions (wallet_id, type, amount, balance_before, balance_after) values ($1, 'topup', 100, 0, 100)`, [anyTxn.id]))?.includes('permission denied'));

await as(ADMIN);
ok('admin can see every wallet', (await q(`select id from public.wallets`)).length >= 1);

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
