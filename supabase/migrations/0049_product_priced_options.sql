-- ============================================================================
-- 0049_product_priced_options.sql
--
-- Replaces the old free-text "المواصفات" (specs) feature with priced,
-- selectable options: each product can have zero or more named options
-- (e.g. "ضمان سنتين +200ج"), the customer ticks any combination on the
-- product page, and every ticked option's extra_price adds to what they
-- pay — same server-authoritative pricing discipline as the rest of the
-- cart/checkout system (0035/0036/0046): nothing about price is ever
-- trusted from the client, only option IDs are, and every RPC re-prices
-- from `product_options` itself.
--
-- `products.specs` (jsonb) is left in place untouched — no data is
-- destroyed — but the app stops reading/writing it from this point on.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. product_options — admin-managed, no cost (pure price add-on).
-- ----------------------------------------------------------------------------
-- Guarded (if not exists / drop-then-create) throughout this section: live
-- drift discovered 2026-09-19 showed this table, its index/policies, and
-- cart_items' option_ids column + PK had already been created out-of-band
-- (ad hoc SQL, never through `db push`) while other parts of this same
-- file — critically the function bodies further down — had not, leaving
-- e.g. rpc_create_order still charging raw selling_price with no offer/
-- option awareness live. Guarding every statement here is what lets this
-- file replay safely and bring the function bodies (and the one genuinely
-- missing piece, order_items.selected_options_snapshot) up to date
-- regardless of exactly how much of it limped through before. Same
-- rationale as 0062's `create table if not exists` for this exact table.
create table if not exists public.product_options (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  name text not null check (btrim(name) <> ''),
  extra_price numeric(10,2) not null default 0 check (extra_price >= 0),
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists idx_product_options_product on public.product_options (product_id, sort_order);

alter table public.product_options enable row level security;

-- No sensitive data (no cost) — same open-read policy as product_images.
grant select on public.product_options to authenticated;
grant insert, update, delete on public.product_options to authenticated;
drop policy if exists product_options_select on public.product_options;
create policy product_options_select on public.product_options for select to authenticated using (true);
drop policy if exists product_options_write on public.product_options;
create policy product_options_write on public.product_options for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- 2. cart_items — a line is now keyed by (product, exact option combo), so
--    picking a different combination of the same product is a separate
--    line, priced separately. option_ids is always stored canonicalised
--    (sorted, deduplicated) by the RPCs below so the same combination
--    always maps to the same line regardless of tick order.
-- ----------------------------------------------------------------------------
alter table public.cart_items add column if not exists option_ids uuid[] not null default '{}';

do $$
declare
  v_pk_cols text[];
begin
  select coalesce(array_agg(kcu.column_name order by kcu.column_name), '{}')
    into v_pk_cols
    from information_schema.table_constraints tc
    join information_schema.key_column_usage kcu
      on kcu.constraint_name = tc.constraint_name and kcu.table_schema = tc.table_schema
    where tc.table_schema = 'public' and tc.table_name = 'cart_items' and tc.constraint_type = 'PRIMARY KEY';

  if v_pk_cols <> array['customer_id', 'option_ids', 'product_id'] then
    alter table public.cart_items drop constraint cart_items_pkey;
    alter table public.cart_items add primary key (customer_id, product_id, option_ids);
  end if;
end $$;

-- ----------------------------------------------------------------------------
-- 3. Cart RPCs — same bodies as 0035, extended with option_ids.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_cart_set_item(
  p_product_id uuid, p_quantity int, p_option_ids uuid[] default '{}'
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_price numeric(12,2);
  v_options_total numeric(12,2);
  v_option_ids uuid[];
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  if p_product_id is null or p_quantity is null
     or p_quantity < 0 or p_quantity > private.cart_max_quantity() then
    raise exception 'INVALID_QUANTITY';
  end if;

  select coalesce(array_agg(distinct x order by x), '{}') into v_option_ids
    from unnest(coalesce(p_option_ids, '{}'::uuid[])) x;

  if p_quantity = 0 then
    delete from public.cart_items
     where customer_id = v_uid and product_id = p_product_id and option_ids = v_option_ids;
    return public.rpc_get_my_cart();
  end if;

  select p.selling_price into v_price
    from public.products p
   where p.id = p_product_id and p.is_active and not p.is_service;
  if not found then raise exception 'PRODUCT_NOT_FOUND'; end if;

  if array_length(v_option_ids, 1) > 0 then
    if (select count(*) from public.product_options
         where id = any(v_option_ids) and product_id = p_product_id) <> array_length(v_option_ids, 1) then
      raise exception 'OPTION_NOT_FOUND';
    end if;
    select coalesce(sum(po.extra_price), 0) into v_options_total
      from public.product_options po where po.id = any(v_option_ids);
  else
    v_options_total := 0;
  end if;
  v_price := v_price + v_options_total;

  -- Serialise this customer's cart writes so the line cap can't be raced.
  perform 1 from public.customers where id = v_uid for update;

  if not exists (
      select 1 from public.cart_items
       where customer_id = v_uid and product_id = p_product_id and option_ids = v_option_ids)
     and (select count(*) from public.cart_items where customer_id = v_uid) >= private.cart_max_lines() then
    raise exception 'CART_FULL';
  end if;

  insert into public.cart_items as ci (customer_id, product_id, option_ids, quantity, price_seen)
  values (v_uid, p_product_id, v_option_ids, p_quantity, v_price)
  on conflict (customer_id, product_id, option_ids) do update
    set quantity = excluded.quantity, price_seen = excluded.price_seen, updated_at = now();

  return public.rpc_get_my_cart();
end;
$$;

create or replace function public.rpc_cart_add_item(
  p_product_id uuid, p_quantity int, p_option_ids uuid[] default '{}'
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_current int;
  v_option_ids uuid[];
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > private.cart_max_quantity() then
    raise exception 'INVALID_QUANTITY';
  end if;

  select coalesce(array_agg(distinct x order by x), '{}') into v_option_ids
    from unnest(coalesce(p_option_ids, '{}'::uuid[])) x;

  select quantity into v_current from public.cart_items
   where customer_id = auth.uid() and product_id = p_product_id and option_ids = v_option_ids;
  return public.rpc_cart_set_item(
    p_product_id, least(coalesce(v_current, 0) + p_quantity, private.cart_max_quantity()), v_option_ids);
end;
$$;

create or replace function public.rpc_get_my_cart()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_items jsonb;
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;

  select coalesce(jsonb_agg(line order by line ->> 'added_at'), '[]'::jsonb) into v_items
  from (
    select jsonb_build_object(
      'product_id', p.id,
      'name', p.name,
      'sku', p.sku,
      'image_url', (
        select pi.image_url from public.product_images pi
         where pi.product_id = p.id
         order by pi.is_primary desc, pi.sort_order asc limit 1),
      'quantity', ci.quantity,
      'option_ids', to_jsonb(ci.option_ids),
      'options', coalesce((
        select jsonb_agg(jsonb_build_object('id', po.id, 'name', po.name, 'extra_price', po.extra_price) order by po.sort_order)
        from public.product_options po where po.id = any(ci.option_ids)
      ), '[]'::jsonb),
      'unit_price', p.selling_price + coalesce((
        select sum(po.extra_price) from public.product_options po where po.id = any(ci.option_ids)), 0),
      'price_seen', ci.price_seen,
      'price_changed', (p.selling_price + coalesce((
        select sum(po.extra_price) from public.product_options po where po.id = any(ci.option_ids)), 0)) <> ci.price_seen,
      'line_total', case when p.is_active and not p.is_service
                         then (p.selling_price + coalesce((
                           select sum(po.extra_price) from public.product_options po where po.id = any(ci.option_ids)), 0)) * ci.quantity
                         else 0 end,
      'is_active', p.is_active and not p.is_service,
      'is_available', p.is_active and not p.is_service and coalesce((
        select sum(ws.quantity) from public.warehouse_stock ws where ws.product_id = p.id), 0) >= ci.quantity,
      'added_at', ci.added_at
    ) as line
    from public.cart_items ci
    join public.products p on p.id = ci.product_id
    where ci.customer_id = auth.uid()
  ) lines;

  return jsonb_build_object(
    'items', v_items,
    'item_count', coalesce((select sum((l ->> 'quantity')::int) from jsonb_array_elements(v_items) l
                            where (l ->> 'is_active')::boolean), 0),
    'subtotal', coalesce((select sum((l ->> 'line_total')::numeric) from jsonb_array_elements(v_items) l), 0),
    'currency', 'EGP',
    'has_issues', exists (select 1 from jsonb_array_elements(v_items) l
                          where not (l ->> 'is_available')::boolean or (l ->> 'price_changed')::boolean)
  );
end;
$$;

create or replace function public.rpc_cart_acknowledge_prices()
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  update public.cart_items ci
     set price_seen = p.selling_price + coalesce((
           select sum(po.extra_price) from public.product_options po where po.id = any(ci.option_ids)), 0),
         updated_at = now()
    from public.products p
   where p.id = ci.product_id and ci.customer_id = auth.uid()
     and ci.price_seen <> (p.selling_price + coalesce((
           select sum(po.extra_price) from public.product_options po where po.id = any(ci.option_ids)), 0));
  return public.rpc_get_my_cart();
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. order_items — snapshot which options (name + price, not just an id
--    that could later change) were picked, same "snapshot everything at
--    order time" discipline as the delivery address (0036).
-- ----------------------------------------------------------------------------
alter table public.order_items
  add column if not exists selected_options_snapshot jsonb not null default '[]'::jsonb;

create or replace view public.order_items_display
  with (security_invoker = true) as
select id, order_id, product_id, product_name_snapshot, quantity,
       unit_price_snapshot, discount, line_total, selected_options_snapshot
from public.order_items;

-- ----------------------------------------------------------------------------
-- 5. rpc_create_order — each item may now carry option_ids; price and
--    snapshot them the same way the rest of this function already treats
--    everything else client-supplied: re-validate, never trust.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_create_order(
  p_customer_id uuid, p_items jsonb, p_address_id uuid, p_notes text, p_client_request_id uuid
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_order_id uuid;
  v_existing_id uuid;
  v_existing_customer uuid;
  v_address record;
  v_item jsonb;
  v_product_id uuid;
  v_qty int;
  v_product record;
  v_subtotal numeric(12,2) := 0;
  v_option_ids uuid[];
  v_options_total numeric(12,2);
  v_options_snapshot jsonb;
  v_unit_price numeric(12,2);
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
  if length(p_notes) > 1000 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_address from public.customer_addresses
    where id = p_address_id and customer_id = p_customer_id and is_active;
  if not found then raise exception 'ADDRESS_NOT_FOUND'; end if;
  -- Delivery is NOT zone-restricted (0046) — deliberately no
  -- address_is_serviceable() check here any more.

  if p_client_request_id is not null then
    select id, customer_id into v_existing_id, v_existing_customer
      from public.orders where client_request_id = p_client_request_id;
    if found then
      if v_existing_customer <> p_customer_id then raise exception 'IDEMPOTENCY_KEY_CONFLICT'; end if;
      return v_existing_id;
    end if;
  end if;

  begin
    insert into public.orders (
      customer_id, status, notes, client_request_id,
      delivery_address_id, delivery_address, delivery_latitude, delivery_longitude,
      delivery_recipient_name, delivery_phone, delivery_building, delivery_floor,
      delivery_apartment, delivery_landmark, delivery_city_id, delivery_service_area_id
    )
    values (
      p_customer_id, 'pending', nullif(btrim(p_notes), ''), p_client_request_id,
      v_address.id, v_address.address_line, v_address.latitude, v_address.longitude,
      v_address.recipient_name, v_address.phone, v_address.building, v_address.floor,
      v_address.apartment, v_address.landmark, v_address.city_id, v_address.service_area_id
    )
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

    begin
      select coalesce(array_agg((x)::uuid), '{}') into v_option_ids
        from jsonb_array_elements_text(coalesce(v_item -> 'option_ids', '[]'::jsonb)) x;
    exception when invalid_text_representation then
      raise exception 'INVALID_ITEM';
    end;

    v_options_total := 0;
    v_options_snapshot := '[]'::jsonb;
    if array_length(v_option_ids, 1) > 0 then
      if (select count(*) from public.product_options
           where id = any(v_option_ids) and product_id = v_product_id) <> array_length(v_option_ids, 1) then
        raise exception 'OPTION_NOT_FOUND';
      end if;
      select coalesce(sum(po.extra_price), 0),
             coalesce(jsonb_agg(jsonb_build_object('name', po.name, 'extra_price', po.extra_price) order by po.sort_order), '[]'::jsonb)
        into v_options_total, v_options_snapshot
        from public.product_options po where po.id = any(v_option_ids);
    end if;

    v_unit_price := v_product.selling_price + v_options_total;
    v_subtotal := v_subtotal + v_qty * v_unit_price;

    insert into public.order_items (
      order_id, product_id, product_name_snapshot, quantity,
      unit_price_snapshot, unit_cost_snapshot, discount, selected_options_snapshot
    )
    values (
      v_order_id, v_product.id, v_product.name, v_qty,
      v_unit_price, v_product.cost_price, 0, v_options_snapshot
    );
  end loop;

  update public.orders set subtotal = v_subtotal where id = v_order_id;
  return v_order_id;
end;
$$;

select private.apply_function_grants();
