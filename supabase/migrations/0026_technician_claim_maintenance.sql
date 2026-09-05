-- ============================================================================
-- 0026_technician_claim_maintenance.sql
--
-- A technician could already SEE waiting requests (maintenance_select allows
-- `is_technician() and status = 'waiting'`) but could not act on one: the
-- only path from 'waiting' to 'assigned' was rpc_assign_maintenance, which is
-- admin-only, and rpc_start_maintenance refuses anything not already
-- 'assigned' to the caller. So every job stalled until an admin assigned it.
--
-- This adds a self-claim so a technician can take a waiting job directly.
-- The `status = 'waiting'` predicate in the UPDATE is what makes it safe
-- under concurrency: if two technicians tap at once, exactly one row update
-- matches and the loser gets REQUEST_NOT_WAITING rather than silently
-- stealing an already-claimed job.
-- ============================================================================

create or replace function public.rpc_claim_maintenance(p_request_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_technician() then raise exception 'FORBIDDEN'; end if;

  update public.maintenance_requests
    set status = 'assigned',
        assigned_technician_id = auth.uid(),
        assigned_at = now()
    where id = p_request_id and status = 'waiting';

  if not found then raise exception 'REQUEST_NOT_WAITING'; end if;
end;
$$;
