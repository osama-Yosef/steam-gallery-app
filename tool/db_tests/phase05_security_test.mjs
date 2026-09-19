// tool/db_tests/phase05_security_test.mjs
//
// Phase 0.5 fixes (0029/0030) exercised as admin, technician, customer and
// anon. See harness.mjs for how the database is built.
//
//   cd tool/db_tests && npm install && npm test

import { setup, uid, ADMIN, TECH, TECH2, CUST_A, CUST_B } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err, db } = await setup(process.argv[2]);

// ---------------------------------------------------------------- provisioning
console.log('\n== Provisioning ==');
await asSuper();
ok('customer phone comes from auth.users, not user metadata',
  (await one(`select phone from public.users where id = $1`, [CUST_A])).phone === '+201000000004');
ok('empty auth phone is stored as NULL (no metadata fallback)',
  (await one(`select phone from public.users where id = $1`, [CUST_B])).phone === null);

// Before 0029 a customer could write any number into users.phone. Simulate a
// profile squatting a number (in the older "+20…" format), then the real
// holder signing up with it.
await db.query(`update public.users set phone = '+201077777777' where id = $1`, [CUST_B]);
const HOLDER = uid(30);
ok('real holder can sign up with a number a stale profile was squatting',
  (await err(`insert into auth.users (id, phone, raw_user_meta_data) values ($1, '201077777777', '{"full_name":"Holder"}')`, [HOLDER])) === null);
ok('the holder\'s profile gets the number', (await one(`select phone from public.users where id = $1`, [HOLDER])).phone === '201077777777');
ok('the squatting profile loses it', (await one(`select phone from public.users where id = $1`, [CUST_B])).phone === null);
// Real Supabase refuses a second auth user with the same number (the stand-in
// table has no such constraint); what matters here is that the release never
// takes a number from the profile whose own auth account holds it.
await err(`insert into auth.users (id, phone) values ($1, '201000000004')`, [uid(31)]);
ok('a profile whose own auth account holds the number keeps it',
  (await one(`select phone from public.users where id = $1`, [CUST_A])).phone === '+201000000004');

