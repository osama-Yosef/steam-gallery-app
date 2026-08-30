-- ============================================================================
-- 0014_fix_role_sync_trigger.sql
--
-- Bug found via live testing: Supabase's Admin API (auth.admin.createUser,
-- used by both the manual admin bootstrap and the create-user Edge Function)
-- does NOT write app_metadata in the same statement as the initial INSERT
-- into auth.users — it inserts the row first, then attaches app_metadata in
-- a follow-up UPDATE. Our AFTER INSERT trigger (handle_new_auth_user) reads
-- raw_app_meta_data at INSERT time, so it always saw an empty role and
-- silently defaulted every admin/technician created this way to 'customer'.
-- Self sign-up (customers) was never affected — they have no app_metadata
-- at all, so 'customer' was always the correct fallback for them.
--
-- Fix: also sync on UPDATE of auth.users, but only when raw_app_meta_data
-- actually changed (not on every login's last_sign_in_at bump), and only
-- provision the technician/customer extension rows if they don't exist yet.
-- ============================================================================

create or replace function public.sync_user_role_on_metadata_update() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_role user_role;
  v_employee_code text;
begin
  if new.raw_app_meta_data is not distinct from old.raw_app_meta_data then
    return new; -- routine auth.users update (e.g. last_sign_in_at) — nothing to do
  end if;

  v_role := coalesce((new.raw_app_meta_data ->> 'role')::user_role, 'customer');

  update public.users set role = v_role where id = new.id and role is distinct from v_role;

  if v_role = 'technician' and not exists (select 1 from public.technicians where id = new.id) then
    v_employee_code := coalesce(new.raw_user_meta_data ->> 'employee_code', 'T-' || substr(new.id::text, 1, 8));
    insert into public.technicians (id, employee_code, created_by)
      values (new.id, v_employee_code, (new.raw_user_meta_data ->> 'created_by')::uuid)
      on conflict (id) do nothing;
    insert into public.technician_bags (technician_id) values (new.id) on conflict (technician_id) do nothing;
    insert into public.technician_accounts (id) values (new.id) on conflict (id) do nothing;
  elsif v_role = 'customer' and not exists (select 1 from public.customers where id = new.id) then
    insert into public.customers (id) values (new.id) on conflict (id) do nothing;
    insert into public.customer_accounts (id) values (new.id) on conflict (id) do nothing;
  end if;

  return new;
end;
$$;

create trigger trg_on_auth_user_metadata_updated
  after update on auth.users
  for each row execute function public.sync_user_role_on_metadata_update();
