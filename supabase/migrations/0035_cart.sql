-- ============================================================================
-- 0035_cart.sql  (Phase 7 — cart)
--
-- The cart used to live only in app memory: lost on restart, invisible on a
-- second device, and it carried prices the app itself had read. It now lives
-- in the database, and it holds NO money: only product + quantity. Every read
-- (rpc_get_my_cart) prices lines from products at that moment, flags lines
-- that became unavailable or whose price moved since they were added, and
-- computes the subtotal server-side. Checkout (Phase 8) reads this table, not
-- anything the app sends.
--
-- Writes go through RPCs only (bounds, product checks, line caps).
-- No existing table, trigger or ledger is touched.
-- ============================================================================

create table public.cart_items (
  customer_id uuid not null references public.customers(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity int not null check (quantity between 1 and 20),
  -- Price when the line was added/last changed: display only, used to tell
  -- the customer "the price changed". Never used to charge.
  price_seen numeric(12,2) not null check (price_seen >= 0),
  added_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (customer_id, product_id)
);

create index idx_cart_items_updated on public.cart_items (updated_at);

alter table public.cart_items enable row level security;

-- Read own lines (admins may look, e.g. for support). No direct writes.
revoke all on public.cart_items from anon, authenticated;
grant select on public.cart_items to authenticated;
create policy cart_items_select on public.cart_items for select to authenticated
  using (customer_id = auth.uid() or public.is_admin());

-- ----------------------------------------------------------------------------
-- Limits (mirrored in the app: maxCartLineQuantity / maxCartLines)
-- ----------------------------------------------------------------------------
create or replace function private.cart_max_quantity() returns int
language sql immutable as $$ select 20 $$;
create or replace function private.cart_max_lines() returns int
language sql immutable as $$ select 30 $$;

-- ----------------------------------------------------------------------------
-- Set a line's quantity (0 removes it). Returns the cart.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_cart_set_item(p_product_id uuid, p_quantity int)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_price numeric(12,2);
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  if p_product_id is null or p_quantity is null
     or p_quantity < 0 or p_quantity > private.cart_max_quantity() then
    raise exception 'INVALID_QUANTITY';
  end if;

  if p_quantity = 0 then
    delete from public.cart_items where customer_id = v_uid and product_id = p_product_id;
    return public.rpc_get_my_cart();
  end if;

  select p.selling_price into v_price
    from public.products p
   where p.id = p_product_id and p.is_active and not p.is_service;
  if not found then raise exception 'PRODUCT_NOT_FOUND'; end if;

  -- Serialise this customer's cart writes so the line cap can't be raced.
  perform 1 from public.customers where id = v_uid for update;

  if not exists (select 1 from public.cart_items where customer_id = v_uid and product_id = p_product_id)
     and (select count(*) from public.cart_items where customer_id = v_uid) >= private.cart_max_lines() then
    raise exception 'CART_FULL';
  end if;

  insert into public.cart_items as ci (customer_id, product_id, quantity, price_seen)
  values (v_uid, p_product_id, p_quantity, v_price)
  on conflict (customer_id, product_id) do update
    set quantity = excluded.quantity, price_seen = excluded.price_seen, updated_at = now();

  return public.rpc_get_my_cart();
end;
$$;

-- Adds to whatever is already there (product page «أضف للسلة»), capped.
create or replace function public.rpc_cart_add_item(p_product_id uuid, p_quantity int)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_current int;
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > private.cart_max_quantity() then
    raise exception 'INVALID_QUANTITY';
  end if;
  select quantity into v_current from public.cart_items
   where customer_id = auth.uid() and product_id = p_product_id;
  return public.rpc_cart_set_item(
    p_product_id, least(coalesce(v_current, 0) + p_quantity, private.cart_max_quantity()));
end;
$$;

create or replace function public.rpc_cart_clear()
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  delete from public.cart_items where customer_id = auth.uid();
  return public.rpc_get_my_cart();
end;
$$;

-- ----------------------------------------------------------------------------
-- The priced cart
-- ----------------------------------------------------------------------------
-- {
--   items: [{product_id, name, sku, image_url, quantity, unit_price,
--            price_seen, price_changed, line_total, is_available, is_active}],
--   item_count, subtotal, currency, has_issues
-- }
-- A line whose product was switched off stays visible (so the customer sees
-- why it can't be bought) but is excluded from the subtotal.
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
      'unit_price', p.selling_price,
      'price_seen', ci.price_seen,
      'price_changed', p.selling_price <> ci.price_seen,
      'line_total', case when p.is_active and not p.is_service
                         then p.selling_price * ci.quantity else 0 end,
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

-- Accept the new prices: refresh price_seen so the "price changed" notice
-- goes away once the customer has seen it.
create or replace function public.rpc_cart_acknowledge_prices()
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  update public.cart_items ci
     set price_seen = p.selling_price, updated_at = now()
    from public.products p
   where p.id = ci.product_id and ci.customer_id = auth.uid()
     and ci.price_seen <> p.selling_price;
  return public.rpc_get_my_cart();
end;
$$;

revoke all on function private.cart_max_quantity() from public, anon, authenticated;
revoke all on function private.cart_max_lines() from public, anon, authenticated;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_cart_set_item', 'customer'),
  ('rpc_cart_add_item', 'customer'),
  ('rpc_cart_clear', 'customer'),
  ('rpc_get_my_cart', 'customer'),
  ('rpc_cart_acknowledge_prices', 'customer')
on conflict (function_name) do nothing;

select private.apply_function_grants();
