-- 0085: a technician can't remit more than he owes.
--
-- A technician sold for 600, remitted the 600, then pressed it again twice
-- and remitted another 100: «المطلوب توريده» went to -1300 and the till
-- took 1300 that never came in. rpc_technician_supply now refuses any
-- amount above what is due (sale_credit + adjustment - supply_debit, the
-- same sum as technician_account_summary), so nothing is ever owed back.
--
-- The error is INVALID_AMOUNT, which the app already shows as
-- «المبلغ المدخل غير صحيح» — no app update needed.
--
-- Same function as 0055 with 0083's sales access; only the due check and
-- the row lock (two remittances at once can't both pass it) are new.

create or replace function public.rpc_technician_supply(p_technician_id uuid, p_amount numeric, p_notes text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_supply_id uuid;
  v_due numeric;
begin
  if not ((public.is_admin() or public.is_sales()) or (public.is_technician() and p_technician_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then
    raise exception 'INVALID_AMOUNT';
  end if;
  if length(p_notes) > 500 then raise exception 'INPUT_TOO_LONG'; end if;
  perform 1 from public.technicians where id = p_technician_id for update;
  if not found then
    raise exception 'TECHNICIAN_NOT_AVAILABLE';
  end if;
  if not exists (select 1 from public.cashboxes where is_active) then raise exception 'NO_CASHBOX'; end if;

  select coalesce(sum(case when transaction_type = 'supply_debit' then -amount else amount end), 0)
    into v_due
  from public.technician_account_transactions
  where technician_id = p_technician_id;
  if p_amount > v_due then
    raise exception 'INVALID_AMOUNT: المطلوب توريده %', greatest(v_due, 0);
  end if;

  insert into public.technician_supplies (technician_id, amount, notes, recorded_by, status, reviewed_by, reviewed_at)
  values (p_technician_id, p_amount, nullif(btrim(p_notes), ''), auth.uid(), 'confirmed', auth.uid(), now())
  returning id into v_supply_id;
  perform public.post_technician_supply(v_supply_id);

  return v_supply_id;
end;
$$;