// ---------------------------------------------------------------- catalogue + stock (admin)
await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('SKU1', 'Iron', 60, 100) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 20, 60, 'seed')`, [P]);
const SERVICE = (await one(`select id from public.products where sku = 'SERVICE-MAINT'`)).id;
await q(`select public.rpc_cashbox_deposit(1000, 'float')`);
const cash = async () => { await asSuper(); const r = await one(`select balance from public.cashbox_balances where kind = 'cash' limit 1`); return Number(r.balance); };
const stock = async () => { await asSuper(); const r = await one(`select quantity from public.warehouse_stock where product_id = $1`, [P]); return r.quantity; };
const custBalance = async (c) => { await asSuper(); const r = await one(`select remaining_balance from public.customer_account_summary where customer_id = $1`, [c]); return Number(r.remaining_balance); };

// 0036: rpc_create_order now takes a saved, serviceable address instead of
// free text. مدينة نصر is seeded as covered by 0032.
const cairo = (await one(`select id from public.cities where name_ar = 'القاهرة'`)).id;
const address = async (customer) => {
  await as(customer);
  const r = (await one(`select public.rpc_save_my_address(
    p_address_id => null, p_city_id => $1, p_label => 'المنزل', p_address_line => 'addr',
    p_latitude => 30.0561, p_longitude => 31.3301) as r`, [cairo])).r;
  return r.id;
};
const addrA = await address(CUST_A);
const addrB = await address(CUST_B);

// ---------------------------------------------------------------- P0-1/2 cost leaks
console.log('\n== P0-1/P0-2: cost never reaches a customer ==');
await as(CUST_A);
ok('customer: products table returns 0 rows', (await q(`select cost_price from public.products`)).length === 0);
const pub = await q(`select * from public.products_public`);
ok('customer: products_public lists the product, available, no cost column',
  pub.length === 1 && pub[0].is_available === true && !Object.keys(pub[0]).some(k => k.includes('cost')));
await as(TECH);
ok('technician: products table still readable (bag screens)', (await q(`select cost_price from public.products where id = $1`, [P])).length === 1);

// ---------------------------------------------------------------- P0-3 order pricing
console.log('\n== P0-3: server-side order pricing ==');
await as(CUST_A);
const K1 = uid(9001);
const O1 = (await one(`select public.rpc_create_order($1, $2, $3, null, $4) as id`,
  [CUST_A, JSON.stringify([{ product_id: P, quantity: 2, discount: 999999 }]), addrA, K1])).id;
const o1 = await one(`select total from public.orders where id = $1`, [O1]);
ok('Test 4/5: payload discount ignored, total = 2 x DB price = 200', Number(o1.total) === 200, `got ${o1.total}`);
ok('idempotent retry returns the same order',
  (await one(`select public.rpc_create_order($1, $2, $3, null, $4) as id`,
    [CUST_A, JSON.stringify([{ product_id: P, quantity: 5 }]), addrA, K1])).id === O1);
await as(CUST_B);
ok('another customer reusing the key gets IDEMPOTENCY_KEY_CONFLICT',
  (await err(`select public.rpc_create_order($1, $2, $3, null, $4)`,
    [CUST_B, JSON.stringify([{ product_id: P, quantity: 1 }]), addrB, K1]))?.includes('IDEMPOTENCY_KEY_CONFLICT'));
ok('customer cannot order on behalf of another customer',
  (await err(`select public.rpc_create_order($1, $2, $3, null, null)`,
    [CUST_A, JSON.stringify([{ product_id: P, quantity: 1 }]), addrA]))?.includes('FORBIDDEN'));
ok('service line cannot be ordered',
  (await err(`select public.rpc_create_order($1, $2, $3, null, null)`,
    [CUST_B, JSON.stringify([{ product_id: SERVICE, quantity: 1 }]), addrB]))?.includes('PRODUCT_NOT_FOUND'));
ok('zero quantity rejected',
  (await err(`select public.rpc_create_order($1, $2, $3, null, null)`,
    [CUST_B, JSON.stringify([{ product_id: P, quantity: 0 }]), addrB]))?.includes('INVALID_QUANTITY'));
ok('empty order rejected',
  (await err(`select public.rpc_create_order($1, '[]'::jsonb, $2, null, null)`, [CUST_B, addrB]))?.includes('EMPTY_ORDER'));

// ---------------------------------------------------------------- P0-4 function lockdown
console.log('\n== P0-4: internal functions not callable ==');
await as(CUST_A);
ok('customer cannot call notify_user',
  (await err(`select public.notify_user($1, 'x', 'phish', 'phish')`, [ADMIN]))?.includes('permission denied'));
ok('customer cannot call notify_all_admins',
  (await err(`select public.notify_all_admins('x', 'phish', 'phish')`))?.includes('permission denied'));
await as(null);
ok('anon cannot call notify_user',
  (await err(`select public.notify_user($1, 'x', 'phish', 'phish')`, [ADMIN]))?.includes('permission denied'));
ok('anon cannot call rpc_create_order',
  (await err(`select public.rpc_create_order($1, '[]'::jsonb, $2, null, null)`, [CUST_A, addrA]))?.includes('permission denied'));
await asSuper();
const leakedAnon = await q(`
  select p.oid::regprocedure::text as f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind = 'f'
    and not exists (select 1 from pg_depend d where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
    and has_function_privilege('anon', p.oid, 'execute')`);
ok('verify_security #1: no public function executable by anon', leakedAnon.length === 0, JSON.stringify(leakedAnon));
const leakedAuth = await q(`
  select p.oid::regprocedure::text as f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind = 'f'
    and not exists (select 1 from pg_depend d where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
    and has_function_privilege('authenticated', p.oid, 'execute')
    and p.proname not in (select function_name from private.rpc_allowlist)`);
ok('verify_security #2: nothing executable beyond the allowlist', leakedAuth.length === 0, JSON.stringify(leakedAuth));
const missing = await q(`select a.function_name from private.rpc_allowlist a where not exists (
  select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and p.proname = a.function_name)`);
ok('verify_security #3: every allowlisted function exists', missing.length === 0, JSON.stringify(missing));

// ---------------------------------------------------------------- P0-6 phone
console.log('\n== P0-6: phone not self-editable ==');
await as(CUST_A);
ok('customer cannot update own phone',
  (await err(`update public.users set phone = '+201234567890' where id = $1`, [CUST_A]))?.includes('permission denied'));
ok('customer can still update own name', (await err(`update public.users set full_name = 'A2' where id = $1`, [CUST_A])) === null);

// ---------------------------------------------------------------- confirm + order items views
console.log('\n== Order items views ==');
await as(ADMIN);
await q(`select public.rpc_confirm_order($1)`, [O1]);
ok('confirm deducted stock 20 -> 18', (await stock()) === 18);
await as(CUST_A);
ok('customer: raw order_items returns 0 rows', (await q(`select unit_cost_snapshot from public.order_items`)).length === 0);
const disp = await q(`select * from public.order_items_display where order_id = $1`, [O1]);
ok('customer: order_items_display shows own line without cost', disp.length === 1 && !Object.keys(disp[0]).some(k => k.includes('cost')));
ok('customer: daily_sales_summary exposes no COGS rows', (await q(`select cogs from public.daily_sales_summary`)).length === 0);
await as(CUST_B);
ok('other customer: order_items_display returns 0 rows (IDOR)', (await q(`select * from public.order_items_display where order_id = $1`, [O1])).length === 0);
ok('other customer: orders row invisible (IDOR)', (await q(`select * from public.orders where id = $1`, [O1])).length === 0);

// ---------------------------------------------------------------- P1-7 state machine
console.log('\n== P1-7: order state machine ==');
await as(CUST_B);
const O2 = (await one(`select public.rpc_create_order($1, $2, $3, null, null) as id`,
  [CUST_B, JSON.stringify([{ product_id: P, quantity: 1 }]), addrB])).id;
await as(ADMIN);
ok('pending -> completed refused',
  (await err(`select public.rpc_update_order_status($1, 'completed')`, [O2]))?.includes('INVALID_STATUS_TRANSITION'));
ok('confirmed -> preparing allowed', (await err(`select public.rpc_update_order_status($1, 'preparing')`, [O1])) === null);
ok('preparing -> completed (skipping delivered) refused',
  (await err(`select public.rpc_update_order_status($1, 'completed')`, [O1]))?.includes('INVALID_STATUS_TRANSITION'));

// ---------------------------------------------------------------- P1-9 payments
console.log('\n== P1-9: customer payments ==');
const cashBefore = await cash();
await as(ADMIN);
const PK = uid(9101);
await q(`select public.rpc_record_customer_payment($1, 50, $2, 'p1', $3)`, [CUST_A, O1, PK]);
await q(`select public.rpc_record_customer_payment($1, 50, $2, 'p1', $3)`, [CUST_A, O1, PK]);
await asSuper();
ok('same key twice -> one ledger row', (await one(`select count(*)::int as n from public.customer_account_transactions where client_request_id = $1`, [PK])).n === 1);
ok('same key twice -> paid_amount 50', Number((await one(`select paid_amount from public.orders where id = $1`, [O1])).paid_amount) === 50);
ok('same key twice -> till +50 once', (await cash()) === cashBefore + 50);
await as(ADMIN);
ok('same key, different amount -> conflict',
  (await err(`select public.rpc_record_customer_payment($1, 60, $2, 'p1', $3)`, [CUST_A, O1, PK]))?.includes('IDEMPOTENCY_KEY_CONFLICT'));
ok('payment above remaining refused',
  (await err(`select public.rpc_record_customer_payment($1, 151, $2, null, null)`, [CUST_A, O1]))?.includes('AMOUNT_EXCEEDS_REMAINING'));
ok('payment against another customer\'s order refused',
  (await err(`select public.rpc_record_customer_payment($1, 10, $2, null, null)`, [CUST_B, O1]))?.includes('ORDER_CUSTOMER_MISMATCH'));
ok('old 4-arg call (no key) still resolves', (await err(`select public.rpc_record_customer_payment(p_customer_id => $1, p_amount => 10, p_order_id => null, p_notes => 'legacy')`, [CUST_B])) === null);
await as(CUST_A);
ok('customer cannot record a payment', (await err(`select public.rpc_record_customer_payment($1, 10, null, null, null)`, [CUST_A]))?.includes('FORBIDDEN'));

// ---------------------------------------------------------------- P1-8 cancellation
console.log('\n== P1-8: cancel without double refund ==');
const cashBeforeCancel = await cash();
await as(ADMIN);
await q(`select public.rpc_cancel_order($1, 'test')`, [O1]);
ok('customer A balance back to 0 (charge 200, paid 50, cancelled)', (await custBalance(CUST_A)) === 0, `got ${await custBalance(CUST_A)}`);
ok('till refunded exactly 50', (await cash()) === cashBeforeCancel - 50);
ok('stock returned 18 -> 20', (await stock()) === 20);
await as(ADMIN);
ok('cancelling twice refused', (await err(`select public.rpc_cancel_order($1, 'again')`, [O1]))?.includes('ORDER_NOT_CANCELLABLE'));
ok('cancel without reason refused', (await err(`select public.rpc_cancel_order($1, '  ')`, [O2]))?.includes('REASON_REQUIRED'));

// ---------------------------------------------------------------- P1-10/11 technician
console.log('\n== P1-10/P1-11: technician sale + supply ==');
await as(ADMIN);
await q(`select public.rpc_issue_stock_to_technician($1, $2, 'bag')`, [TECH, JSON.stringify([{ product_id: P, quantity: 5 }])]);
await as(TECH);
ok('tech cannot bill an arbitrary customer',
  (await err(`select public.rpc_technician_sale($1, $2, null, null, $3, 'deferred', 0, 0, null, null, null)`,
    [TECH, CUST_B, JSON.stringify([{ product_id: P, quantity: 1 }])]))?.includes('FORBIDDEN'));
ok('discount above subtotal refused',
  (await err(`select public.rpc_technician_sale($1, null, 'x', null, $2, 'cash', 500, 0, null, null, null)`,
    [TECH, JSON.stringify([{ product_id: P, quantity: 1 }])]))?.includes('INVALID_DISCOUNT'));
ok('paid above total refused',
  (await err(`select public.rpc_technician_sale($1, null, 'x', null, $2, 'cash', 0, 101, null, null, null)`,
    [TECH, JSON.stringify([{ product_id: P, quantity: 1 }])]))?.includes('PAYMENT_EXCEEDS_TOTAL'));
ok('deferred without a customer refused',
  (await err(`select public.rpc_technician_sale($1, null, 'x', null, $2, 'deferred', 0, 0, null, null, null)`,
    [TECH, JSON.stringify([{ product_id: P, quantity: 1 }])]))?.includes('DEFERRED_REQUIRES_CUSTOMER'));
await q(`select public.rpc_technician_sale($1, null, 'walk', null, $2, 'cash', 0, 100, null, null, null)`,
  [TECH, JSON.stringify([{ product_id: P, quantity: 1 }])]);
const due = async () => { await asSuper(); return Number((await one(`select amount_due from public.technician_account_summary where technician_id = $1`, [TECH])).amount_due); };
ok('tech amount due = 100 after cash sale', (await due()) === 100);

const cashBeforeSupply = await cash();
await as(TECH);
const S1 = (await one(`select public.rpc_technician_supply($1, 100, 'cash') as id`, [TECH])).id;
ok('tech supply is pending', (await (async () => { await asSuper(); return (await one(`select status from public.technician_supplies where id = $1`, [S1])).status; })()) === 'pending');
ok('pending supply does not reduce amount due', (await due()) === 100);
ok('pending supply does not touch the till', (await cash()) === cashBeforeSupply);
await asSuper();
ok('admins were notified of the pending supply', (await one(`select count(*)::int as n from public.notifications where user_id = $1 and type = 'supply_pending'`, [ADMIN])).n === 1);
await as(TECH);
ok('tech cannot approve own supply', (await err(`select public.rpc_admin_review_technician_supply($1, true, null)`, [S1]))?.includes('FORBIDDEN'));
await as(ADMIN);
await q(`select public.rpc_admin_review_technician_supply($1, true, null)`, [S1]);
await q(`select public.rpc_admin_review_technician_supply($1, true, null)`, [S1]);
ok('Test 9 style: approving twice posts once (amount due 0)', (await due()) === 0);
ok('approving twice credits the till once', (await cash()) === cashBeforeSupply + 100);
await as(ADMIN);
ok('rejecting an approved supply refused', (await err(`select public.rpc_admin_review_technician_supply($1, false, 'no')`, [S1]))?.includes('SUPPLY_NOT_PENDING'));
const cashBeforeAdminSupply = await cash();
await as(ADMIN);
await q(`select public.rpc_technician_supply($1, 10, 'admin recorded')`, [TECH]);
ok('admin-recorded supply posts immediately', (await cash()) === cashBeforeAdminSupply + 10);

// ---------------------------------------------------------------- P1-13 maintenance + invoice
console.log('\n== P1-13: maintenance + invoice ==');
await as(CUST_A);
const M1 = (await one(`select public.rpc_create_maintenance_request($1, 'A', '010 1234 5678', 'addr', null, null, 'iron', 'broken', null) as id`, [CUST_A])).id;
ok('bad phone refused', (await err(`select public.rpc_create_maintenance_request($1, 'A', 'abc', null, null, null, null, 'x', null)`, [CUST_A]))?.includes('INVALID_PHONE'));
await as(TECH);
await q(`select public.rpc_claim_maintenance($1)`, [M1]);
await q(`select public.rpc_start_maintenance($1)`, [M1]);
await as(CUST_A);
ok('customer cannot cancel an in-progress job', (await err(`select public.rpc_cancel_maintenance($1, 'x')`, [M1]))?.includes('FORBIDDEN_OR_NOT_CANCELLABLE'));
await as(TECH);
await q(`select public.rpc_complete_maintenance($1, 'done')`, [M1]);
await as(TECH2);
ok('another technician cannot invoice the job',
  (await err(`select public.rpc_technician_sale($1, null, null, null, $2, 'cash', 0, 150, null, null, $3)`,
    [TECH2, JSON.stringify([{ product_id: SERVICE, quantity: 1, unit_price: 150 }]), M1]))?.includes('FORBIDDEN'));
await as(TECH);
const INV = (await one(`select public.rpc_technician_sale($1, null, 'A', null, $2, 'cash', 0, 150, null, null, $3) as id`,
  [TECH, JSON.stringify([{ product_id: SERVICE, quantity: 1, unit_price: 150 }]), M1])).id;
await asSuper();
ok('invoice is linked to the job\'s customer', (await one(`select customer_id from public.sales where id = $1`, [INV])).customer_id === CUST_A);
await as(CUST_A);
ok('customer: raw sale_items returns 0 rows', (await q(`select unit_cost_snapshot from public.sale_items`)).length === 0);
const sid = await q(`select * from public.sale_items_display where sale_id = $1`, [INV]);
ok('customer: sale_items_display shows the invoice without cost', sid.length === 1 && !Object.keys(sid[0]).some(k => k.includes('cost')));
await as(CUST_B);
ok('other customer: sale_items_display returns 0 rows (IDOR)', (await q(`select * from public.sale_items_display where sale_id = $1`, [INV])).length === 0);

// ---------------------------------------------------------------- P0-5 deactivation
console.log('\n== P0-5: deactivation enforced ==');
await as(CUST_B);
const M2 = (await one(`select public.rpc_create_maintenance_request($1, 'B', '01012345678', null, null, null, null, 'x', null) as id`, [CUST_B])).id;
await as(ADMIN);
ok('admin cannot deactivate self', (await err(`select public.rpc_admin_set_active($1, false)`, [ADMIN]))?.includes('CANNOT_CHANGE_OWN_ACCOUNT'));
await q(`select public.rpc_admin_set_active($1, false)`, [TECH2]);
await asSuper();
ok('deactivated user is banned in auth', (await one(`select banned_until from auth.users where id = $1`, [TECH2])).banned_until !== null);
await as(TECH2);
ok('deactivated technician with a still-valid JWT cannot claim',
  (await err(`select public.rpc_claim_maintenance($1)`, [M2]))?.includes('FORBIDDEN'));
ok('deactivated technician sees no waiting queue', (await q(`select * from public.maintenance_requests where status = 'waiting'`)).length === 0);
await as(ADMIN);
ok('assigning an inactive technician refused', (await err(`select public.rpc_assign_maintenance($1, $2)`, [M2, TECH2]))?.includes('TECHNICIAN_NOT_AVAILABLE'));
await q(`select public.rpc_admin_set_active($1, true)`, [TECH2]);
await asSuper();
ok('reactivation lifts the ban', (await one(`select banned_until from auth.users where id = $1`, [TECH2])).banned_until === null);

// ---------------------------------------------------------------- ledger immutability still holds
console.log('\n== Ledgers still immutable ==');
await asSuper();
ok('cash_transactions UPDATE still blocked', (await err(`update public.cash_transactions set amount = 0`))?.includes('immutable'));
ok('customer_account_transactions DELETE still blocked', (await err(`delete from public.customer_account_transactions`))?.includes('immutable'));

finish();
