// tool/db_tests/phase2_auth_test.mjs
//
// Phase 2 (0031): phone verification evidence, the require_verified_phone
// switch, and security audit rows written from Auth's own updates.
//
//   cd tool/db_tests && npm install && npm test

import { setup, uid, ADMIN, TECH, CUST_A, CUST_B } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err, db } = await setup(process.argv[2]);

const nowSec = () => Math.floor(Date.now() / 1000);
const otpAmr = (ageSeconds = 5) => ({ amr: [{ method: 'otp', timestamp: nowSec() - ageSeconds }] });
const passwordAmr = { amr: [{ method: 'password', timestamp: nowSec() }] };
const verifiedAt = async (id) => { await asSuper(); return (await one(`select phone_verified_at from public.users where id = $1`, [id])).phone_verified_at; };
const audit = async (action, id) => { await asSuper(); return (await one(`select count(*)::int as n from public.audit_logs where action = $1 and record_id = $2`, [action, id])).n; };

// A product so "can this customer act?" has something real to order.
await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('P2', 'Iron', 60, 100) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 10, 60, 'seed')`, [P]);
const order = (customer) => `select public.rpc_create_order('${customer}', '[{"product_id":"${P}","quantity":1}]'::jsonb, null, null, null, null, null)`;

// ---------------------------------------------------------------- defaults
console.log('\n== Defaults: deploying 0031 changes nothing for existing users ==');
await asSuper();
ok('existing accounts start unverified', (await verifiedAt(CUST_A)) === null);
await as(CUST_A);
ok('switch is off by default', (await one(`select public.rpc_get_auth_settings() as s`)).s.require_verified_phone === false);
ok('unverified customer can still order while the switch is off', (await err(order(CUST_A))) === null);

// ---------------------------------------------------------------- the switch
console.log('\n== Switch: only an admin flips it, and it is audited ==');
await as(CUST_A);
ok('customer cannot flip the switch', (await err(`select public.rpc_admin_set_setting('require_verified_phone', true)`))?.includes('FORBIDDEN'));
await as(TECH);
ok('technician cannot flip the switch', (await err(`select public.rpc_admin_set_setting('require_verified_phone', true)`))?.includes('FORBIDDEN'));
await as(ADMIN);
ok('unknown setting refused', (await err(`select public.rpc_admin_set_setting('nope', true)`))?.includes('UNKNOWN_SETTING'));
await q(`select public.rpc_admin_set_setting('require_verified_phone', true)`);
await asSuper();
ok('switch change audited', (await one(`select count(*)::int as n from public.audit_logs where action = 'SETTING_CHANGED'`)).n === 1);
await as(CUST_A);
ok('clients read the new value', (await one(`select public.rpc_get_auth_settings() as s`)).s.require_verified_phone === true);
await as(CUST_A);
ok('clients cannot read private.app_settings directly', (await err(`select * from private.app_settings`))?.includes('permission denied'));

// ---------------------------------------------------------------- gating
console.log('\n== Gating: unverified customers are anon for writes ==');
await as(CUST_A);
ok('unverified customer cannot order', (await err(order(CUST_A)))?.includes('FORBIDDEN'));
ok('unverified customer cannot open maintenance',
  (await err(`select public.rpc_create_maintenance_request($1, 'A', '01012345678', null, null, null, null, 'x', null)`, [CUST_A]))?.includes('FORBIDDEN'));
ok('unverified customer still reads own orders', (await q(`select id from public.orders where customer_id = $1`, [CUST_A])).length === 1);
await as(ADMIN);
ok('admin is never gated', (await err(`select public.rpc_cashbox_deposit(1, 'x')`)) === null);
await as(TECH);
ok('technician is never gated', (await q(`select public.is_technician() as t`))[0].t === true);

// ---------------------------------------------------------------- client cannot self-verify
console.log('\n== Verification can\'t be forged ==');
await as(CUST_A);
ok('customer cannot write phone_verified_at',
  (await err(`update public.users set phone_verified_at = now() where id = $1`, [CUST_A]))?.includes('permission denied'));
await as(CUST_A, passwordAmr);
ok('password session cannot mark verified', (await err(`select public.rpc_mark_phone_verified()`))?.includes('OTP_SESSION_REQUIRED'));
await as(CUST_A, otpAmr(2 * 3600));
ok('OTP session older than an hour cannot mark verified', (await err(`select public.rpc_mark_phone_verified()`))?.includes('OTP_SESSION_REQUIRED'));
await as(CUST_B, otpAmr());
ok('account without a confirmed phone cannot mark verified', (await err(`select public.rpc_mark_phone_verified()`))?.includes('PHONE_NOT_VERIFIED'));
await as(null);
ok('anon cannot call rpc_mark_phone_verified', (await err(`select public.rpc_mark_phone_verified()`))?.includes('permission denied'));
ok(`still unverified after all of the above`, (await verifiedAt(CUST_A)) === null);

// ---------------------------------------------------------------- legacy account verifies
console.log('\n== Existing account proves its number with an OTP session ==');
await as(CUST_A, otpAmr());
await q(`select public.rpc_mark_phone_verified()`);
ok('fresh OTP session marks verified', (await verifiedAt(CUST_A)) !== null);
const first = await verifiedAt(CUST_A);
await as(CUST_A, otpAmr());
await q(`select public.rpc_mark_phone_verified()`);
ok('marking again keeps the original timestamp', (await verifiedAt(CUST_A)).getTime() === first.getTime());
ok('verification audited', (await audit('PHONE_VERIFIED', CUST_A)) >= 1);
await as(CUST_A);
ok('verified customer can order again', (await err(order(CUST_A))) === null);

// ---------------------------------------------------------------- new signup via Auth
console.log('\n== New signup: Auth confirming the phone counts (switch on) ==');
const NEW = uid(20);
await asSuper();
await db.query(`insert into auth.users (id, phone, raw_user_meta_data) values ($1, '201055555555', '{"full_name":"New"}')`, [NEW]);
ok('signup provisions an unverified customer', (await verifiedAt(NEW)) === null);
await db.query(`update auth.users set phone_confirmed_at = now() where id = $1`, [NEW]);
ok('Auth confirming the OTP marks the profile verified', (await verifiedAt(NEW)) !== null);
ok('phone confirmation audited', (await audit('PHONE_CONFIRMED', NEW)) === 1);

console.log('\n== Switch off: Auth confirmations are not trusted ==');
await as(ADMIN);
await q(`select public.rpc_admin_set_setting('require_verified_phone', false)`);
const AUTO = uid(21);
await asSuper();
await db.query(`insert into auth.users (id, phone, raw_user_meta_data) values ($1, '201066666666', '{"full_name":"Auto"}')`, [AUTO]);
await db.query(`update auth.users set phone_confirmed_at = now() where id = $1`, [AUTO]);
ok('an auto-confirm (switch off) does not count as verification', (await verifiedAt(AUTO)) === null);

// ---------------------------------------------------------------- password audit
console.log('\n== Password changes are audited without secrets ==');
await asSuper();
await db.query(`update auth.users set encrypted_password = 'hash-1' where id = $1`, [CUST_A]);
await db.query(`update auth.users set encrypted_password = 'hash-2' where id = $1`, [CUST_A]);
const pw = await q(`select new_data, old_data from public.audit_logs where action = 'PASSWORD_CHANGED' and record_id = $1`, [CUST_A]);
ok('each password change audited', pw.length === 2);
ok('no hash copied into the audit row', pw.every(r => r.new_data === null && r.old_data === null));
await db.query(`update auth.users set banned_until = null where id = $1`, [CUST_A]);
ok('unrelated auth.users updates add no audit rows', (await audit('PASSWORD_CHANGED', CUST_A)) === 2);

// ---------------------------------------------------------------- grants
// ---------------------------------------------------------------- stale numbers
console.log('\n== Verifying releases a number a stale profile was squatting ==');
const OWNER = uid(40), SQUATTER = uid(41);
await asSuper();
await db.query(`insert into auth.users (id, phone, phone_confirmed_at) values ($1, '201088888888', now())`, [OWNER]);
await db.query(`insert into auth.users (id, phone, phone_confirmed_at) values ($1, '201099999999', now())`, [SQUATTER]);
// The owner's profile lost its number earlier; the squatter wrote it into
// their own profile back when phone was self-editable.
await db.query(`update public.users set phone = null where id = $1`, [OWNER]);
await db.query(`update public.users set phone = '+201088888888' where id = $1`, [SQUATTER]);
await as(OWNER, otpAmr());
ok('owner verifying by OTP is not blocked by the squatter', (await err(`select public.rpc_mark_phone_verified()`)) === null);
await asSuper();
ok('owner profile now carries the number', (await one(`select phone from public.users where id = $1`, [OWNER])).phone === '201088888888');
ok('squatter profile lost it', (await one(`select phone from public.users where id = $1`, [SQUATTER])).phone === null);

// ---------------------------------------------------------------- phone change
console.log('\n== Changing number through Auth ==');
await as(ADMIN);
await q(`select public.rpc_admin_set_setting('require_verified_phone', true)`);
await asSuper();
await db.query(`update auth.users set phone = '201012121212', phone_confirmed_at = now() where id = $1`, [CUST_A]);
const afterChange = await one(`select phone, phone_verified_at from public.users where id = $1`, [CUST_A]);
ok('profile follows the new auth number', afterChange.phone === '201012121212');
ok('verification restarts at the change (switch on: Auth proved the new number)',
  afterChange.phone_verified_at !== null && afterChange.phone_verified_at.getTime() > first.getTime());
ok('phone change audited', (await audit('PHONE_CHANGED', CUST_A)) === 1);
await as(ADMIN);
await q(`select public.rpc_admin_set_setting('require_verified_phone', false)`);
await asSuper();
await db.query(`update auth.users set phone = '201013131313', phone_confirmed_at = now() where id = $1`, [CUST_A]);
ok('with the switch off a changed number is not counted as verified',
  (await verifiedAt(CUST_A)) === null);

console.log('\n== Grants ==');
const leaked = await q(`
  select p.oid::regprocedure::text as f from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prokind = 'f'
    and not exists (select 1 from pg_depend d where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e')
    and (has_function_privilege('anon', p.oid, 'execute')
         or (has_function_privilege('authenticated', p.oid, 'execute')
             and p.proname not in (select function_name from private.rpc_allowlist)))`);
ok('no function executable beyond the allowlist', leaked.length === 0, JSON.stringify(leaked));
await as(CUST_A);
ok('customer cannot call the auth.users trigger function', (await err(`select public.on_auth_user_security_event()`)) !== null);

finish();
