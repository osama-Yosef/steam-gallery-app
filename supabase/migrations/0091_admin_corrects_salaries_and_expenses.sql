-- ============================================================================
-- 0091_admin_corrects_salaries_and_expenses.sql
--
-- Admin only — sales can no longer change a recorded expense:
--
--   rpc_edit_expense     (0087) now admin only
--   rpc_delete_expense   removes an expense; its money goes back to its till
--   rpc_edit_payroll     corrects a paid salary's absence deduction, bonus,
--                        advance deduction and note
--   rpc_delete_payroll   cancels a paid salary, so the month can be paid again
--   rpc_edit_advance     corrects an advance's amount, date and note
--   rpc_delete_advance   removes an advance given by mistake
--
-- Each one keeps the books consistent with 0081: the "مرتبات" expense equals
-- the salary earned, and the money that left the till equals the net (plus
-- the advance, when it was given). A difference moves through the till the
-- payment used: more paid out is checked against the balance, money back is
-- an 'adjustment'. cash_transactions stays append-only, so the history of
-- the mistake and of its correction both remain; audit_logs keeps the before
-- and after of every change.
--
-- A salary's expense is corrected through its payroll — its till movement
-- belongs to the payroll, not the expense — so rpc_edit_expense and
-- rpc_delete_expense refuse it (EXPENSE_IS_PAYROLL).
--
-- An advance already deducted from a salary can't drop below what was
-- deducted (ADVANCE_ALREADY_DEDUCTED): correct that salary first.
--
-- expenses, employee_payrolls and employee_advances stay immutable except
-- inside these RPCs, flagged for their own transaction only (as 0087).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. The ledgers open only for a flagged transaction.
-- ----------------------------------------------------------------------------
create or replace function private.prevent_expense_mutation()
returns trigger language plpgsql as $$
begin
  if current_setting('app.expense_edit', true) = 'on' then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  raise exception 'Ledger rows are immutable: % on % is not allowed', tg_op, tg_table_name;
end;
$$;

create or replace function private.prevent_payroll_mutation()
returns trigger language plpgsql as $$
begin
  if current_setting('app.payroll_edit', true) = 'on' then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  raise exception 'Ledger rows are immutable: % on % is not allowed', tg_op, tg_table_name;
end;
$$;

drop trigger if exists trg_employee_advances_no_update on public.employee_advances;
create trigger trg_employee_advances_no_update
  before update or delete on public.employee_advances
  for each row execute function private.prevent_payroll_mutation();
drop trigger if exists trg_employee_payrolls_no_update on public.employee_payrolls;
create trigger trg_employee_payrolls_no_update
  before update or delete on public.employee_payrolls
  for each row execute function private.prevent_payroll_mutation();

