-- ============================================================================
-- 0077_assembly_products_in_storefront.sql
--
-- Assembly products ("صنف تجميع", 0075) become sellable in the customer
-- storefront, not only at the walk-in register.
--
-- An assembly holds no stock of its own, so everywhere the storefront asked
-- "is this in stock?" by summing warehouse_stock it now asks
-- private.fn_available_qty(), which for an assembly is how many can be built
-- from its components:
--   * products_public (catalog, offers, product detail, related products)
--   * rpc_browse_products (store search / filters / "available only")
--   * rpc_get_my_cart (per-line "is_available")
--
-- Orders follow the same stock path as before, at the same moments:
--   * rpc_confirm_order takes an assembly's components out of the warehouse
--     (via private.fn_sale_stock_out) and refuses, naming the short
--     component, if any is missing. What was taken is remembered per order
--     line in order_item_components (order_items is append-only).
--   * rpc_cancel_order / rpc_admin_return_order put back what was taken —
--     the remembered components for an assembly line, the product itself
--     otherwise (private.fn_order_restock).
-- Bodies are 0065's / 0044's with only the stock loops changed.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Availability, for normal and assembly products alike.
-- ----------------------------------------------------------------------------
create or replace function private.fn_available_qty(p_product_id uuid) returns int
language sql stable security definer set search_path = public as $$
  select case
    when p.is_assembly then coalesce((
      select min(coalesce(ws.qty, 0) / pc.quantity)::int
      from public.product_components pc
      left join (
        select product_id, sum(quantity) as qty
        from public.warehouse_stock group by product_id
      ) ws on ws.product_id = pc.component_id
      where pc.assembly_id = p.id
    ), 0)
    else coalesce((
      select sum(ws.quantity)::int from public.warehouse_stock ws where ws.product_id = p.id
    ), 0)
  end
  from public.products p where p.id = p_product_id;
