-- ============================================================================
-- 0019_fix_bogus_customer_rows_for_non_customers.sql
--
-- Bug found via live testing of Module 8 (Customer Accounts): the admin
-- customer list showed admin/technician accounts (e.g. "مدير الاختبار",
-- "محمد الصنايعي") as if they were customers.
--
-- Root cause: handle_new_auth_user() (AFTER INSERT on auth.users) reads
-- raw_app_meta_data at INSERT time, but Supabase's Admin API
-- (auth.admin.createUser, used by both manual admin bootstrap and the
-- create-user Edge Function) writes app_metadata in a follow-up UPDATE, not
-- the initial INSERT — a race already diagnosed and half-fixed in
-- 0014_fix_role_sync_trigger.sql. 0014 makes sync_user_role_on_metadata_update()
-- correctly set public.users.role and provision technicians/technician_bags
-- once the real role arrives, but it never removes the customers/
-- customer_accounts rows that handle_new_auth_user() had already wrongly
-- created for that user while role still defaulted to 'customer'.
-- ============================================================================

-- 1) One-time cleanup: any user whose current role is admin/technician
--    should never have a customers row. Only touch rows with zero real
--    activity, so a genuine customer who was later promoted to admin never
--    loses their purchase/maintenance history.
delete from public.customers c
using public.users u
where u.id = c.id
  and u.role in ('admin', 'technician')
  and not exists (select 1 from public.customer_account_transactions where customer_id = c.id)
  and not exists (select 1 from public.orders where customer_id = c.id)
  and not exists (select 1 from public.maintenance_requests where customer_id = c.id)
  and not exists (select 1 from public.sales where customer_id = c.id);

-- 2) Prevent recurrence: also clean up (with the same activity guard) when
--    the metadata-sync trigger sees a user settle into admin/technician.
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

  if v_role = 'technician' then
    if not exists (select 1 from public.technicians where id = new.id) then
      v_employee_code := coalesce(new.raw_user_meta_data ->> 'employee_code', 'T-' || substr(new.id::text, 1, 8));
      insert into public.technicians (id, employee_code, created_by)
        values (new.id, v_employee_code, (new.raw_user_meta_data ->> 'created_by')::uuid)
        on conflict (id) do nothing;
      insert into public.technician_bags (technician_id) values (new.id) on conflict (technician_id) do nothing;
      insert into public.technician_accounts (id) values (new.id) on conflict (id) do nothing;
    end if;
    delete from public.customers c
    where c.id = new.id
      and not exists (select 1 from public.customer_account_transactions where customer_id = c.id)
      and not exists (select 1 from public.orders where customer_id = c.id)
      and not exists (select 1 from public.maintenance_requests where customer_id = c.id)
      and not exists (select 1 from public.sales where customer_id = c.id);
  elsif v_role = 'customer' then
    if not exists (select 1 from public.customers where id = new.id) then
      insert into public.customers (id) values (new.id) on conflict (id) do nothing;
      insert into public.customer_accounts (id) values (new.id) on conflict (id) do nothing;
    end if;
  elsif v_role = 'admin' then
    delete from public.customers c
    where c.id = new.id
      and not exists (select 1 from public.customer_account_transactions where customer_id = c.id)
      and not exists (select 1 from public.orders where customer_id = c.id)
      and not exists (select 1 from public.maintenance_requests where customer_id = c.id)
      and not exists (select 1 from public.sales where customer_id = c.id);
  end if;

  return new;
end;
$$;
