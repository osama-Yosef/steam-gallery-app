-- ============================================================================
-- 0048_sales_products_visibility_and_full_cashbox.sql
--
-- Two fixes from live testing on the sales role:
--
-- 1. "بيع مباشر" showed no products at all for sales, while the exact same
--    screen worked for admin. Root cause: `products_select` (0029's rewrite)
--    only ever allowed `is_admin() or is_technician()` — migration 0044
--    widened warehouse_stock/products WRITE for sales but never widened this
--    base products READ policy, so the walk-in-sale screen's
--    `products!inner(...)` embed silently dropped every row for a sales
--    caller (RLS on the embedded table filters the whole joined row out,
--    not just the embedded columns).
--
-- 2. Sales' cashbox access was too narrow (only withdrawal, 0045, on
--    purpose at the time). The business now wants sales to have the same
--    cashbox as admin: see the balance and ledger, record expenses, deposit
--    and withdraw — so this widens every remaining cashbox/expense
--    SELECT policy and RPC the same way 0044/0045 already did for orders/
--    warehouse/withdrawal.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Products — sales can read the full catalogue (incl. inactive rows,
--    same as admin/technician), matching the warehouse/stock-movement
--    visibility it already has. Write access stays admin-only (0047).
-- ----------------------------------------------------------------------------
drop policy if exists products_select on public.products;
create policy products_select on public.products for select to authenticated
  using (public.is_admin() or public.is_technician() or public.is_sales());

-- ----------------------------------------------------------------------------
-- 2. Cashbox ledger + balance — full read access, same as admin.
-- ----------------------------------------------------------------------------
alter policy cashboxes_select on public.cashboxes
  using (public.is_admin() or public.is_sales());

alter policy cash_txn_select on public.cash_transactions
  using (public.is_admin() or public.is_sales());

-- ----------------------------------------------------------------------------
-- 3. Expenses — sales can see categories/history and record new ones.
-- ----------------------------------------------------------------------------
alter policy expense_categories_select on public.expense_categories
  using (public.is_admin() or public.is_sales());

alter policy expenses_select on public.expenses
  using (public.is_admin() or public.is_sales());

create or replace function public.rpc_record_expense(p_category_id uuid, p_amount numeric, p_expense_date date, p_notes text, p_attachment_url text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_expense_id uuid;
  v_cashbox_id uuid;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;

  select id into v_cashbox_id from public.cashboxes where is_active limit 1;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

  insert into public.expenses (category_id, amount, expense_date, notes, attachment_url, created_by)
  values (p_category_id, p_amount, coalesce(p_expense_date, current_date), p_notes, p_attachment_url, auth.uid())
  returning id into v_expense_id;

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  values (v_cashbox_id, 'expense', -p_amount, 'expense', v_expense_id, p_notes, auth.uid());

  return v_expense_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Deposit — sales can now put cash into the till too (0045 already did
--    withdrawal; the business wants both, "normal" access like admin).
-- ----------------------------------------------------------------------------
create or replace function public.rpc_cashbox_deposit(
  p_amount numeric,
  p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_cashbox_id uuid;
  v_txn_id uuid;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
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

select private.apply_function_grants();
