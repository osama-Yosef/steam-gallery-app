-- ============================================================================
-- 0045_sales_cashbox_withdraw.sql
--
-- Lets the sales role perform a cash withdrawal ("صرف من الخزنة") from the
-- till, without giving it any visibility into the cashbox ledger.
--
-- Only `rpc_cashbox_withdraw`'s permission check widens here — deliberately
-- nothing else. `cashboxes`/`cash_transactions` SELECT stay admin-only
-- (0011), matching 0044's explicit constraint that sales must never see the
-- cashbox ledger, deposits, or the running balance list. The RPC is
-- SECURITY DEFINER, so it reads/locks the true balance under the hood
-- regardless of the caller's own SELECT grants and still refuses to
-- overdraw the till — the client just won't be able to show sales a
-- balance figure beforehand (AdminCashMovementScreen already handles a
-- null balance by hiding that card and skipping the client-side
-- pre-check, deferring entirely to this function).
-- `rpc_cashbox_deposit` is untouched: sales can withdraw, never deposit.
-- ============================================================================

create or replace function public.rpc_cashbox_withdraw(
  p_amount numeric,
  p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_cashbox_id uuid;
  v_balance numeric(14,2);
  v_txn_id uuid;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
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