$$;
-- Called from products_public, which runs as the querying role (same
-- arrangement as private.fn_effective_price, 0061).
revoke all on function private.fn_available_qty(uuid) from public, anon;
grant execute on function private.fn_available_qty(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- fn_sale_stock_out (0075) learns which ledger the movements belong to:
-- 'sale' for walk-in sales (unchanged default), 'order' for customer orders.
-- ----------------------------------------------------------------------------
drop function if exists private.fn_sale_stock_out(uuid, int, uuid, uuid, text);

create or replace function private.fn_sale_stock_out(
  p_product_id uuid, p_qty int, p_sale_id uuid, p_warehouse_id uuid, p_notes text,
  p_reference_type text default 'sale'
) returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_product record;
  v_comp record;
  v_cost numeric(12,2) := 0;
  v_components jsonb := '[]'::jsonb;
  v_have int;
begin
  select id, name, cost_price, is_service, is_assembly into v_product
    from public.products where id = p_product_id;
  if not found then raise exception 'PRODUCT_NOT_FOUND: %', p_product_id; end if;

  if v_product.is_service then
    return jsonb_build_object('unit_cost', 0, 'components', null);
  end if;

  if not v_product.is_assembly then
    insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
    values (v_product.id, 'sale', p_qty, 'warehouse', p_warehouse_id, 'external', v_product.cost_price, p_reference_type, p_sale_id, p_notes, auth.uid());
    return jsonb_build_object('unit_cost', v_product.cost_price, 'components', null);
  end if;

  if not exists (select 1 from public.product_components where assembly_id = v_product.id) then
    raise exception 'ASSEMBLY_HAS_NO_COMPONENTS: %', v_product.name;
  end if;

  for v_comp in
    select pc.component_id, pc.quantity, p.name, p.cost_price
    from public.product_components pc join public.products p on p.id = pc.component_id
    where pc.assembly_id = v_product.id
    order by p.name
  loop
    select coalesce(sum(quantity), 0) into v_have from public.warehouse_stock
      where warehouse_id = p_warehouse_id and product_id = v_comp.component_id;
    if v_have < v_comp.quantity * p_qty then
      raise exception 'INSUFFICIENT_COMPONENT: %', v_comp.name;
    end if;
  end loop;

  for v_comp in
    select pc.component_id, pc.quantity, p.name, p.cost_price
    from public.product_components pc join public.products p on p.id = pc.component_id
    where pc.assembly_id = v_product.id
  loop
    insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
    values (v_comp.component_id, 'sale', v_comp.quantity * p_qty, 'warehouse', p_warehouse_id, 'external', v_comp.cost_price, p_reference_type, p_sale_id,
            coalesce(p_notes || ' · ', '') || 'مكون من ' || v_product.name, auth.uid());
    v_cost := v_cost + v_comp.quantity * v_comp.cost_price;
    v_components := v_components || jsonb_build_object(
      'product_id', v_comp.component_id, 'quantity', v_comp.quantity, 'unit_cost', v_comp.cost_price);
  end loop;

  return jsonb_build_object('unit_cost', v_cost, 'components', v_components);
end;
$$;
revoke all on function private.fn_sale_stock_out(uuid, int, uuid, uuid, text, text) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- What an assembly order line actually took out of the warehouse.
-- ----------------------------------------------------------------------------
create table if not exists public.order_item_components (
  order_item_id uuid primary key references public.order_items(id),
  -- [{"product_id": .., "quantity": <per unit>, "unit_cost": ..}, ...]
  components jsonb not null,
  created_at timestamptz not null default now()
);
alter table public.order_item_components enable row level security;
drop policy if exists order_item_components_select on public.order_item_components;
create policy order_item_components_select on public.order_item_components for select to authenticated
  using (public.is_admin() or public.is_sales());

-- Puts an order's stock back: an assembly line's remembered components, or
-- the product itself for every other line.
create or replace function private.fn_order_restock(p_order_id uuid, p_warehouse_id uuid, p_note text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_item record;
  v_comp jsonb;
begin
  for v_item in
    select oi.*, oic.components from public.order_items oi
    left join public.order_item_components oic on oic.order_item_id = oi.id
    where oi.order_id = p_order_id
  loop
    if jsonb_typeof(v_item.components) = 'array' then
      for v_comp in select value from jsonb_array_elements(v_item.components) loop
        insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, to_location_type, to_location_id, unit_cost, reference_type, reference_id, notes, created_by)
        values ((v_comp ->> 'product_id')::uuid, 'return_from_customer',
                (v_comp ->> 'quantity')::int * v_item.quantity, 'external', 'warehouse', p_warehouse_id,
                (v_comp ->> 'unit_cost')::numeric, 'order', p_order_id,
                p_note || ' · مكون من ' || v_item.product_name_snapshot, auth.uid());
      end loop;
    else
      insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, to_location_type, to_location_id, unit_cost, reference_type, reference_id, notes, created_by)
      values (v_item.product_id, 'return_from_customer', v_item.quantity, 'external', 'warehouse', p_warehouse_id, v_item.unit_cost_snapshot, 'order', p_order_id, p_note, auth.uid());
    end if;
  end loop;
