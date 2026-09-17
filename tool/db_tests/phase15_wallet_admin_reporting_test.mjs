// tool/db_tests/phase15_wallet_admin_reporting_test.mjs
//
// Phase 15 (0042): admin/finance visibility into the wallet liability. The
// existing revenue/profit figures (daily_sales_summary, 0009) were already
// correct once wallet/InstaPay payments existed — they key off orders.status,
// not payment channel. What was missing was any view of money sitting in
// customer wallets at all, which is a liability, not revenue, and never
// touches cashbox_balances by design (0040/0041).
//
//   cd tool/db_tests && npm install && npm test

import { setup, ADMIN, CUST_A, CUST_B } from './harness.mjs';

const { ok, finish, as, q, one } = await setup(process.argv[2]);

const topupAndVerify = async (customer, amount, ref) => {
  const p = await as(customer).then(() => one(
    `select public.rpc_wallet_topup_via_instapay($1, $2, $3) as id`,
    [amount, ref, `${customer}/${Math.random().toString(36).slice(2)}.jpg`]));
  await as(ADMIN);
  await q(`select public.rpc_admin_verify_instapay($1, true)`, [p.id]);
};

console.log('\n== Seeding two customer wallets ==');
await topupAndVerify(CUST_A, 300, 'REF-15-A');
await topupAndVerify(CUST_B, 150, 'REF-15-B');

console.log('\n== wallet_summary (admin) ==');
await as(ADMIN);
const rows = await q(`select * from public.wallet_summary order by customer_name`);
ok('admin sees every customer wallet', rows.length === 2);
const rowA = rows.find(r => r.customer_id === CUST_A);
const rowB = rows.find(r => r.customer_id === CUST_B);
ok('balances are correct per customer', Number(rowA.balance) === 300 && Number(rowB.balance) === 150);
ok('customer names are joined in', !!rowA.customer_name && !!rowB.customer_name);

console.log('\n== wallet_liability_summary (admin) ==');
const liability = await one(`select * from public.wallet_liability_summary`);
ok('total_liability sums every active wallet', Number(liability.total_liability) === 450);
ok('wallet_count matches', Number(liability.wallet_count) === 2);

console.log('\n== A customer only ever sees their own wallet (RLS via security_invoker) ==');
await as(CUST_A);
const ownRows = await q(`select * from public.wallet_summary`);
ok('customer A sees only their own wallet row, never customer B\'s', ownRows.length === 1 && ownRows[0].customer_id === CUST_A);
const ownLiability = await one(`select * from public.wallet_liability_summary`);
ok('a customer querying the liability view gets their own balance, not the shop total (not a leak — RLS-scoped, same as customer_account_summary)',
  Number(ownLiability.total_liability) === 300);

console.log('\n== Anonymous access ==');
await as(null);
let anonBlocked = false;
try { await q(`select * from public.wallet_summary`); } catch { anonBlocked = true; }
ok('anon gets nothing from wallet_summary (the underlying wallets grant is authenticated-only)', anonBlocked);

finish();
