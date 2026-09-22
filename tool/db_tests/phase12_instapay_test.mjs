// tool/db_tests/phase12_instapay_test.mjs
//
// Phase 12 (0039): InstaPay manual verification — a customer can only ever
// create a 'pending_verification' payment; only rpc_admin_verify_instapay
// can turn it into 'succeeded' or 'failed', and doing that twice must never
// double-apply the financial effect (master prompt Test 9).
//
//   cd tool/db_tests && npm install && npm test

import { setup, ADMIN, CUST_A, CUST_B } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

await as(ADMIN);
const cairo = (await one(`select id from public.cities where name_ar = 'القاهرة'`)).id;
await as(CUST_A);
const addrA = (await one(`select public.rpc_save_my_address(
  p_address_id => null, p_city_id => $1, p_label => 'المنزل', p_address_line => 'addr',
  p_latitude => 30.0561, p_longitude => 31.3301) as r`, [cairo])).r.id;

await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('IP1', 'مكواة', 50, 100) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 20, 50, 'seed')`, [P]);

const createOrder = () => as(CUST_A).then(() => one(
  `select public.rpc_create_order($1, $2, $3, null, null) as id`,
  [CUST_A, JSON.stringify([{ product_id: P, quantity: 1 }]), addrA]));
const submit = (orderId, amount, ref, path, reqId) => as(CUST_A).then(() => one(
  `select public.rpc_submit_instapay_payment($1, $2, $3, $4, $5) as id`,
  [orderId, amount, ref, path, reqId ?? null]));
const submitErr = (orderId, amount, ref, path) => as(CUST_A).then(() => err(
  `select public.rpc_submit_instapay_payment($1, $2, $3, $4)`,
  [orderId, amount, ref, path]));
const paymentRow = async (id) => { await asSuper(); return one(`select * from public.payments where id = $1`, [id]); };
const orderRow = async (id) => { await asSuper(); return one(`select * from public.orders where id = $1`, [id]); };
const proofPath = () => `${CUST_A}/${Math.random().toString(36).slice(2)}.jpg`;

// ---------------------------------------------------------------- settings
console.log('\n== InstaPay details ==');
await as(CUST_A);
let details = (await one(`select public.rpc_get_instapay_details() as d`)).d;
ok('not configured by default', details.configured === false);
ok('customer cannot set the InstaPay handle',
  (await err(`select public.rpc_admin_set_text_setting('instapay_ipa_address', 'x@instapay')`))?.includes('FORBIDDEN'));
await as(ADMIN);
await q(`select public.rpc_admin_set_text_setting('instapay_ipa_address', 'mokoji@instapay')`);
await q(`select public.rpc_admin_set_text_setting('instapay_beneficiary_name', 'مكوجي')`);
await as(CUST_A);
details = (await one(`select public.rpc_get_instapay_details() as d`)).d;
ok('configured after admin sets it', details.configured === true && details.ipa_address === 'mokoji@instapay');
ok('unknown setting key refused', (await as(ADMIN).then(() =>
  err(`select public.rpc_admin_set_text_setting('something_else', 'x')`)))?.includes('UNKNOWN_SETTING'));

// ---------------------------------------------------------------- submission
console.log('\n== Submitting a transfer ==');
const o1 = (await createOrder()).id;
const path1 = proofPath();
const pay1 = (await submit(o1, 100, 'IP-REF-001', path1)).id;
let p = await paymentRow(pay1);
ok('submission is pending_verification, never paid directly', p.status === 'pending_verification');
ok('channel is instapay and reference/proof are recorded', p.channel === 'instapay' && p.provider_reference === 'IP-REF-001'
  && p.metadata.proof_path === path1);
ok('order is untouched until an admin verifies', (await orderRow(o1)).payment_status === 'unpaid');

ok('a bogus proof path outside the customer\'s own folder is refused',
  (await submitErr(o1, 100, 'IP-REF-002', `${CUST_B}/x.jpg`))?.includes('INVALID_PROOF_PATH'));
ok('a second submission for the same order while one is pending is refused',
  (await submitErr(o1, 100, 'IP-REF-003', proofPath()))?.includes('VERIFICATION_ALREADY_PENDING'));
ok('empty reference refused', (await submitErr(o1, 100, '  ', proofPath()))?.includes('REFERENCE_REQUIRED'));
ok('amount above the remaining balance refused',
  (await createOrder().then(o => submitErr(o.id, 999999, 'IP-X', proofPath())))?.includes('AMOUNT_EXCEEDS_REMAINING'));

await as(CUST_B);
ok('another customer cannot submit against someone else\'s order',
  (await err(`select public.rpc_submit_instapay_payment($1, $2, $3, $4)`,
    [o1, 100, 'IP-REF-004', `${CUST_B}/x.jpg`]))?.includes('ORDER_CUSTOMER_MISMATCH'));

// ---------------------------------------------------------------- verification
console.log('\n== Admin verification ==');
await as(CUST_A);
ok('customer cannot verify their own payment',
  (await err(`select public.rpc_admin_verify_instapay($1, true)`, [pay1]))?.includes('FORBIDDEN'));

await as(ADMIN);
await q(`select public.rpc_admin_verify_instapay($1, true)`, [pay1]);
p = await paymentRow(pay1);
ok('approved payment is succeeded with paid_at set', p.status === 'succeeded' && p.paid_at !== null);
let o = await orderRow(o1);
ok('order reflects the payment (paid in full)', Number(o.paid_amount) === 100 && o.payment_status === 'paid');

await asSuper();
// 0064: a confirmed InstaPay transfer is real money received by transfer,
// so it credits خزنة التحويلات (the transfer cashbox) — not the physical
// cash till, which must stay untouched.
const cashTillTotal = (await one(
  `select coalesce(sum(ct.amount),0)::numeric as n from public.cash_transactions ct
   join public.cashboxes cb on cb.id = ct.cashbox_id where cb.kind = 'cash'`)).n;
ok('InstaPay money never touches the physical cash till', Number(cashTillTotal) === 0);
const transferTillTotal = (await one(
  `select coalesce(sum(ct.amount),0)::numeric as n from public.cash_transactions ct
   join public.cashboxes cb on cb.id = ct.cashbox_id where cb.kind = 'transfer'`)).n;
ok('InstaPay money credits the transfer cashbox instead', Number(transferTillTotal) === 100);

console.log('\n== Verifying twice must not double-apply (Test 9) ==');
await as(ADMIN);
ok('re-verifying an already-succeeded payment is refused',
  (await err(`select public.rpc_admin_verify_instapay($1, true)`, [pay1]))?.includes('PAYMENT_NOT_PENDING_VERIFICATION'));
o = await orderRow(o1);
ok('order is not double-credited', Number(o.paid_amount) === 100);

console.log('\n== Rejection ==');
const o2 = (await createOrder()).id;
const pay2 = (await submit(o2, 100, 'IP-REF-010', proofPath())).id;
await as(ADMIN);
ok('rejecting without a reason is refused',
  (await err(`select public.rpc_admin_verify_instapay($1, false)`, [pay2]))?.includes('REASON_REQUIRED'));
await q(`select public.rpc_admin_verify_instapay($1, false, $2)`, [pay2, 'المرجع مش موجود في كشف الحساب']);
p = await paymentRow(pay2);
ok('rejected payment is failed, with the reason recorded', p.status === 'failed'
  && p.metadata.rejection_reason === 'المرجع مش موجود في كشف الحساب');
ok('order stays unpaid after a rejection', (await orderRow(o2)).payment_status === 'unpaid');
ok('customer can resubmit after a rejection (no longer "already pending")',
  (await submit(o2, 100, 'IP-REF-011', proofPath())) !== null);

// ---------------------------------------------------------------- idempotency + audit
console.log('\n== Idempotency and audit ==');
const o3 = (await createOrder()).id;
const reqId = '22222222-3333-4444-8888-999999999999';
const retryPath = proofPath();
const first = await submit(o3, 100, 'IP-REF-020', retryPath, reqId);
// A genuine retry resends the exact same request — this must short-circuit
// on the idempotency key, not trip the "already pending" rule the first
// call itself just created.
const second = await submit(o3, 100, 'IP-REF-020', retryPath, reqId);
ok('same client_request_id returns the same payment (idempotent submission)', first.id === second.id);

await asSuper();
ok('every attempt is recorded immutably',
  (await one(`select count(*)::int as n from public.payment_attempts where payment_id = $1`, [pay1])).n === 1);
ok('payment changes are audited', (await one(`select count(*)::int as n from public.audit_logs where table_name = 'payments'`)).n >= 4);

// ---------------------------------------------------------------- grants
console.log('\n== Grants ==');
const leaked = await q(`
  select p.oid::regprocedure::text as f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind = 'f'
    and not exists (select 1 from pg_depend d where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
    and (has_function_privilege('anon', p.oid, 'execute')
         or (has_function_privilege('authenticated', p.oid, 'execute')
             and p.proname not in (select function_name from private.rpc_allowlist)))`);
ok('no function executable beyond the allowlist', leaked.length === 0, JSON.stringify(leaked));

finish();
