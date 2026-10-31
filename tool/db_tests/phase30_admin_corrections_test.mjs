// tool/db_tests/phase30_admin_corrections_test.mjs
//
// 0091: only admin corrects or deletes expenses, paid salaries and advances,
// and every correction keeps the tills, the "مرتبات" expense and the advance
// balance in step.
//
//   cd tool/db_tests && npm install && node phase30_admin_corrections_test.mjs

import { setup, uid, ADMIN, TECH } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err, mkUser, roleOf } = await setup(process.argv[2]);

const SALES = uid(9);
await mkUser(SALES, 'sales', '+201000000009', 'Sales');
roleOf[SALES] = 'sales';

const num = v => Number(v);
const till = async kind => {
  await asSuper();
  return num((await one(`select coalesce(sum(t.amount), 0) as n from public.cash_transactions t
    join public.cashboxes c on c.id = t.cashbox_id where c.kind = $1 and c.is_active`, [kind])).n);
};
const balance = async e => {
  await asSuper();
  return num((await one(`select advance_balance as n from public.employee_balances where employee_id = $1`, [e])).n);
};
const payroll = async id => {
  await asSuper();
  return await one(`select p.*, x.amount as expense from public.employee_payrolls p
    left join public.expenses x on x.id = p.expense_id where p.id = $1`, [id]);
};
const refused = async (who, sql, params, re = /FORBIDDEN/) => {
  await as(who);
  return re.test(await err(sql, params) ?? '');
};
const month = n => `2026-0${n}-01`;

await as(ADMIN);
await q(`select public.rpc_cashbox_deposit(100000, 'رصيد', 'main')`);
const CAT = (await one(`insert into public.expense_categories (name) values ('تصنيف اختبار') returning id`)).id;
const EMP = (await one(`insert into public.employees (full_name, monthly_salary) values ('معاذ', 8400) returning id`)).id;

console.log('\n== the wrong advance: 6000 deducted that he never took ==');
{
  const main0 = await till('main');
  await as(ADMIN);
  const ADV = (await one(`select public.rpc_employee_advance($1, 6000, '2026-01-10', 'main', null) as id`, [EMP])).id;
  await as(ADMIN);
  const PAY = (await one(`select public.rpc_pay_salary($1, $2, 0, 0, 6000, 'main', null) as id`, [EMP, month(1)])).id;
  ok('till lost 8400 in all', await till('main') === main0 - 8400);

  ok('sales can\'t edit a salary', await refused(SALES, `select public.rpc_edit_payroll($1, 0, 0, 0, null)`, [PAY]));
  ok('sales can\'t delete a salary', await refused(SALES, `select public.rpc_delete_payroll($1, null)`, [PAY]));
  ok('sales can\'t edit an advance', await refused(SALES, `select public.rpc_edit_advance($1, 1, null, null)`, [ADV]));
  ok('sales can\'t delete an advance', await refused(SALES, `select public.rpc_delete_advance($1, null)`, [ADV]));
  ok('a technician can\'t either', await refused(TECH, `select public.rpc_edit_payroll($1, 0, 0, 0, null)`, [PAY]));

  ok('an advance on a salary can\'t be deleted', await refused(ADMIN, `select public.rpc_delete_advance($1, null)`, [ADV], /ADVANCE_ALREADY_DEDUCTED/));
  ok('nor lowered below the deduction', await refused(ADMIN, `select public.rpc_edit_advance($1, 5000, null, null)`, [ADV], /ADVANCE_ALREADY_DEDUCTED/));

  await as(ADMIN);
  let e = await err(`select public.rpc_edit_payroll($1, 0, 0, 0, 'مكانش عليه سلفة')`, [PAY]);
  ok('admin takes the deduction off the salary', !e, e);
  let p = await payroll(PAY);
  ok('net is now 8400', num(p.net_amount) === 8400 && num(p.advance_deduction) === 0);
  ok('the expense is still 8400', num(p.expense) === 8400);
  ok('6000 more left the till', await till('main') === main0 - 14400);

  await as(ADMIN);
  e = await err(`select public.rpc_delete_advance($1, 'اتسجلت بالغلط')`, [ADV]);
  ok('then deletes the advance', !e, e);
  ok('its 6000 is back', await till('main') === main0 - 8400);
  ok('he owes nothing', await balance(EMP) === 0);
  await asSuper();
  ok('both logged', (await one(`select count(*)::int as n from public.audit_logs where action in ('PAYROLL_EDITED', 'ADVANCE_DELETED') and record_id in ($1, $2)`, [PAY, ADV])).n === 2);
}

