-- ============================================================================
-- 0088_technician_sale_edit_limits.sql
--
-- Two limits on editing/deleting a technician's invoice (0087):
--
-- 1. A technician can change his own invoice for 3 days after it was made;
--    after that only admin can. EDIT_WINDOW_EXPIRED.
--
-- 2. «المطلوب توريده» never goes below zero. Lowering an invoice the
--    technician already remitted the money for would leave the shop owing
--    him; that edit (or delete) is refused with TECHNICIAN_DUE_NEGATIVE —
--    for admin too. Same due formula and the same row lock as
--    rpc_technician_supply (0085), so a remittance at the same moment
--    can't slip past it.
--
-- Both checks live in private.fn_tech_sale_settle, which every edit and
-- delete calls; a refusal rolls the whole edit back (stock included).
-- Only that function is replaced; nothing else changes.
-- ============================================================================

create or replace function private.fn_tech_sale_settle(
  p_sale_id uuid, p_old_total numeric, p_old_paid numeric, p_note text
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_sale record;
  v_new_paid numeric(12,2);
  v_delta numeric(12,2);
  v_due numeric(14,2);
begin
  select * into v_sale from public.sales where id = p_sale_id for update;

  -- 1. A technician's own window; admin is not limited.
  if not public.is_admin() and v_sale.created_at < now() - interval '3 days' then
    raise exception 'EDIT_WINDOW_EXPIRED';
  end if;

  if v_sale.payment_method = 'deferred' then
    v_delta := v_sale.total - p_old_total;
    if v_delta <> 0 and v_sale.customer_id is not null then
      insert into public.customer_account_transactions (customer_id, transaction_type, amount, sale_id, notes, created_by)
      values (v_sale.customer_id, case when v_delta > 0 then 'order_charge' else 'return_credit' end::cust_txn_type,
              v_delta, p_sale_id, p_note, auth.uid());
    end if;
    return;
  end if;

  v_new_paid := case when p_old_paid >= p_old_total then v_sale.total
                     else least(p_old_paid, v_sale.total) end;
  v_delta := v_new_paid - p_old_paid;
  if v_delta > 0 then
    insert into public.technician_account_transactions (technician_id, transaction_type, amount, sale_id, notes, created_by)
    values (v_sale.technician_id, 'sale_credit', v_delta, p_sale_id, p_note, auth.uid());
  elsif v_delta < 0 then
    -- 2. What he still owes must cover the reduction.
    perform 1 from public.technicians where id = v_sale.technician_id for update;
    select coalesce(sum(case when transaction_type = 'supply_debit' then -amount else amount end), 0)
      into v_due
    from public.technician_account_transactions
    where technician_id = v_sale.technician_id;
    if v_due + v_delta < 0 then
      raise exception 'TECHNICIAN_DUE_NEGATIVE: %', greatest(v_due, 0);
    end if;

    insert into public.technician_account_transactions (technician_id, transaction_type, amount, sale_id, notes, created_by)
    values (v_sale.technician_id, 'adjustment', v_delta, p_sale_id, p_note, auth.uid());
  end if;
  update public.sales set paid_amount = v_new_paid where id = p_sale_id;
end;
$$;
revoke all on function private.fn_tech_sale_settle(uuid, numeric, numeric, text) from public, anon, authenticated;

notify pgrst, 'reload schema';
