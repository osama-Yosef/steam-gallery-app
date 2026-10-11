// tool/db_tests/phase22_tills_employees_test.mjs
//
// 0079..0081: four tills (main / drawer / CIB / Vodafone Cash) and transfers
// between them, the 'wallet' payment method, several expense lines at once,
// opening stock, and employees (attendance, advances, salary payments).
//
//   cd tool/db_tests && npm install && node phase22_tills_employees_test.mjs

import { randomUUID } from 'node:crypto';
import { setup, ADMIN, TECH } from './harness.mjs';

const { ok, finish, as, asSuper, q, one, err } = await setup(process.argv[2]);

const till = async (kind) => {
  await asSuper();
  return Number((await one(
    `select coalesce(sum(ct.amount), 0)::numeric as b
     from public.cash_transactions ct join public.cashboxes cb on cb.id = ct.cashbox_id
     where cb.kind = $1 and cb.is_active`, [kind])).b);
};

console.log('\n== Four tills ==');
{
  await asSuper();
  const kinds = (await q(`select kind from public.cashboxes where is_active order by kind`)).map(r => r.kind);
  ok('one active till per kind: cash, main, transfer, wallet', JSON.stringify(kinds) === '["cash","main","transfer","wallet"]', JSON.stringify(kinds));
  const names = Object.fromEntries((await q(`select kind, name from public.cashboxes where is_active`)).map(r => [r.kind, r.name]));
  ok('tills are named for the shop', names.cash === 'خزنة الدرج' && names.main === 'الخزنة الرئيسية'
    && names.transfer === 'حساب CIB' && names.wallet === 'فودافون كاش', JSON.stringify(names));
  const left = await one(`select count(*)::int as n from pg_proc where prosrc like '%else ''transfer'' end%'`);
  ok('no RPC still maps "anything not cash" to the transfer till inline', left.n === 0);
}

console.log('\n== Wallet payments land in the wallet till ==');
await as(ADMIN);
const P = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T22', 'مكواة', 50, 200) returning id`)).id;
await q(`select public.rpc_receive_purchase($1, 10, 50, 'seed')`, [P]);
const sell = async (method) => {
  await as(ADMIN);
  return (await one(`select public.rpc_admin_walk_in_sale(null, null, $1, $2, 0, $3, null) as id`,
    [JSON.stringify([{ product_id: P, quantity: 1 }]), method, randomUUID()])).id;
};
{
  const w0 = await till('wallet'), c0 = await till('cash'), t0 = await till('transfer');
  const saleId = await sell('wallet');
  ok('wallet sale +200 in فودافون كاش', await till('wallet') === w0 + 200);
  ok('cash and CIB untouched', await till('cash') === c0 && await till('transfer') === t0);
  await sell('cash');
  ok('cash sale still goes to the drawer', await till('cash') === c0 + 200);
  await sell('transfer');
  ok('bank transfer sale still goes to CIB', await till('transfer') === t0 + 200);

  await as(ADMIN);
  const item = await one(`select id from public.sale_items where sale_id = $1`, [saleId]);
  await q(`select public.rpc_return_sale_item($1, 1, 'مرتجع')`, [item.id]);
  ok('returning a wallet sale refunds the wallet till by default', await till('wallet') === w0);
}

console.log('\n== Transfers between tills ==');
{
  await as(ADMIN);
  await q(`select public.rpc_cashbox_deposit(1000, 'عهدة', 'main')`);
  ok('deposit into the main safe', await till('main') === 1000);
  const c0 = await till('cash');
  await as(ADMIN);
  await q(`select public.rpc_cashbox_transfer('main', 'cash', 300, 'فكة للدرج')`);
  ok('main -300', await till('main') === 700);
  ok('drawer +300', await till('cash') === c0 + 300);
  await asSuper();
  const rows = await q(`select transaction_type, reference_type from public.cash_transactions where reference_type = 'cashbox_transfer'`);
  ok('booked as a pair of adjustments, not income/expense', rows.length === 2 && rows.every(r => r.transaction_type === 'adjustment'));

  await as(ADMIN);
  ok('more than the till holds is refused', /INSUFFICIENT_CASH/.test(await err(`select public.rpc_cashbox_transfer('main', 'wallet', 5000, null)`)));
  ok('same till both sides is refused', /SAME_CASHBOX/.test(await err(`select public.rpc_cashbox_transfer('main', 'main', 1, null)`)));
  ok('unknown till refused', /INVALID_INPUT/.test(await err(`select public.rpc_cashbox_transfer('main', 'bank', 1, null)`)));
  await as(TECH);
  ok('a technician cannot move till money', /FORBIDDEN/.test(await err(`select public.rpc_cashbox_transfer('main', 'cash', 1, null)`)));

  await as(ADMIN);
  const id = randomUUID();
  const params = JSON.stringify({ p_from_kind: 'main', p_to_kind: 'transfer', p_amount: 100, p_notes: 'إيداع بنك' });
  await q(`select public.rpc_replay($1, 'rpc_cashbox_transfer', $2)`, [id, params]);
  await q(`select public.rpc_replay($1, 'rpc_cashbox_transfer', $2)`, [id, params]);
  ok('an offline transfer sent twice moves the money once', await till('main') === 600);
}