console.log('\n== absence, bonus and the expense ==');
{
  await as(ADMIN);
  const PAY = (await one(`select public.rpc_pay_salary($1, $2, 0, 0, 0, 'main', null) as id`, [EMP, month(2)])).id;
  const main0 = await till('main');

  await as(ADMIN);
  ok('edit: absence 400, bonus 100', !(await err(`select public.rpc_edit_payroll($1, 400, 100, 0, null)`, [PAY])));
  let p = await payroll(PAY);
  ok('expense follows what he earned', num(p.expense) === 8100);
  ok('300 back in the till', await till('main') === main0 + 300);

  ok('absence above the salary refused', await refused(ADMIN, `select public.rpc_edit_payroll($1, 9000, 0, 0, null)`, [PAY], /INVALID_DEDUCTION/));
  ok('deduction above the balance refused', await refused(ADMIN, `select public.rpc_edit_payroll($1, 0, 0, 500, null)`, [PAY], /ADVANCE_EXCEEDS_BALANCE/));

  await as(ADMIN);
  ok('nothing earned: allowed', !(await err(`select public.rpc_edit_payroll($1, 8400, 0, 0, null)`, [PAY])));
  p = await payroll(PAY);
  ok('and the expense is gone', p.expense_id === null);
  ok('the whole salary is back', await till('main') === main0 + 8400);

  await as(ADMIN);
  ok('restored', !(await err(`select public.rpc_edit_payroll($1, 0, 0, 0, null)`, [PAY])));
  p = await payroll(PAY);
  ok('a new expense is booked', num(p.expense) === 8400);
  ok('and the money left again', await till('main') === main0);
}

console.log('\n== a correction the till can\'t cover ==');
{
  await as(ADMIN);
  const E2 = (await one(`insert into public.employees (full_name, monthly_salary) values ('حمزة', 1000) returning id`)).id;
  await as(ADMIN);
  const ADV = (await one(`select public.rpc_employee_advance($1, 500, null, 'cash', null) as id`, [E2]).catch(() => ({}))).id;
  ok('no drawer money: the advance is refused', !ADV);
  await as(ADMIN);
  await q(`select public.rpc_cashbox_deposit(500, 'x', 'cash')`);
  await as(ADMIN);
  const A2 = (await one(`select public.rpc_employee_advance($1, 500, null, 'cash', null) as id`, [E2])).id;
  ok('raising past the balance refused', await refused(ADMIN, `select public.rpc_edit_advance($1, 900, null, null)`, [A2], /INSUFFICIENT_CASH/));
  await as(ADMIN);
  ok('lowering is fine', !(await err(`select public.rpc_edit_advance($1, 200, '2026-02-02', 'صح')`, [A2])));
  ok('300 back in the drawer', await till('cash') === 300);
  ok('he owes 200', await balance(E2) === 200);
}

console.log('\n== cancelling a salary ==');
{
  await as(ADMIN);
  const ADV = (await one(`select public.rpc_employee_advance($1, 1000, null, 'main', null) as id`, [EMP])).id;
  await as(ADMIN);
  const PAY = (await one(`select public.rpc_pay_salary($1, $2, 0, 0, 1000, 'main', null) as id`, [EMP, month(3)])).id;
  const main0 = await till('main');
  await asSuper();
  const X = (await one(`select expense_id from public.employee_payrolls where id = $1`, [PAY])).expense_id;

  ok('its expense can\'t be deleted alone', await refused(ADMIN, `select public.rpc_delete_expense($1, null)`, [X], /EXPENSE_IS_PAYROLL/));

  await as(ADMIN);
  const e = await err(`select public.rpc_delete_payroll($1, 'غلط')`, [PAY]);
  ok('admin cancels it', !e, e);
  ok('the net is back', await till('main') === main0 + 7400);
  ok('the advance is owed again', await balance(EMP) === 1000);
  await asSuper();
  ok('the expense is gone', (await q(`select 1 from public.expenses where id = $1`, [X])).length === 0);
  await as(ADMIN);
  ok('the month can be paid again', !(await err(`select public.rpc_pay_salary($1, $2, 0, 0, 1000, 'main', null)`, [EMP, month(3)])));
  ok('ADV still there', !!ADV);
}

console.log('\n== deleting an expense ==');
{
  await as(ADMIN);
  await q(`select public.rpc_cashbox_deposit(1000, 'x', 'cash')`);
  const cash0 = await till('cash');
  await as(SALES);
  const X = (await one(`select public.rpc_record_expense($1, 100, current_date, 'كهرباء', null, 'cash') as id`, [CAT])).id;
  ok('sales still records an expense', await till('cash') === cash0 - 100);

  ok('sales can\'t edit one', await refused(SALES, `select public.rpc_edit_expense($1, null, 150, null, null)`, [X]));
  ok('sales can\'t delete one', await refused(SALES, `select public.rpc_delete_expense($1, null)`, [X]));

  await as(ADMIN);
  ok('admin raises it to 150', !(await err(`select public.rpc_edit_expense($1, null, 150, null, null)`, [X])));
  await as(ADMIN);
  const e = await err(`select public.rpc_delete_expense($1, 'مكرر')`, [X]);
  ok('admin deletes it', !e, e);
  ok('the full 150 is back', await till('cash') === cash0);
  await asSuper();
  ok('gone from the expenses', (await q(`select 1 from public.expenses where id = $1`, [X])).length === 0);
  ok('logged', (await one(`select count(*)::int as n from public.audit_logs where action = 'EXPENSE_DELETED' and record_id = $1`, [X])).n === 1);
  await as(ADMIN);
  ok('twice: not found', /EXPENSE_NOT_FOUND/.test(await err(`select public.rpc_delete_expense($1, null)`, [X]) ?? ''));
}

console.log('\n== still immutable outside the RPCs ==');
{
  await asSuper();
  ok('payrolls', /immutable/.test(await err(`update public.employee_payrolls set net_amount = 0`) ?? ''));
  ok('advances', /immutable/.test(await err(`delete from public.employee_advances`) ?? ''));
  ok('expenses', /immutable/.test(await err(`delete from public.expenses`) ?? ''));
}

finish();
