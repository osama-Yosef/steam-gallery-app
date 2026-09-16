// tool/db_tests/phase10_payment_architecture_test.mjs
//
// Phase 10 (0038): payments / payment_attempts / payment_webhook_events —
// the architecture only. No provider is wired up yet (Phase 11/12): the
// point of this phase is that nothing except service_role can ever write a
// "payment succeeded" row, that a provider reference can only ever back one
// payment (replay-proof), and that customers see only their own payments.
//
//   cd tool/db_tests && npm install && npm test

import { setup, ADMIN, CUST_A, CUST_B } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

// ---------------------------------------------------------------- writes are service_role-only
console.log('\n== No one but service_role can write a payment ==');
await as(CUST_A);
ok('customer cannot insert their own "succeeded" payment',
  (await err(`insert into public.payments (customer_id, channel, amount, status)
    values ($1, 'gateway', 100, 'succeeded')`, [CUST_A]))?.includes('permission denied'));
await as(ADMIN);
ok('admin cannot insert a payment directly either (Edge Function / service_role only)',
  (await err(`insert into public.payments (customer_id, channel, amount, status)
    values ($1, 'gateway', 100, 'succeeded')`, [CUST_A]))?.includes('permission denied'));
await as(null);
ok('anon cannot read payments at all',
  (await err(`select * from public.payments`))?.includes('permission denied'));

// Only asSuper() (this harness's stand-in for service_role / a superuser
// migration) can seed rows, exactly like a real Edge Function using the
// service_role key would.
await asSuper();
const pA1 = (await one(`insert into public.payments (customer_id, channel, provider, amount, status, provider_reference)
  values ($1, 'gateway', 'paymob', 250, 'succeeded', 'ref-1') returning id`, [CUST_A])).id;
const pA2 = (await one(`insert into public.payments (customer_id, channel, amount, status)
  values ($1, 'cash_on_delivery', 100, 'pending') returning id`, [CUST_A])).id;
const pB1 = (await one(`insert into public.payments (customer_id, channel, provider, amount, status, provider_reference)
  values ($1, 'gateway', 'paymob', 300, 'succeeded', 'ref-2') returning id`, [CUST_B])).id;

// ---------------------------------------------------------------- ownership
console.log('\n== Customers see only their own payments ==');
await as(CUST_A);
const seenByA = (await q(`select id from public.payments`)).map(r => r.id);
ok('customer A sees exactly their own two payments', seenByA.sort().join() === [pA1, pA2].sort().join());
await as(CUST_B);
ok('customer B does not see A\'s payments', !(await q(`select id from public.payments`)).some(r => r.id === pA1));
await as(ADMIN);
ok('admin sees every payment', (await q(`select id from public.payments`)).length === 3);

// ---------------------------------------------------------------- replay safety
console.log('\n== A provider reference can only ever back one payment ==');
await asSuper();
ok('a second payment with the same (provider, reference) is refused',
  (await err(`insert into public.payments (customer_id, channel, provider, amount, status, provider_reference)
    values ($1, 'gateway', 'paymob', 999, 'succeeded', 'ref-1')`, [CUST_B]))?.includes('duplicate key'));
ok('the same reference under a different provider is fine (they are different providers\' ids)',
  (await err(`insert into public.payments (customer_id, channel, provider, amount, status, provider_reference)
    values ($1, 'gateway', 'fawry', 50, 'succeeded', 'ref-1')`, [CUST_B])) === null);

// ---------------------------------------------------------------- attempts + webhook events
console.log('\n== payment_attempts is append-only ==');
await asSuper();
const att1 = (await one(`insert into public.payment_attempts (payment_id, attempt_no, status, failure_reason)
  values ($1, 1, 'failed', 'insufficient funds') returning id`, [pA2])).id;
await q(`insert into public.payment_attempts (payment_id, attempt_no, status) values ($1, 2, 'succeeded')`, [pA2]);
ok('an attempt row cannot be edited',
  (await err(`update public.payment_attempts set status = 'succeeded' where id = $1`, [att1]))?.includes('immutable'));
ok('an attempt row cannot be deleted',
  (await err(`delete from public.payment_attempts where id = $1`, [att1]))?.includes('immutable'));
ok('a duplicate attempt_no for the same payment is refused',
  (await err(`insert into public.payment_attempts (payment_id, attempt_no, status) values ($1, 2, 'failed')`, [pA2]))?.includes('duplicate key'));

await as(CUST_A);
ok('a customer cannot read attempt history (admin/support detail, not customer-facing)',
  (await q(`select id from public.payment_attempts`)).length === 0);
await as(ADMIN);
ok('admin can read attempts', (await q(`select id from public.payment_attempts where payment_id = $1`, [pA2])).length === 2);

console.log('\n== payment_webhook_events: idempotent by (provider, event_id), core fields immutable ==');
await asSuper();
const evt = (await one(`insert into public.payment_webhook_events (provider, event_id, payload)
  values ('paymob', 'evt-1', '{"status":"succeeded"}'::jsonb) returning id`)).id;
ok('the same (provider, event_id) cannot be inserted twice — a replayed webhook is caught here',
  (await err(`insert into public.payment_webhook_events (provider, event_id, payload)
    values ('paymob', 'evt-1', '{"status":"succeeded"}'::jsonb)`))?.includes('duplicate key'));
ok('marking an event processed is allowed',
  (await err(`update public.payment_webhook_events set processed_at = now() where id = $1`, [evt])) === null);
ok('changing the original payload afterwards is refused',
  (await err(`update public.payment_webhook_events set payload = '{"status":"tampered"}'::jsonb where id = $1`, [evt]))?.includes('only processed_at/processing_error may change'));
ok('changing event_id afterwards is refused',
  (await err(`update public.payment_webhook_events set event_id = 'evt-2' where id = $1`, [evt]))?.includes('only processed_at/processing_error may change'));
ok('deleting a webhook event is refused',
  (await err(`delete from public.payment_webhook_events where id = $1`, [evt]))?.includes('immutable'));

await as(ADMIN);
ok('admin can read webhook events for support/diagnostics',
  (await q(`select id from public.payment_webhook_events where id = $1`, [evt])).length === 1);
await as(CUST_A);
ok('a customer cannot read webhook events at all', (await q(`select id from public.payment_webhook_events`)).length === 0);
await as(null);
ok('anon cannot read webhook events', (await err(`select * from public.payment_webhook_events`))?.includes('permission denied'));

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
