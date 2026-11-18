// tool/db_tests/phase36_offline_complete_maintenance_test.mjs
//
// 0097: closing a maintenance job can wait offline on the technician's
// phone and be sent later. A sent-twice close (first answer lost) must not
// come back as "not in progress" — rpc_replay runs it once per request id.
//
//   cd tool/db_tests && npm install && node phase36_offline_complete_maintenance_test.mjs

import { setup, uid, TECH, TECH2, CUST_A } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

const request = async (tech, status = 'in_progress') => {
  await asSuper();
  return (await one(`insert into public.maintenance_requests
      (customer_id, customer_name, phone, problem_description, status, assigned_technician_id)
    values ($1, 'أ', '01012345678', 'عطل', $2, $3) returning id`, [CUST_A, status, tech])).id;
};
const statusOf = async id => {
  await asSuper();
  return (await one(`select status, notes from public.maintenance_requests where id = $1`, [id]));
};
const replay = (rid, params) =>
  one(`select public.rpc_replay($1, 'rpc_complete_maintenance', $2::jsonb) as r`, [rid, JSON.stringify(params)]);

console.log('\n== closed through rpc_replay ==');
{
  const M = await request(TECH);
  const RID = uid(901);
  await as(TECH);
  const first = (await replay(RID, { p_request_id: M, p_notes: 'تم' })).r;
  ok('first send closes the job', first.replayed === false && (await statusOf(M)).status === 'completed');
  ok('notes kept', (await statusOf(M)).notes === 'تم');

  await as(TECH);
  const again = await err(`select public.rpc_replay($1, 'rpc_complete_maintenance', $2::jsonb)`,
    [RID, JSON.stringify({ p_request_id: M, p_notes: 'تم' })]);
  ok('the same request sent again is not an error', !again, again);
  await as(TECH);
  ok('…and reports it was already done', (await replay(RID, { p_request_id: M, p_notes: 'تم' })).r.replayed === true);
}

console.log('\n== still checks who may close it ==');
{
  const M = await request(TECH);
  await as(TECH2);
  const e = await err(`select public.rpc_replay($1, 'rpc_complete_maintenance', $2::jsonb)`,
    [uid(902), JSON.stringify({ p_request_id: M, p_notes: null })]);
  ok('another technician is refused', /FORBIDDEN_OR_NOT_IN_PROGRESS/.test(e ?? ''), e);
  ok('job untouched', (await statusOf(M)).status === 'in_progress');

  await as(TECH);
  const retry = await err(`select public.rpc_replay($1, 'rpc_complete_maintenance', $2::jsonb)`,
    [uid(902), JSON.stringify({ p_request_id: M, p_notes: null })]);
  ok('a refused id is released (the call rolled back with it)', !retry, retry);
  ok('the assigned technician closes it', (await statusOf(M)).status === 'completed');
}

console.log('\n== a job that never started ==');
{
  const M = await request(TECH, 'assigned');
  await as(TECH);
  const e = await err(`select public.rpc_replay($1, 'rpc_complete_maintenance', $2::jsonb)`,
    [uid(903), JSON.stringify({ p_request_id: M, p_notes: null })]);
  ok('refused with the usual reason', /FORBIDDEN_OR_NOT_IN_PROGRESS/.test(e ?? ''), e);
}

console.log('\n== the earlier replayable RPCs still work ==');
{
  await as(TECH);
  const e = await err(`select public.rpc_replay($1, 'rpc_nope', '{}'::jsonb)`, [uid(904)]);
  ok('unknown RPCs still refused', /UNSUPPORTED_RPC/.test(e ?? ''), e);
}

finish();