console.log('\n== Several expense lines at once ==');
{
  await asSuper();
  const cats = await q(`select id, name from public.expense_categories where is_active order by name limit 2`);
  const before = await till('main');
  const n0 = Number((await one(`select count(*)::int as n from public.expenses`)).n);
  await as(ADMIN);
  await q(`select public.rpc_record_expenses($1, current_date, 'main')`, [JSON.stringify([
    { category_id: cats[0].id, amount: 50, notes: 'لمبات' },
    { category_id: cats[1].id, amount: 25.5 },
  ])]);
  await asSuper();
  ok('two expense rows', Number((await one(`select count(*)::int as n from public.expenses`)).n) === n0 + 2);
  ok('main safe -75.5', await till('main') === before - 75.5);

  await as(ADMIN);
  const e = await err(`select public.rpc_record_expenses($1, current_date, 'main')`, [JSON.stringify([
    { category_id: cats[0].id, amount: 10 },
    { category_id: cats[1].id, amount: -1 },
  ])]);
  await asSuper();
  ok('one bad line refuses the whole batch', /INVALID_AMOUNT/.test(e)
    && Number((await one(`select count(*)::int as n from public.expenses`)).n) === n0 + 2);
}

console.log('\n== Opening stock ==');
{
  await as(ADMIN);
  const Q = (await one(`insert into public.products (sku, name, cost_price, selling_price) values ('T22B', 'غلاية', 80, 150) returning id`)).id;
  const S = (await one(`select id from public.products where sku = 'SERVICE-MAINT'`))?.id;
  const cash0 = await till('cash');
  await as(ADMIN);
  await q(`select public.rpc_admin_opening_stock($1, null)`, [JSON.stringify([{ product_id: Q, quantity: 7, unit_cost: 90 }])]);
  await asSuper();
  ok('warehouse has the opening quantity', Number((await one(`select quantity from public.warehouse_stock where product_id = $1`, [Q])).quantity) === 7);
  const m = await one(`select movement_type, unit_cost, notes from public.stock_movements where product_id = $1`, [Q]);
  ok('recorded as an opening balance movement', m.movement_type === 'opening_balance' && Number(m.unit_cost) === 90 && m.notes === 'رصيد افتتاحي');
  ok('the given cost becomes the cost price', Number((await one(`select cost_price from public.products where id = $1`, [Q])).cost_price) === 90);
  ok('no money moved', await till('cash') === cash0);
  if (S) {
    await as(ADMIN);
    ok('a service line has no stock', /NOT_A_STOCK_PRODUCT/.test(await err(`select public.rpc_admin_opening_stock($1, null)`, [JSON.stringify([{ product_id: S, quantity: 1 }])])));
  }
  await as(TECH);
  ok('admin only', /FORBIDDEN/.test(await err(`select public.rpc_admin_opening_stock($1, null)`, [JSON.stringify([{ product_id: Q, quantity: 1 }])])));
}