end;
$$;
revoke all on function private.fn_order_restock(uuid, uuid, text) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- Storefront availability (0061's view, availability via fn_available_qty).
-- ----------------------------------------------------------------------------
create or replace view public.products_public as
select
  p.id, p.sku, p.barcode, p.category_id, p.name, p.description, p.specs,
  private.fn_effective_price(p.id)::numeric(12,2) as selling_price, p.is_active, p.created_at,
  private.fn_available_qty(p.id) > 0 as is_available,
  img.image_url as primary_image_url,
  p.is_featured,
  p.featured_sort
from public.products p
left join lateral (
  select image_url from public.product_images pi
  where pi.product_id = p.id
  order by pi.is_primary desc, pi.sort_order asc
  limit 1
) img on true
where p.is_active = true and p.is_service = false;

-- ----------------------------------------------------------------------------
-- Store browsing (0034's function, availability via fn_available_qty).
-- ----------------------------------------------------------------------------
create or replace function public.rpc_browse_products(
  p_search text default null,
  p_category_id uuid default null,
  p_min_price numeric default null,
  p_max_price numeric default null,
  p_available_only boolean default false,
  p_sort text default 'newest',
  p_limit int default 20,
  p_offset int default 0
)
returns setof public.products_public
language plpgsql stable security definer set search_path = '' as $$
declare
  v_term text;
  v_sort text := coalesce(p_sort, 'newest');
begin
  -- Suspended users (and unverified customers when the switch is on) are
  -- 'anon' here, same as everywhere else.
  if public.auth_role() = 'anon' then
    raise exception 'FORBIDDEN';
  end if;

  if v_sort not in ('newest', 'price_asc', 'price_desc', 'name') then
    raise exception 'INVALID_SORT';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 50
     or p_offset is null or p_offset < 0 or p_offset > 10000 then
    raise exception 'INVALID_PAGE';
  end if;
  if (p_min_price is not null and p_min_price < 0)
     or (p_max_price is not null and p_max_price < 0)
     or (p_min_price is not null and p_max_price is not null and p_min_price > p_max_price) then
    raise exception 'INVALID_PRICE_RANGE';
  end if;
  if length(p_search) > 100 then
    raise exception 'INPUT_TOO_LONG';
  end if;

  v_term := nullif(btrim(public.search_key(p_search)), '');
  if v_term is not null then
    v_term := '%' || replace(replace(replace(v_term, '\', '\\'), '%', '\%'), '_', '\_') || '%';
  end if;

  return query
  with recursive cats as (
    select c.id from public.product_categories c where c.id = p_category_id
    union
    select c.id from public.product_categories c join cats on c.parent_id = cats.id
  ),
  page as (
    select
      p.id, p.sku, p.barcode, p.category_id, p.name, p.description, p.specs,
      p.selling_price, p.is_active, p.created_at,
      private.fn_available_qty(p.id) > 0 as is_available,
      p.is_featured, p.featured_sort
    from public.products p
    where p.is_active
      and not p.is_service
      and (p_category_id is null or p.category_id in (select id from cats))
      and (p_min_price is null or p.selling_price >= p_min_price)
      and (p_max_price is null or p.selling_price <= p_max_price)
      and (v_term is null or public.search_key(p.name || ' ' || p.sku) like v_term)
  )
  select
    pg.id, pg.sku, pg.barcode, pg.category_id, pg.name, pg.description, pg.specs,
    pg.selling_price, pg.is_active, pg.created_at, pg.is_available,
    (
      select pi.image_url from public.product_images pi
      where pi.product_id = pg.id
      order by pi.is_primary desc, pi.sort_order asc
      limit 1
    ) as primary_image_url,
    pg.is_featured, pg.featured_sort
  from page pg
  where not coalesce(p_available_only, false) or pg.is_available
  order by
    case when v_sort = 'price_asc' then pg.selling_price end asc,
    case when v_sort = 'price_desc' then pg.selling_price end desc,
    case when v_sort = 'name' then pg.name end asc,
    case when v_sort = 'newest' then pg.created_at end desc,
    pg.id
  limit p_limit offset p_offset;
end;
$$;

-- ----------------------------------------------------------------------------
-- Cart (0061's function, availability via fn_available_qty).
-- ----------------------------------------------------------------------------
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
      'unit_price', private.fn_effective_price(p.id) + coalesce((
        select sum(po.extra_price) from public.product_options po where po.id = any(ci.option_ids)), 0),
      'price_seen', ci.price_seen,
      'price_changed', (private.fn_effective_price(p.id) + coalesce((
        select sum(po.extra_price) from public.product_options po where po.id = any(ci.option_ids)), 0)) <> ci.price_seen,
      'line_total', case when p.is_active and not p.is_service
                         then (private.fn_effective_price(p.id) + coalesce((
                           select sum(po.extra_price) from public.product_options po where po.id = any(ci.option_ids)), 0)) * ci.quantity
                         else 0 end,
      'is_active', p.is_active and not p.is_service,
      'is_available', p.is_active and not p.is_service and private.fn_available_qty(p.id) >= ci.quantity,
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

-- ----------------------------------------------------------------------------
-- Order confirm / cancel / return (0065 / 0044 bodies, stock loops changed).
-- ----------------------------------------------------------------------------
create or replace function public.rpc_confirm_order(p_order_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_warehouse_id uuid;
  v_item record;
  v_customer_id uuid;
  v_total numeric(12,2);
  v_shipping_fee_status text;
  v_out jsonb;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  select customer_id, total, shipping_fee_status into v_customer_id, v_total, v_shipping_fee_status
    from public.orders where id = p_order_id and status = 'pending' for update;
  if v_customer_id is null then raise exception 'ORDER_NOT_PENDING'; end if;
  if v_shipping_fee_status <> 'approved' then raise exception 'SHIPPING_FEE_NOT_APPROVED'; end if;

  for v_item in
    select oi.*, p.is_assembly from public.order_items oi
    join public.products p on p.id = oi.product_id
    where oi.order_id = p_order_id
  loop
    if v_item.is_assembly then
      -- Components out of the warehouse (refused, naming the short one, if
      -- any is missing), and what was taken remembered for a later
      -- cancel/return.
      v_out := private.fn_sale_stock_out(v_item.product_id, v_item.quantity, p_order_id,
                                         v_warehouse_id, 'بيع - تأكيد طلب', 'order');
      insert into public.order_item_components (order_item_id, components)
      values (v_item.id, v_out -> 'components')
      on conflict (order_item_id) do update set components = excluded.components;
    else
      insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
      values (v_item.product_id, 'sale', v_item.quantity, 'warehouse', v_warehouse_id, 'external', v_item.unit_cost_snapshot, 'order', p_order_id, 'بيع - تأكيد طلب', auth.uid());
    end if;
  end loop;

  update public.orders set status = 'confirmed', confirmed_by = auth.uid() where id = p_order_id;

  insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
  values (v_customer_id, 'order_charge', v_total, p_order_id, 'قيمة الطلب', auth.uid());

  perform public.notify_user(v_customer_id, 'order_status', 'تم تأكيد طلبك', 'جاري تجهيز طلبك الآن', jsonb_build_object('order_id', p_order_id));
end;
$$;

create or replace function public.rpc_cancel_order(p_order_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_warehouse_id uuid;
  v_item record;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_reason is null or btrim(p_reason) = '' then raise exception 'REASON_REQUIRED'; end if;
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.status in ('completed', 'cancelled', 'returned') then
    raise exception 'ORDER_NOT_CANCELLABLE';
  end if;

  if v_order.status <> 'pending' then
    select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
    if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

    perform private.fn_order_restock(p_order_id, v_warehouse_id, 'إلغاء طلب');

    insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
    values (v_order.customer_id, 'return_credit', -v_order.total, p_order_id, 'إلغاء طلب', auth.uid());
  end if;

  perform private.fn_apply_order_refund(p_order_id, p_reason);

  update public.orders
    set status = 'cancelled', cancelled_reason = btrim(p_reason),
        payment_status = case when v_order.paid_amount > 0 then 'refunded' else payment_status end
    where id = p_order_id;
  perform public.notify_user(v_order.customer_id, 'order_status', 'تم إلغاء طلبك', btrim(p_reason),
    jsonb_build_object('order_id', p_order_id, 'status', 'cancelled'));
end;
$$;

create or replace function public.rpc_admin_return_order(p_order_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_warehouse_id uuid;
  v_item record;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_reason is null or btrim(p_reason) = '' then raise exception 'REASON_REQUIRED'; end if;
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.status not in ('delivered', 'completed') then
    raise exception 'ORDER_NOT_RETURNABLE';
  end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  perform private.fn_order_restock(p_order_id, v_warehouse_id, 'إرجاع طلب');

  insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
  values (v_order.customer_id, 'return_credit', -v_order.total, p_order_id, 'إرجاع طلب', auth.uid());

  perform private.fn_apply_order_refund(p_order_id, p_reason);

  update public.orders
    set status = 'returned', cancelled_reason = btrim(p_reason),
        payment_status = case when v_order.paid_amount > 0 then 'refunded' else payment_status end
    where id = p_order_id;
  perform public.notify_user(v_order.customer_id, 'order_status', 'تم استلام إرجاع طلبك', btrim(p_reason),
    jsonb_build_object('order_id', p_order_id, 'status', 'returned'));
end;
$$;

select private.apply_function_grants();
notify pgrst, 'reload schema';
