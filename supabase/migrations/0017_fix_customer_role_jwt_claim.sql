-- ============================================================================
-- 0017_fix_customer_role_jwt_claim.sql
--
-- Critical bug found via live testing: rpc_create_order (and every other
-- RPC/RLS policy gating on is_customer()/is_admin()/is_technician()) reads
-- the role from the JWT's app_metadata, NOT from public.users.role. But
-- handle_new_auth_user() only ever wrote the resolved role into
-- public.users — it never wrote it back into auth.users.raw_app_meta_data.
-- Only rpc_admin_set_role() did that, and only for explicit admin-driven
-- role changes (technician/admin creation). Every self-registered customer
-- therefore had NO role in their JWT at all, auth_role() fell back to
-- 'anon', and is_customer() was false for every customer that ever
-- self-signed-up — silently blocking every order and maintenance request.
--
-- Fix: handle_new_auth_user() now also stamps app_metadata.role on the
-- auth.users row it just created, exactly like rpc_admin_set_role does for
-- admin-driven signups. This also affects already-existing accounts once
-- they're touched again, but existing broken accounts need a one-time
-- backfill (see bottom).
-- ============================================================================

create or replace function public.handle_new_auth_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_role user_role := coalesce((new.raw_app_meta_data ->> 'role')::user_role, 'customer');
  v_full_name text := coalesce(
    new.raw_user_meta_data ->> 'full_name',
    new.phone,
    new.email,
    'مستخدم جديد'
  );
  v_employee_code text;
begin
  insert into public.users (id, role, full_name, phone, email)
  values (new.id, v_role, v_full_name, coalesce(new.phone, new.raw_user_meta_data ->> 'phone'), new.email);

  if v_role = 'customer' then
    insert into public.customers (id) values (new.id);
    insert into public.customer_accounts (id) values (new.id);
  elsif v_role = 'technician' then
    v_employee_code := coalesce(new.raw_user_meta_data ->> 'employee_code', 'T-' || substr(new.id::text, 1, 8));
    insert into public.technicians (id, employee_code, created_by)
      values (new.id, v_employee_code, (new.raw_user_meta_data ->> 'created_by')::uuid);
    insert into public.technician_bags (technician_id) values (new.id);
    insert into public.technician_accounts (id) values (new.id);
  end if;

  -- Every RLS policy and RPC checks the JWT's app_metadata.role, not
  -- public.users.role — keep them in lockstep from the moment of creation.
  update auth.users
    set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', v_role::text)
    where id = new.id;

  return new;
end;
$$;

-- One-time backfill for accounts already created before this fix (e.g. the
-- test customers created during Module 1-3 development) whose JWT never
-- got a role stamped. Safe to run any time: only touches rows missing it.
update auth.users u
  set raw_app_meta_data = coalesce(u.raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', p.role::text)
  from public.users p
  where p.id = u.id
    and (u.raw_app_meta_data -> 'role') is null;