console.log('\n== Employees ==');
{
  await as(ADMIN);
  const E = (await one(`insert into public.employees (full_name, job_title, monthly_salary) values ('محمود', 'بائع', 6000) returning id`)).id;
  await as(TECH);
  ok('a technician sees no employees', (await q(`select * from public.employees`)).length === 0);
  ok('nor can add one', (await err(`insert into public.employees (full_name) values ('x')`)) !== null);

  await as(ADMIN);
  const month = '2026-09-01';
  for (const [d, s] of [['2026-09-01', 'present'], ['2026-09-02', 'absent'], ['2026-09-03', 'absent'], ['2026-09-04', 'late'], ['2026-08-31', 'absent']]) {
    await q(`insert into public.employee_attendance (employee_id, work_date, status) values ($1, $2, $3)
             on conflict (employee_id, work_date) do update set status = excluded.status`, [E, d, s]);
  }
  await q(`insert into public.employee_attendance (employee_id, work_date, status) values ($1, '2026-09-04', 'present')
           on conflict (employee_id, work_date) do update set status = excluded.status`, [E]);
  ok('one attendance mark per day, editable', Number((await one(`select count(*)::int as n from public.employee_attendance where employee_id = $1 and work_date = '2026-09-04' and status = 'present'`, [E])).n) === 1);

  const cash0 = await till('cash');
  await as(ADMIN);
  await q(`select public.rpc_employee_advance($1, 500, '2026-09-10', 'cash', 'ظرف')`, [E]);
  ok('advance leaves the drawer', await till('cash') === cash0 - 500);
  await asSuper();
  ok('as a balance-only withdrawal', (await one(`select transaction_type from public.cash_transactions where reference_type = 'employee_advance'`)).transaction_type === 'other_expense');
  await as(ADMIN);
  ok('advance balance 500', Number((await one(`select advance_balance from public.employee_balances where employee_id = $1`, [E])).advance_balance) === 500);
  ok('an advance bigger than the till is refused', /INSUFFICIENT_CASH/.test(await err(`select public.rpc_employee_advance($1, 999999, null, 'cash', null)`, [E])));

  const pv = (await one(`select public.rpc_payroll_preview($1, '2026-09-15') as p`, [E])).p;
  ok('preview counts September only', pv.absent_days === 2 && pv.present_days === 2 && pv.period_month === '2026-09-01', JSON.stringify(pv));
  ok('suggested deduction = 2 days of 6000/30', Number(pv.absence_deduction) === 400);
  ok('preview shows the advance balance', Number(pv.advance_balance) === 500 && pv.already_paid === false);

  ok('deducting more advance than owed is refused',
    /ADVANCE_EXCEEDS_BALANCE/.test(await err(`select public.rpc_pay_salary($1, $2, 400, 0, 600, 'main', null)`, [E, month])));

  await as(ADMIN);
  await q(`select public.rpc_cashbox_deposit(10000, 'مرتبات', 'main')`);
  const main0 = await till('main');
  await asSuper();
  const exp0 = Number((await one(`select coalesce(sum(amount),0)::numeric as s from public.expenses`)).s);
  await as(ADMIN);
  await q(`select public.rpc_pay_salary($1, $2, 400, 100, 500, 'main', 'مكافأة جرد')`, [E, month]);
  // earned = 6000 - 400 + 100 = 5700; net = 5700 - 500 = 5200
  ok('only the net leaves the till', await till('main') === main0 - 5200);
  await asSuper();
  ok('the earned salary is the expense', Number((await one(`select coalesce(sum(amount),0)::numeric as s from public.expenses`)).s) === exp0 + 5700);
  const pr = await one(`select p.*, c.name as cat from public.employee_payrolls p join public.expenses x on x.id = p.expense_id join public.expense_categories c on c.id = x.category_id`);
  ok('payroll snapshot', Number(pr.net_amount) === 5200 && pr.absent_days === 2 && pr.cat === 'مرتبات');
  await as(ADMIN);
  ok('advance settled', Number((await one(`select advance_balance from public.employee_balances where employee_id = $1`, [E])).advance_balance) === 0);
  ok('the same month cannot be paid twice', /SALARY_ALREADY_PAID/.test(await err(`select public.rpc_pay_salary($1, '2026-09-20', 0, 0, 0, 'main', null)`, [E])));
  ok('preview now says paid', (await one(`select public.rpc_payroll_preview($1, $2) as p`, [E, month])).p.already_paid === true);
  await asSuper();
  ok('payroll rows are immutable (ledger trigger)', /immutable/.test(await err(`update public.employee_payrolls set net_amount = 0`)));

  await as(TECH);
  ok('payroll is admin only', /FORBIDDEN/.test(await err(`select public.rpc_pay_salary($1, '2026-10-01', 0, 0, 0, 'main', null)`, [E])));
}

finish();
