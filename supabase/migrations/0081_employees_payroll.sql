-- ============================================================================
-- 0081_employees_payroll.sql
--
-- Shop staff (not app users — no login): their monthly salary, attendance,
-- advances (سلف) and monthly salary payments. Admin only.
--
-- Money:
--   * An advance leaves a till at once as 'other_expense' (balance only):
--     it is money the employee owes back, not a cost of the business yet.
--   * Paying a month books the salary actually earned
--     (base - absence deduction + bonus) as an expense under "مرتبات" — so
--     it reaches the profit reports — while only the net
--     (earned - advances deducted) leaves the till now; the advanced part
--     already left when it was given. Till out in total = earned.
--   * advance balance = all advances - all advance deductions on payrolls.
--
-- Absence deduction suggested by rpc_payroll_preview = salary / 30 per
-- absent day; the admin can change it when paying.
--
-- Also restates rpc_replay (0076) so the new money RPCs from 0080/0081
-- can be queued offline and sent once.
-- ============================================================================

create table if not exists public.employees (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (length(btrim(full_name)) between 1 and 200),
  phone text check (length(phone) <= 30),
  job_title text check (length(job_title) <= 100),
  monthly_salary numeric(12,2) not null default 0 check (monthly_salary >= 0),
  hire_date date,
  notes text check (length(notes) <= 1000),
  is_active boolean not null default true,
  created_by uuid references public.users(id) default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.employee_attendance (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.employees(id),
  work_date date not null,
  status text not null check (status in ('present', 'absent', 'late', 'leave')),
  notes text check (length(notes) <= 500),
  recorded_by uuid references public.users(id) default auth.uid(),
  updated_at timestamptz not null default now(),
  unique (employee_id, work_date)
);
create index if not exists idx_employee_attendance_date on public.employee_attendance (work_date);

create table if not exists public.employee_advances (
  id uuid primary key default gen_random_uuid(),
  advance_number bigserial unique,
  employee_id uuid not null references public.employees(id),
  amount numeric(12,2) not null check (amount > 0),
  advance_date date not null default current_date,
  kind text not null check (kind in ('main', 'cash', 'transfer', 'wallet')),
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);
create index if not exists idx_employee_advances_employee on public.employee_advances (employee_id);

create table if not exists public.employee_payrolls (
  id uuid primary key default gen_random_uuid(),
  payroll_number bigserial unique,
  employee_id uuid not null references public.employees(id),
  period_month date not null check (period_month = date_trunc('month', period_month)::date),
  base_salary numeric(12,2) not null check (base_salary >= 0),
  absent_days int not null default 0 check (absent_days >= 0),
  absence_deduction numeric(12,2) not null default 0 check (absence_deduction >= 0),
  bonus numeric(12,2) not null default 0 check (bonus >= 0),
  advance_deduction numeric(12,2) not null default 0 check (advance_deduction >= 0),
  net_amount numeric(12,2) not null check (net_amount >= 0),
  kind text not null check (kind in ('main', 'cash', 'transfer', 'wallet')),
  expense_id uuid references public.expenses(id),
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  unique (employee_id, period_month)
);

drop trigger if exists trg_employee_advances_no_update on public.employee_advances;
create trigger trg_employee_advances_no_update
  before update or delete on public.employee_advances
  for each row execute function public.prevent_mutation();
drop trigger if exists trg_employee_payrolls_no_update on public.employee_payrolls;
create trigger trg_employee_payrolls_no_update
  before update or delete on public.employee_payrolls
  for each row execute function public.prevent_mutation();

alter table public.employees enable row level security;
alter table public.employee_attendance enable row level security;
alter table public.employee_advances enable row level security;
alter table public.employee_payrolls enable row level security;

-- Employees and attendance are plain records the admin edits directly;
-- advances and payrolls move money, so they are written by the RPCs below
-- only (select policy, no write grant).
grant select, insert, update on public.employees to authenticated;
drop policy if exists employees_admin on public.employees;
create policy employees_admin on public.employees for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

grant select, insert, update, delete on public.employee_attendance to authenticated;
drop policy if exists employee_attendance_admin on public.employee_attendance;
create policy employee_attendance_admin on public.employee_attendance for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

grant select on public.employee_advances to authenticated;
drop policy if exists employee_advances_select on public.employee_advances;
create policy employee_advances_select on public.employee_advances for select to authenticated
  using (public.is_admin());

grant select on public.employee_payrolls to authenticated;
drop policy if exists employee_payrolls_select on public.employee_payrolls;
create policy employee_payrolls_select on public.employee_payrolls for select to authenticated
  using (public.is_admin());

create or replace view public.employee_balances
  with (security_invoker = true) as
select e.id as employee_id, e.full_name, e.phone, e.job_title, e.monthly_salary,
  e.hire_date, e.notes, e.is_active, e.created_at,
  coalesce(a.total, 0)::numeric(14,2) as total_advances,
  (coalesce(a.total, 0) - coalesce(p.deducted, 0))::numeric(14,2) as advance_balance,
  p.last_paid_month
from public.employees e
left join (select employee_id, sum(amount) as total from public.employee_advances group by employee_id) a
  on a.employee_id = e.id
left join (
  select employee_id, sum(advance_deduction) as deducted, max(period_month) as last_paid_month
  from public.employee_payrolls group by employee_id
) p on p.employee_id = e.id;

grant select on public.employee_balances to authenticated;

-- ----------------------------------------------------------------------------
-- Advance
-- ----------------------------------------------------------------------------
create or replace function public.rpc_employee_advance(
  p_employee_id uuid, p_amount numeric, p_advance_date date, p_kind text, p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_employee record;
  v_cashbox_id uuid;
  v_balance numeric(14,2);
  v_id uuid;
  v_notes text := nullif(btrim(p_notes), '');
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then raise exception 'INVALID_AMOUNT'; end if;
  if p_kind is null or p_kind not in ('main', 'cash', 'transfer', 'wallet') then raise exception 'INVALID_INPUT'; end if;
  if length(v_notes) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_employee from public.employees where id = p_employee_id;
  if not found then raise exception 'EMPLOYEE_NOT_FOUND'; end if;
  if not v_employee.is_active then raise exception 'EMPLOYEE_INACTIVE'; end if;

  select id into v_cashbox_id from public.cashboxes where kind = p_kind and is_active limit 1 for update;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;
  select coalesce(sum(amount), 0) into v_balance from public.cash_transactions where cashbox_id = v_cashbox_id;
  if p_amount > v_balance then raise exception 'INSUFFICIENT_CASH: %', v_balance; end if;

  insert into public.employee_advances (employee_id, amount, advance_date, kind, notes, created_by)
  values (p_employee_id, p_amount, coalesce(p_advance_date, current_date), p_kind, v_notes, auth.uid())
  returning id into v_id;

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  values (v_cashbox_id, 'other_expense', -p_amount, 'employee_advance', v_id,
          'سلفة ' || v_employee.full_name || coalesce(' · ' || v_notes, ''), auth.uid());

  return v_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- What paying p_month would look like: attendance counts, the suggested
-- absence deduction, the advance balance, and whether it's already paid.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_payroll_preview(p_employee_id uuid, p_month date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_employee record;
  v_month date := date_trunc('month', coalesce(p_month, current_date))::date;
  v_counts record;
  v_advance_balance numeric(14,2);
  v_daily numeric;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  select * into v_employee from public.employees where id = p_employee_id;
  if not found then raise exception 'EMPLOYEE_NOT_FOUND'; end if;

  select
    count(*) filter (where status = 'present') as present,
    count(*) filter (where status = 'absent') as absent,
    count(*) filter (where status = 'late') as late,
    count(*) filter (where status = 'leave') as on_leave
  into v_counts
  from public.employee_attendance
  where employee_id = p_employee_id
    and work_date >= v_month and work_date < (v_month + interval '1 month');

  select advance_balance into v_advance_balance from public.employee_balances where employee_id = p_employee_id;
  v_daily := v_employee.monthly_salary / 30;

  return jsonb_build_object(
    'period_month', v_month,
    'base_salary', v_employee.monthly_salary,
    'present_days', v_counts.present,
    'absent_days', v_counts.absent,
    'late_days', v_counts.late,
    'leave_days', v_counts.on_leave,
    'daily_rate', round(v_daily, 2),
    'absence_deduction', least(v_employee.monthly_salary, round(v_daily * v_counts.absent, 2)),
    'advance_balance', coalesce(v_advance_balance, 0),
    'already_paid', exists (
      select 1 from public.employee_payrolls where employee_id = p_employee_id and period_month = v_month)
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- Pay a month's salary
-- ----------------------------------------------------------------------------
create or replace function public.rpc_pay_salary(
  p_employee_id uuid, p_month date, p_absence_deduction numeric, p_bonus numeric,
  p_advance_deduction numeric, p_kind text, p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_employee record;
  v_month date := date_trunc('month', coalesce(p_month, current_date))::date;
  v_absence numeric(12,2) := coalesce(p_absence_deduction, 0);
  v_bonus numeric(12,2) := coalesce(p_bonus, 0);
  v_advance numeric(12,2) := coalesce(p_advance_deduction, 0);
  v_earned numeric(12,2);
  v_net numeric(12,2);
  v_advance_balance numeric(14,2);
  v_absent_days int;
  v_cashbox_id uuid;
  v_balance numeric(14,2);
  v_category_id uuid;
  v_expense_id uuid;
  v_payroll_id uuid;
  v_notes text := nullif(btrim(p_notes), '');
  v_label text;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if v_absence < 0 or v_bonus < 0 or v_advance < 0
     or v_absence <> round(v_absence, 2) or v_bonus <> round(v_bonus, 2) or v_advance <> round(v_advance, 2) then
    raise exception 'INVALID_AMOUNT';
  end if;
  if p_kind is null or p_kind not in ('main', 'cash', 'transfer', 'wallet') then raise exception 'INVALID_INPUT'; end if;
  if length(v_notes) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_employee from public.employees where id = p_employee_id for update;
  if not found then raise exception 'EMPLOYEE_NOT_FOUND'; end if;
  if exists (select 1 from public.employee_payrolls where employee_id = p_employee_id and period_month = v_month) then
    raise exception 'SALARY_ALREADY_PAID';
  end if;

  if v_absence > v_employee.monthly_salary then raise exception 'INVALID_DEDUCTION'; end if;
  v_earned := v_employee.monthly_salary - v_absence + v_bonus;

  select coalesce(sum(amount), 0) into v_advance_balance from public.employee_advances where employee_id = p_employee_id;
  v_advance_balance := v_advance_balance - coalesce(
    (select sum(advance_deduction) from public.employee_payrolls where employee_id = p_employee_id), 0);
  if v_advance > v_advance_balance then raise exception 'ADVANCE_EXCEEDS_BALANCE'; end if;
  if v_advance > v_earned then raise exception 'INVALID_DEDUCTION'; end if;
  v_net := v_earned - v_advance;

  select count(*) into v_absent_days from public.employee_attendance
    where employee_id = p_employee_id and status = 'absent'
      and work_date >= v_month and work_date < (v_month + interval '1 month');

  v_label := 'مرتب ' || v_employee.full_name || ' عن ' || to_char(v_month, 'YYYY-MM');

  if v_net > 0 then
    select id into v_cashbox_id from public.cashboxes where kind = p_kind and is_active limit 1 for update;
    if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;
    select coalesce(sum(amount), 0) into v_balance from public.cash_transactions where cashbox_id = v_cashbox_id;
    if v_net > v_balance then raise exception 'INSUFFICIENT_CASH: %', v_balance; end if;
  end if;

  if v_earned > 0 then
    insert into public.expense_categories (name) values ('مرتبات') on conflict (name) do nothing;
    select id into v_category_id from public.expense_categories where name = 'مرتبات';
    insert into public.expenses (category_id, amount, expense_date, notes, created_by)
    values (v_category_id, v_earned, current_date, v_label || coalesce(' · ' || v_notes, ''), auth.uid())
    returning id into v_expense_id;
  end if;

  insert into public.employee_payrolls (employee_id, period_month, base_salary, absent_days, absence_deduction,
    bonus, advance_deduction, net_amount, kind, expense_id, notes, created_by)
  values (p_employee_id, v_month, v_employee.monthly_salary, v_absent_days, v_absence,
    v_bonus, v_advance, v_net, p_kind, v_expense_id, v_notes, auth.uid())
  returning id into v_payroll_id;

  if v_net > 0 then
    insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
    values (v_cashbox_id, 'expense', -v_net, 'employee_payroll', v_payroll_id, v_label, auth.uid());
  end if;

  return v_payroll_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- rpc_replay (0076) + the money RPCs added in 0080/0081.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_replay(p_request_id uuid, p_rpc text, p_params jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  p jsonb := coalesce(p_params, '{}'::jsonb);
  v_result jsonb;
begin
  if auth.uid() is null then raise exception 'FORBIDDEN'; end if;
  if p_request_id is null or p_rpc is null then raise exception 'INVALID_INPUT'; end if;

  insert into private.processed_requests (id, rpc, user_id)
  values (p_request_id, p_rpc, auth.uid())
  on conflict (id) do nothing;
  if not found then
    return jsonb_build_object('replayed', true);
  end if;

  case p_rpc
    when 'rpc_record_expense' then
      v_result := to_jsonb(public.rpc_record_expense(
        (p ->> 'p_category_id')::uuid, (p ->> 'p_amount')::numeric, (p ->> 'p_expense_date')::date,
        p ->> 'p_notes', p ->> 'p_attachment_url', coalesce(p ->> 'p_kind', 'cash')));
    when 'rpc_record_expenses' then
      v_result := public.rpc_record_expenses(
        p -> 'p_items', (p ->> 'p_expense_date')::date, coalesce(p ->> 'p_kind', 'cash'));
    when 'rpc_cashbox_deposit' then
      v_result := to_jsonb(public.rpc_cashbox_deposit(
        (p ->> 'p_amount')::numeric, p ->> 'p_notes', coalesce(p ->> 'p_kind', 'cash')));
    when 'rpc_cashbox_withdraw' then
      v_result := to_jsonb(public.rpc_cashbox_withdraw(
        (p ->> 'p_amount')::numeric, p ->> 'p_notes', coalesce(p ->> 'p_kind', 'cash')));
    when 'rpc_cashbox_transfer' then
      v_result := to_jsonb(public.rpc_cashbox_transfer(
        p ->> 'p_from_kind', p ->> 'p_to_kind', (p ->> 'p_amount')::numeric, p ->> 'p_notes'));
    when 'rpc_employee_advance' then
      v_result := to_jsonb(public.rpc_employee_advance(
        (p ->> 'p_employee_id')::uuid, (p ->> 'p_amount')::numeric, (p ->> 'p_advance_date')::date,
        p ->> 'p_kind', p ->> 'p_notes'));
    when 'rpc_pay_salary' then
      v_result := to_jsonb(public.rpc_pay_salary(
        (p ->> 'p_employee_id')::uuid, (p ->> 'p_month')::date, (p ->> 'p_absence_deduction')::numeric,
        (p ->> 'p_bonus')::numeric, (p ->> 'p_advance_deduction')::numeric, p ->> 'p_kind', p ->> 'p_notes'));
    when 'rpc_confirm_order' then
      perform public.rpc_confirm_order((p ->> 'p_order_id')::uuid);
    when 'rpc_update_order_status' then
      perform public.rpc_update_order_status((p ->> 'p_order_id')::uuid, (p ->> 'p_new_status')::order_status);
    when 'rpc_cancel_order' then
      perform public.rpc_cancel_order((p ->> 'p_order_id')::uuid, p ->> 'p_reason');
    when 'rpc_admin_return_order' then
      perform public.rpc_admin_return_order((p ->> 'p_order_id')::uuid, p ->> 'p_reason');
    when 'rpc_admin_set_shipping_fee' then
      perform public.rpc_admin_set_shipping_fee((p ->> 'p_order_id')::uuid, (p ->> 'p_amount')::numeric);
    else
      raise exception 'UNSUPPORTED_RPC: %', p_rpc;
  end case;

  return jsonb_build_object('replayed', false, 'result', v_result);
end;
$$;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_employee_advance', 'admin'),
  ('rpc_payroll_preview', 'admin'),
  ('rpc_pay_salary', 'admin')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
