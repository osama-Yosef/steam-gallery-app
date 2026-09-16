-- ============================================================================
-- 0029_security_hotfix_p0.sql
--
-- Phase 0.5 of the Mokoji platform conversion: the six critical findings of
-- the Phase 0 audit. Every one of them was exploitable by anyone able to
-- self-register a customer account.
--
--   P0-1  Customers could SELECT products.cost_price straight off the table
--         (products_select allowed `is_active` rows to every role; the
--         products_public view was a convention, not a boundary).
--   P0-2  Customers could SELECT order_items.unit_cost_snapshot and
--         sale_items.unit_cost_snapshot (the customer invoice screen actually
--         did), and through daily_sales_summary the COGS of their own orders.
--   P0-3  rpc_create_order trusted a per-line `discount` from the payload, so
--         a customer could price any order down to zero or below.
--   P0-4  `grant execute on all functions ... to authenticated` (0011) plus
--         Postgres' default EXECUTE-to-PUBLIC exposed every SECURITY DEFINER
--         helper over PostgREST, e.g. notify_user / notify_all_admins let any
--         caller push arbitrary notifications to any user or every admin.
--   P0-5  users.is_active was never enforced: roles came from the JWT alone,
--         so a deactivated admin/technician kept full power.
--   P0-6  users.phone was self-updatable (squatting another person's number,
--         impersonation on tickets, blocking that number's real sign-up), and
--         handle_new_auth_user copied an unverified phone out of
--         user-controlled raw_user_meta_data.
--
-- Non-destructive: no table, row, ledger, trigger or RLS enablement is
-- dropped. Only grants, policies, views and function bodies change.
--
-- RULE FROM HERE ON — every future migration that creates or re-creates a
-- function in `public` must register client-callable ones in
-- private.rpc_allowlist and finish with `select private.apply_function_grants();`.
-- New functions are otherwise callable by anon through Postgres' default
-- EXECUTE-to-PUBLIC. tool/sql/verify_security.sql flags any regression.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Function EXECUTE lockdown (P0-4)
-- ----------------------------------------------------------------------------
-- `private` is not in PostgREST's exposed schemas, so nothing here is
-- reachable over the API.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.rpc_allowlist (
  function_name text primary key,
  note text
);

insert into private.rpc_allowlist (function_name, note) values
  -- Used inside RLS / storage policies, evaluated as the querying user.
  ('auth_role', 'RLS helper'),
  ('is_admin', 'RLS helper'),
  ('is_technician', 'RLS helper'),
  ('is_customer', 'RLS helper'),
  -- Client-callable RPCs. Each one performs its own authorization check.
  ('rpc_admin_set_role', 'admin'),
  ('rpc_admin_set_active', 'admin'),
  ('rpc_admin_walk_in_sale', 'admin'),
  ('rpc_assign_maintenance', 'admin'),
  ('rpc_cancel_maintenance', 'admin/customer'),
  ('rpc_cancel_order', 'admin'),
  ('rpc_cashbox_deposit', 'admin'),
  ('rpc_cashbox_withdraw', 'admin'),
  ('rpc_claim_maintenance', 'technician'),
  ('rpc_complete_inventory_count', 'admin'),
  ('rpc_complete_maintenance', 'admin/technician'),
  ('rpc_confirm_order', 'admin'),
  ('rpc_create_maintenance_request', 'admin/customer'),
  ('rpc_create_order', 'admin/customer'),
  ('rpc_issue_stock_to_technician', 'admin'),
  ('rpc_my_maintenance_position', 'any signed-in owner'),
  ('rpc_receive_purchase', 'admin'),
  ('rpc_record_customer_payment', 'admin'),
  ('rpc_record_expense', 'admin'),
  ('rpc_save_inventory_count_item', 'admin'),
  ('rpc_start_inventory_count', 'admin'),
  ('rpc_start_maintenance', 'admin/technician'),
  ('rpc_technician_sale', 'admin/technician'),
  ('rpc_technician_supply', 'admin/technician'),
  ('rpc_update_order_status', 'admin')
on conflict (function_name) do nothing;

-- Idempotent: strips EXECUTE from public/anon/authenticated on every function
-- in `public`, then re-grants authenticated exactly the allowlist. Trigger
-- functions need no grant — Postgres does not check EXECUTE when a trigger
-- fires — and SECURITY DEFINER callers run as the owner anyway.
create or replace function private.apply_function_grants() returns void
language plpgsql security definer set search_path = pg_catalog, public as $$
declare
  r record;
begin
  for r in
    select p.oid::regprocedure as sig, p.proname
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      -- Leave extension-owned functions (pg_trgm etc.) alone.
      and not exists (
        select 1 from pg_depend d
        where d.classid = 'pg_proc'::regclass and d.objid = p.oid and d.deptype = 'e'
      )
  loop
    execute format('revoke execute on function %s from public, anon, authenticated', r.sig);
    execute format('grant execute on function %s to service_role', r.sig);
    if exists (select 1 from private.rpc_allowlist a where a.function_name = r.proname) then
      execute format('grant execute on function %s to authenticated', r.sig);
    end if;
  end loop;
end;
$$;

revoke all on function private.apply_function_grants() from public, anon, authenticated;

-- Supabase's own default privileges hand EXECUTE on new public functions to
-- anon/authenticated; stop that for functions created by this role. (The
-- global PUBLIC default cannot be revoked per-schema, which is why
-- apply_function_grants() must still run after every function change.)
alter default privileges in schema public revoke execute on functions from anon, authenticated;

-- ----------------------------------------------------------------------------
-- 2. Enforce is_active (P0-5)
-- ----------------------------------------------------------------------------
-- SECURITY DEFINER is required: users_select itself calls is_admin(), so an
-- invoker-rights lookup of public.users here would recurse through RLS.
create or replace function public.auth_role() returns text
language sql stable security definer set search_path = public as $$
  select case
    when auth.uid() is null then 'anon'
    when exists (select 1 from public.users u where u.id = auth.uid() and u.is_active)
      then coalesce(auth.jwt() -> 'app_metadata' ->> 'role', 'anon')
    else 'anon'
  end;
$$;

-- The maintenance RPCs let "the assigned technician" act without checking the
-- caller still is one; route them through is_technician() so deactivation
-- takes effect there too.
create or replace function public.rpc_start_maintenance(p_request_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.maintenance_requests
    set status = 'in_progress', started_at = now()
    where id = p_request_id and status = 'assigned'
      and (public.is_admin() or (public.is_technician() and assigned_technician_id = auth.uid()));
  if not found then raise exception 'FORBIDDEN_OR_NOT_ASSIGNED'; end if;
end;
$$;

create or replace function public.rpc_complete_maintenance(p_request_id uuid, p_notes text)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.maintenance_requests
    set status = 'completed', completed_at = now(), notes = coalesce(p_notes, notes)
    where id = p_request_id and status = 'in_progress'
      and (public.is_admin() or (public.is_technician() and assigned_technician_id = auth.uid()));
  if not found then raise exception 'FORBIDDEN_OR_NOT_IN_PROGRESS'; end if;
end;
$$;

-- Deactivation also bans the auth user (no new sign-in, no token refresh) and
-- revokes its sessions, so a stale app can't keep refreshing. Reactivation
-- lifts the ban. An admin can't deactivate or re-role themself, which would
-- risk locking the last admin out.
create or replace function public.rpc_admin_set_active(p_user_id uuid, p_is_active boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_user_id = auth.uid() then raise exception 'CANNOT_CHANGE_OWN_ACCOUNT'; end if;
  if p_is_active is null then raise exception 'INVALID_INPUT'; end if;

  update public.users set is_active = p_is_active where id = p_user_id;
  if not found then raise exception 'USER_NOT_FOUND'; end if;

  -- A far-future timestamp rather than 'infinity': GoTrue scans banned_until
  -- into a Go time value, which cannot represent infinity.
  update auth.users
    set banned_until = case when p_is_active then null else now() + interval '100 years' end
    where id = p_user_id;

  if not p_is_active then
    begin
      delete from auth.sessions where user_id = p_user_id;
    exception when insufficient_privilege then
      -- The ban alone already blocks refresh; the current access token then
      -- dies at expiry, and auth_role() refuses it in the database meanwhile.
      null;
    end;
  end if;
end;
$$;

create or replace function public.rpc_admin_set_role(p_user_id uuid, p_new_role user_role)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_user_id = auth.uid() then raise exception 'CANNOT_CHANGE_OWN_ACCOUNT'; end if;
  if p_new_role is null then raise exception 'INVALID_INPUT'; end if;

  update public.users set role = p_new_role where id = p_user_id;
  if not found then raise exception 'USER_NOT_FOUND'; end if;

  update auth.users
    set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', p_new_role::text)
    where id = p_user_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 3. Phone can no longer be self-edited or self-asserted (P0-6)
-- ----------------------------------------------------------------------------
-- A table-level REVOKE also removes column-level grants; the explicit column
-- revoke just states the intent.
revoke update (phone) on public.users from authenticated;
revoke update on public.users from authenticated;
grant update (full_name, avatar_url) on public.users to authenticated;

-- Until now anyone could write any number into their own users.phone, so a
-- profile may be squatting a number whose real holder has no account yet.
-- users.phone is UNIQUE, so that real holder's sign-up would then fail
-- outright. auth.users.phone is unique too and set by Supabase Auth, so a
-- profile whose own auth account holds a DIFFERENT number has no claim to
-- this one: clear it. Numbers are compared as digits because older rows mix
-- "+20…" and "20…" formats. The users audit trigger records the change.
create or replace function private.release_phone(p_phone text, p_owner uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_digits text := regexp_replace(coalesce(p_phone, ''), '\D', '', 'g');
begin
  if v_digits = '' then return; end if;
  update public.users u
    set phone = null
    where u.id <> p_owner
      and regexp_replace(coalesce(u.phone, ''), '\D', '', 'g') = v_digits
      and not exists (
        select 1 from auth.users a
        where a.id = u.id and regexp_replace(coalesce(a.phone, ''), '\D', '', 'g') = v_digits
      );
end;
$$;
revoke all on function private.release_phone(text, uuid) from public, anon, authenticated;

-- Same as 0017, except the phone comes only from auth.users.phone (set by
-- Supabase Auth itself), never from user-controlled raw_user_meta_data.
create or replace function public.handle_new_auth_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_role user_role := coalesce((new.raw_app_meta_data ->> 'role')::user_role, 'customer');
  v_full_name text := left(coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    new.phone,
    new.email,
    'مستخدم جديد'
  ), 100);
  v_employee_code text;
begin
  perform private.release_phone(new.phone, new.id);

  insert into public.users (id, role, full_name, phone, email)
  values (new.id, v_role, v_full_name, nullif(new.phone, ''), new.email);

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

  update auth.users
    set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', v_role::text)
    where id = new.id;

  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Cost price never reaches a customer (P0-1, P0-2)
-- ----------------------------------------------------------------------------
-- products: admin (catalog management) and technicians (their bag screens
-- embed products incl. cost_price — bag value at cost is already theirs to
-- see via technician_account_summary). Customers read products_public, a
-- definer view that never selects cost_price.
drop policy if exists products_select on public.products;
create policy products_select on public.products for select to authenticated
  using (public.is_admin() or public.is_technician());

-- order_items: admin only on the raw table. Customers read
-- order_items_display, now a definer view with its own row filter — it has
-- to be definer, because under invoker rights the admin-only policy above
-- would leave customers with nothing. security_barrier stops a caller's
-- WHERE clause from observing filtered-out rows.
drop policy if exists order_items_select on public.order_items;
create policy order_items_select on public.order_items for select to authenticated
  using (public.is_admin());

alter view public.order_items_display set (security_invoker = false);
create or replace view public.order_items_display
  with (security_barrier = true) as
select oi.id, oi.order_id, oi.product_id, oi.product_name_snapshot, oi.quantity,
       oi.unit_price_snapshot, oi.discount, oi.line_total
from public.order_items oi
where public.is_admin()
   or exists (
     select 1 from public.orders o
     where o.id = oi.order_id and o.customer_id = auth.uid()
   );
grant select on public.order_items_display to authenticated;

-- sale_items: admin + the selling technician on the raw table; everyone who
-- may see the sale (incl. the customer of a maintenance invoice) goes through
-- sale_items_display, which mirrors 0027's sales_select row rules minus cost.
drop policy if exists sale_items_select on public.sale_items;
create policy sale_items_select on public.sale_items for select to authenticated
  using (
    public.is_admin()
    or sale_id in (select s.id from public.sales s where s.technician_id = auth.uid())
  );

create or replace view public.sale_items_display
  with (security_barrier = true) as
select si.id, si.sale_id, si.product_id, si.product_name_snapshot, si.quantity,
       si.unit_price_snapshot, si.discount, si.line_total
from public.sale_items si
where public.is_admin()
   or exists (
     select 1 from public.sales s
     where s.id = si.sale_id
       and (
         s.technician_id = auth.uid()
         or s.customer_id = auth.uid()
         or s.maintenance_request_id in (
           select mr.id from public.maintenance_requests mr where mr.customer_id = auth.uid()
         )
       )
   );
revoke all on public.sale_items_display from public, anon;
grant select on public.sale_items_display to authenticated;

-- ----------------------------------------------------------------------------
-- 5. rpc_create_order: server-side pricing only (P0-3)
-- ----------------------------------------------------------------------------
-- Same signature as before (Flutter unchanged). Changes:
--   * any client-supplied `discount` is ignored — line discounts are 0;
--   * items are validated (shape, 1..999 quantity, active, not a service line);
--   * idempotency is scoped to the customer and survives a concurrent retry
--     (unique_violation resolves to the winner's order instead of an error);
--   * free-text / coordinate inputs are bounded.
create or replace function public.rpc_create_order(
  p_customer_id uuid, p_items jsonb, p_delivery_address text,
  p_latitude numeric, p_longitude numeric, p_notes text, p_client_request_id uuid
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_order_id uuid;
  v_existing_id uuid;
  v_existing_customer uuid;
  v_item jsonb;
  v_product_id uuid;
  v_qty int;
  v_product record;
  v_subtotal numeric(12,2) := 0;
begin
  if not (public.is_admin() or (public.is_customer() and p_customer_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;
  if not exists (select 1 from public.customers where id = p_customer_id) then
    raise exception 'CUSTOMER_NOT_FOUND';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_ORDER';
  end if;
  if jsonb_array_length(p_items) > 100 then raise exception 'TOO_MANY_ITEMS'; end if;
  if length(p_delivery_address) > 500 or length(p_notes) > 1000 then
    raise exception 'INPUT_TOO_LONG';
  end if;
  if (p_latitude is not null and (p_latitude < -90 or p_latitude > 90))
     or (p_longitude is not null and (p_longitude < -180 or p_longitude > 180)) then
    raise exception 'INVALID_LOCATION';
  end if;

  if p_client_request_id is not null then
    select id, customer_id into v_existing_id, v_existing_customer
      from public.orders where client_request_id = p_client_request_id;
    if found then
      if v_existing_customer <> p_customer_id then raise exception 'IDEMPOTENCY_KEY_CONFLICT'; end if;
      return v_existing_id;
    end if;
  end if;

  begin
    insert into public.orders (customer_id, status, delivery_address, delivery_latitude, delivery_longitude, notes, client_request_id)
    values (p_customer_id, 'pending', nullif(btrim(p_delivery_address), ''), p_latitude, p_longitude,
            nullif(btrim(p_notes), ''), p_client_request_id)
    returning id into v_order_id;
  exception when unique_violation then
    -- A concurrent retry with the same key committed first.
    select id, customer_id into v_existing_id, v_existing_customer
      from public.orders where client_request_id = p_client_request_id;
    if v_existing_customer is distinct from p_customer_id then
      raise exception 'IDEMPOTENCY_KEY_CONFLICT';
    end if;
    return v_existing_id;
  end;

  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) <> 'object' then raise exception 'INVALID_ITEM'; end if;
    begin
      v_product_id := (v_item ->> 'product_id')::uuid;
      v_qty := (v_item ->> 'quantity')::int;
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'INVALID_ITEM';
    end;
    if v_product_id is null then raise exception 'INVALID_ITEM'; end if;
    if v_qty is null or v_qty <= 0 or v_qty > 999 then raise exception 'INVALID_QUANTITY'; end if;

    select id, name, selling_price, cost_price, is_service into v_product
      from public.products where id = v_product_id and is_active;
    if not found or v_product.is_service then
      raise exception 'PRODUCT_NOT_FOUND: %', v_product_id;
    end if;

    v_subtotal := v_subtotal + v_qty * v_product.selling_price;

    insert into public.order_items (order_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount)
    values (v_order_id, v_product.id, v_product.name, v_qty, v_product.selling_price, v_product.cost_price, 0);
  end loop;

  update public.orders set subtotal = v_subtotal where id = v_order_id;
  return v_order_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 6. Apply the grants last, so every function (re)defined above is covered.
-- ----------------------------------------------------------------------------
select private.apply_function_grants();
