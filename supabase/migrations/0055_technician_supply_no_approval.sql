-- ============================================================================
-- 0055_technician_supply_no_approval.sql
--
-- Requested change: a technician's own "تسجيل توريد" (recording cash handed
-- in) should post immediately, the same as when an admin records it,
-- instead of sitting as 'pending' until an admin reviews it.
--
-- Trade-off worth knowing: the pending step (0030) existed specifically so
-- a technician's own claim of having handed in cash couldn't reduce their
-- own amount-due balance and credit the till before anyone verified the
-- cash actually arrived. Removing it means that check no longer exists.
-- rpc_admin_review_technician_supply is left in place (harmless, and still
-- needed for any already-pending rows from before this migration) but the
-- flow no longer creates pending ones.
-- ============================================================================

create or replace function public.rpc_technician_supply(p_technician_id uuid, p_amount numeric, p_notes text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_supply_id uuid;
begin
  if not (public.is_admin() or (public.is_technician() and p_technician_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then
    raise exception 'INVALID_AMOUNT';
  end if;
  if length(p_notes) > 500 then raise exception 'INPUT_TOO_LONG'; end if;
  if not exists (select 1 from public.technicians where id = p_technician_id) then
    raise exception 'TECHNICIAN_NOT_AVAILABLE';
  end if;
  if not exists (select 1 from public.cashboxes where is_active) then raise exception 'NO_CASHBOX'; end if;

  insert into public.technician_supplies (technician_id, amount, notes, recorded_by, status, reviewed_by, reviewed_at)
  values (p_technician_id, p_amount, nullif(btrim(p_notes), ''), auth.uid(), 'confirmed', auth.uid(), now())
  returning id into v_supply_id;
  perform public.post_technician_supply(v_supply_id);

  return v_supply_id;
end;
$$;

select private.apply_function_grants();
notify pgrst, 'reload schema';