-- ----------------------------------------------------------------------------
-- 2. Money between a till and a correction. p_out > 0 leaves the till of
--    [p_kind] (checked against its balance), p_out < 0 comes back to it.
-- ----------------------------------------------------------------------------
create or replace function private.fn_till_correction(
  p_kind text, p_out numeric, p_out_type cash_txn_type,
  p_reference_type text, p_reference_id uuid, p_note text
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_cashbox_id uuid;
  v_balance numeric(14,2);
begin
  if p_out = 0 then return; end if;
  select id into v_cashbox_id from public.cashboxes where kind = p_kind and is_active limit 1 for update;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

  if p_out > 0 then
    select coalesce(sum(amount), 0) into v_balance from public.cash_transactions where cashbox_id = v_cashbox_id;
    if p_out > v_balance then raise exception 'INSUFFICIENT_CASH: %', v_balance; end if;
    insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
    values (v_cashbox_id, p_out_type, -p_out, p_reference_type, p_reference_id, p_note, auth.uid());
  else
    insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
    values (v_cashbox_id, 'adjustment', -p_out, p_reference_type, p_reference_id, p_note, auth.uid());
  end if;
end;
$$;
revoke all on function private.fn_till_correction(text, numeric, cash_txn_type, text, uuid, text) from public, anon, authenticated;

-- Advances given minus advances deducted, leaving out [p_except_payroll].
create or replace function private.fn_employee_advance_left(p_employee_id uuid, p_except_payroll uuid default null)
returns numeric language sql stable security definer set search_path = public as $$
  select (coalesce((select sum(amount) from public.employee_advances where employee_id = p_employee_id), 0)
        - coalesce((select sum(advance_deduction) from public.employee_payrolls
                    where employee_id = p_employee_id and id is distinct from p_except_payroll), 0))::numeric(14,2);
$$;
revoke all on function private.fn_employee_advance_left(uuid, uuid) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- 3. Expenses
-- ----------------------------------------------------------------------------
do $patch$
declare
  v_def text := pg_get_functiondef('public.rpc_edit_expense(uuid, uuid, numeric, date, text)'::regprocedure);
  v_old text := 'if not (public.is_admin() or public.is_sales()) then';
begin
  if strpos(v_def, v_old) = 0 then
    raise exception '0091: rpc_edit_expense role check not found';
  end if;
  execute replace(v_def, v_old, 'if not public.is_admin() then');
end
$patch$;

create or replace function public.rpc_delete_expense(p_expense_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_exp record;
  v_row record;
  v_note text;
  v_found boolean := false;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_exp from public.expenses where id = p_expense_id for update;
  if not found then raise exception 'EXPENSE_NOT_FOUND'; end if;
  if exists (select 1 from public.employee_payrolls where expense_id = p_expense_id) then
    raise exception 'EXPENSE_IS_PAYROLL';
  end if;

  v_note := 'حذف مصروف #' || v_exp.expense_number || coalesce(' · ' || nullif(btrim(p_reason), ''), '');

  -- What it took out of each till, its earlier edits included.
  for v_row in
    select cashbox_id, -sum(amount) as held from public.cash_transactions
    where reference_type = 'expense' and reference_id = p_expense_id
    group by cashbox_id
  loop
    v_found := true;
    if v_row.held <> 0 then
      insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
      values (v_row.cashbox_id, 'adjustment', v_row.held, 'expense', p_expense_id, v_note, auth.uid());
    end if;
  end loop;
  -- The drawer if it can't be told, as rpc_edit_expense.
  if not v_found then
    perform private.fn_till_correction('cash', -v_exp.amount, 'expense', 'expense', p_expense_id, v_note);
  end if;

  perform set_config('app.expense_edit', 'on', true);
  delete from public.expenses where id = p_expense_id;
  perform set_config('app.expense_edit', 'off', true);

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'EXPENSE_DELETED', 'expenses', p_expense_id, to_jsonb(v_exp), null);
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Paid salaries
-- ----------------------------------------------------------------------------
create or replace function public.rpc_edit_payroll(
  p_payroll_id uuid, p_absence_deduction numeric, p_bonus numeric,
  p_advance_deduction numeric, p_notes text
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_payroll record;
  v_employee record;
  v_absence numeric(12,2) := coalesce(p_absence_deduction, 0);
  v_bonus numeric(12,2) := coalesce(p_bonus, 0);
  v_advance numeric(12,2) := coalesce(p_advance_deduction, 0);
  v_earned numeric(12,2);
  v_net numeric(12,2);
  v_expense_id uuid;
  v_category_id uuid;
  v_notes text := nullif(btrim(p_notes), '');
  v_label text;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if v_absence < 0 or v_bonus < 0 or v_advance < 0
     or v_absence <> round(v_absence, 2) or v_bonus <> round(v_bonus, 2) or v_advance <> round(v_advance, 2) then
    raise exception 'INVALID_AMOUNT';
  end if;
  if length(v_notes) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_payroll from public.employee_payrolls where id = p_payroll_id;
  if not found then raise exception 'PAYROLL_NOT_FOUND'; end if;
  select * into v_employee from public.employees where id = v_payroll.employee_id for update;

  if v_absence > v_payroll.base_salary then raise exception 'INVALID_DEDUCTION'; end if;
  v_earned := v_payroll.base_salary - v_absence + v_bonus;
  if v_advance > private.fn_employee_advance_left(v_payroll.employee_id, p_payroll_id) then
    raise exception 'ADVANCE_EXCEEDS_BALANCE';
  end if;
  if v_advance > v_earned then raise exception 'INVALID_DEDUCTION'; end if;
  v_net := v_earned - v_advance;
  v_label := 'تعديل مرتب ' || v_employee.full_name || ' عن ' || to_char(v_payroll.period_month, 'YYYY-MM');

  perform private.fn_till_correction(v_payroll.kind, v_net - v_payroll.net_amount, 'expense',
                                     'employee_payroll', p_payroll_id, v_label);

  -- The expense follows the salary earned; nothing earned, no expense.
  v_expense_id := v_payroll.expense_id;
  perform set_config('app.expense_edit', 'on', true);
  if v_expense_id is not null and v_earned > 0 then
    update public.expenses set amount = v_earned where id = v_expense_id;
  elsif v_expense_id is null and v_earned > 0 then
    insert into public.expense_categories (name) values ('مرتبات') on conflict (name) do nothing;
    select id into v_category_id from public.expense_categories where name = 'مرتبات';
    insert into public.expenses (category_id, amount, expense_date, notes, created_by)
    values (v_category_id, v_earned, current_date,
            'مرتب ' || v_employee.full_name || ' عن ' || to_char(v_payroll.period_month, 'YYYY-MM'), auth.uid())
    returning id into v_expense_id;
  end if;

  perform set_config('app.payroll_edit', 'on', true);
  update public.employee_payrolls set
    absence_deduction = v_absence,
    bonus = v_bonus,
    advance_deduction = v_advance,
    net_amount = v_net,
    expense_id = case when v_earned > 0 then v_expense_id end,
    notes = v_notes
  where id = p_payroll_id;
  perform set_config('app.payroll_edit', 'off', true);

  if v_earned = 0 and v_expense_id is not null then
    delete from public.expenses where id = v_expense_id;
  end if;
  perform set_config('app.expense_edit', 'off', true);

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'PAYROLL_EDITED', 'employee_payrolls', p_payroll_id, to_jsonb(v_payroll),
          (select to_jsonb(p) from public.employee_payrolls p where p.id = p_payroll_id));
end;
$$;

create or replace function public.rpc_delete_payroll(p_payroll_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_payroll record;
  v_employee record;
  v_note text;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_payroll from public.employee_payrolls where id = p_payroll_id;
  if not found then raise exception 'PAYROLL_NOT_FOUND'; end if;
  select * into v_employee from public.employees where id = v_payroll.employee_id for update;

  v_note := 'إلغاء مرتب ' || v_employee.full_name || ' عن ' || to_char(v_payroll.period_month, 'YYYY-MM')
            || coalesce(' · ' || nullif(btrim(p_reason), ''), '');
  perform private.fn_till_correction(v_payroll.kind, -v_payroll.net_amount, 'expense',
                                     'employee_payroll', p_payroll_id, v_note);

  perform set_config('app.payroll_edit', 'on', true);
  delete from public.employee_payrolls where id = p_payroll_id;
  perform set_config('app.payroll_edit', 'off', true);

  if v_payroll.expense_id is not null then
    perform set_config('app.expense_edit', 'on', true);
    delete from public.expenses where id = v_payroll.expense_id;
    perform set_config('app.expense_edit', 'off', true);
  end if;

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'PAYROLL_DELETED', 'employee_payrolls', p_payroll_id, to_jsonb(v_payroll), null);
end;
$$;

-- ----------------------------------------------------------------------------
-- 5. Advances
-- ----------------------------------------------------------------------------
create or replace function public.rpc_edit_advance(
  p_advance_id uuid, p_amount numeric, p_advance_date date, p_notes text
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_advance record;
  v_employee record;
  v_notes text := nullif(btrim(p_notes), '');
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then raise exception 'INVALID_AMOUNT'; end if;
  if length(v_notes) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_advance from public.employee_advances where id = p_advance_id;
  if not found then raise exception 'ADVANCE_NOT_FOUND'; end if;
  select * into v_employee from public.employees where id = v_advance.employee_id for update;

  if private.fn_employee_advance_left(v_advance.employee_id) + p_amount - v_advance.amount < 0 then
    raise exception 'ADVANCE_ALREADY_DEDUCTED';
  end if;

  perform private.fn_till_correction(v_advance.kind, p_amount - v_advance.amount, 'other_expense',
                                     'employee_advance', p_advance_id, 'تعديل سلفة ' || v_employee.full_name);

  perform set_config('app.payroll_edit', 'on', true);
  update public.employee_advances set
    amount = p_amount,
    advance_date = coalesce(p_advance_date, advance_date),
    notes = v_notes
  where id = p_advance_id;
  perform set_config('app.payroll_edit', 'off', true);

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'ADVANCE_EDITED', 'employee_advances', p_advance_id, to_jsonb(v_advance),
          (select to_jsonb(a) from public.employee_advances a where a.id = p_advance_id));
end;
$$;

create or replace function public.rpc_delete_advance(p_advance_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_advance record;
  v_employee record;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_advance from public.employee_advances where id = p_advance_id;
  if not found then raise exception 'ADVANCE_NOT_FOUND'; end if;
  select * into v_employee from public.employees where id = v_advance.employee_id for update;

  if private.fn_employee_advance_left(v_advance.employee_id) - v_advance.amount < 0 then
    raise exception 'ADVANCE_ALREADY_DEDUCTED';
  end if;

  perform private.fn_till_correction(v_advance.kind, -v_advance.amount, 'other_expense',
    'employee_advance', p_advance_id,
    'حذف سلفة ' || v_employee.full_name || coalesce(' · ' || nullif(btrim(p_reason), ''), ''));

  perform set_config('app.payroll_edit', 'on', true);
  delete from public.employee_advances where id = p_advance_id;
  perform set_config('app.payroll_edit', 'off', true);

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'ADVANCE_DELETED', 'employee_advances', p_advance_id, to_jsonb(v_advance), null);
end;
$$;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_delete_expense', 'admin'),
  ('rpc_edit_payroll', 'admin'),
  ('rpc_delete_payroll', 'admin'),
  ('rpc_edit_advance', 'admin'),
  ('rpc_delete_advance', 'admin')
on conflict (function_name) do nothing;
update private.rpc_allowlist set note = 'admin' where function_name = 'rpc_edit_expense';

select private.apply_function_grants();
notify pgrst, 'reload schema';
