-- ============================================================================
-- 0028_cashbox_deposit_withdrawal.sql
--
-- Manual cash in / cash out on the till.
--
-- The owner needs to put money into the till (float at the start of the day,
-- a personal top-up) and take money out of it (drawings, moving cash to the
-- bank) WITHOUT either one landing in the profit figures.
--
-- That constraint is what picks the implementation: these two RPCs write to
-- `cash_transactions` and to NOTHING else. In particular they never touch
-- `expenses`, `sales` or `orders`, and that is exactly why they stay out of
-- every profit number in the app:
--
--   * Reports → صافي الربح  = (sales/orders revenue - COGS) - sum(expenses)
--   * Dashboard → صافي ربح الشهر = daily_sales_summary - sum(expenses)
--
-- Neither expression reads `cash_transactions`, so an `other_income` /
-- `other_expense` row moves the till balance (`cashbox_balances` sums
-- `cash_transactions.amount`) and leaves revenue, COGS and expenses alone.
-- If a future report ever starts computing profit from the cashbox instead,
-- it MUST exclude these two transaction types.
--
-- The `other_income` / `other_expense` enum members already existed in 0001
-- and were unused; this is what they were reserved for.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Deposit — cash added to the till from outside the business cycle.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_cashbox_deposit(
  p_amount numeric,
  p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_cashbox_id uuid;
  v_txn_id uuid;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;

  select id into v_cashbox_id from public.cashboxes where is_active limit 1;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

  insert into public.cash_transactions
    (cashbox_id, transaction_type, amount, reference_type, notes, created_by)
  values
    (v_cashbox_id, 'other_income', p_amount, 'manual_deposit',
     coalesce(nullif(btrim(p_notes), ''), 'إيداع نقدي'), auth.uid())
  returning id into v_txn_id;

  return v_txn_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- Withdrawal — cash taken out of the till.
--
-- Refuses to overdraw. A till that reports a negative balance is a bookkeeping
-- error nobody can unwind afterwards (cash_transactions is append-only), so
-- the check has to happen before the write, under a row lock on the cashbox so
-- two concurrent withdrawals can't both pass it.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_cashbox_withdraw(
  p_amount numeric,
  p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_cashbox_id uuid;
  v_balance numeric(14,2);
  v_txn_id uuid;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;

  select id into v_cashbox_id from public.cashboxes where is_active limit 1 for update;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

  select coalesce(sum(amount), 0) into v_balance
    from public.cash_transactions where cashbox_id = v_cashbox_id;

  if p_amount > v_balance then
    raise exception 'INSUFFICIENT_CASH: %', v_balance;
  end if;

  insert into public.cash_transactions
    (cashbox_id, transaction_type, amount, reference_type, notes, created_by)
  values
    (v_cashbox_id, 'other_expense', -p_amount, 'manual_withdrawal',
     coalesce(nullif(btrim(p_notes), ''), 'سحب نقدي'), auth.uid())
  returning id into v_txn_id;

  return v_txn_id;
end;
$$;
