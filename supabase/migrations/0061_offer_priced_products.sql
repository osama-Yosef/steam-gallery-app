-- ============================================================================
-- 0061_offer_priced_products.sql
--
-- Reverses a deliberate decision from 0033 ("عروض خاصة وقت ما أحب لكن
-- السعر ثابت" — offers whenever I like, but the price stays fixed"):
-- offers can now optionally set a discounted price per product. Confirmed
-- with the business owner today as a change of mind, not an oversight.
--
-- Design: products.selling_price is NEVER overwritten — an offer's
-- discounted price lives only on offer_products.offer_price, and
-- private.fn_effective_price() picks it up ONLY while the offer is live
-- (is_active and inside its schedule). The moment an offer ends, is turned
-- off, or its price is cleared, every price calculation reads
-- products.selling_price again automatically — nothing to "revert" by
-- hand, because the real price was never touched in the first place.
--
-- Applied everywhere a unit price is derived from a product: the customer
-- storefront (products_public), the cart (rpc_cart_set_item,
-- rpc_get_my_cart, rpc_cart_acknowledge_prices), rpc_create_order, and
-- rpc_admin_walk_in_sale. If a product is (rarely) in more than one live
-- discounted offer at once, the lowest offer price wins.
-- ============================================================================

-- Guarded (if not exists): same live drift as 0049/0058/0059 (found
-- 2026-09-19) — this column, and private.fn_effective_price() below, had
-- already been applied out-of-band while rpc_create_order further down in
-- this same file had not, leaving orders charge raw selling_price with no
-- offer awareness despite the cart already showing the discounted price.
alter table public.offer_products
  add column if not exists offer_price numeric(12,2) check (offer_price is null or offer_price >= 0);

create or replace function private.fn_effective_price(p_product_id uuid) returns numeric
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select min(op.offer_price)
       from public.offer_products op
       join public.offers o on o.id = op.offer_id
      where op.product_id = p_product_id
        and op.offer_price is not null
        and o.is_active
        and (o.starts_at is null or o.starts_at <= now())
        and (o.ends_at is null or o.ends_at > now())),
    (select p.selling_price from public.products p where p.id = p_product_id)
  );
$$;
-- Unlike a SECURITY DEFINER function calling another function (where the
-- callee's permission check runs as the definer, e.g. private.setting_text
-- from rpc_get_instapay_details), a plain VIEW does not carry its own
-- identity into function calls in its SELECT list — the querying role
-- itself needs EXECUTE. products_public is `to authenticated`, so this
-- matches that audience exactly rather than the usual private.* lockdown.
revoke all on function private.fn_effective_price(uuid) from public, anon;
grant execute on function private.fn_effective_price(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- Customer storefront: the price shown IS the price charged.
-- ----------------------------------------------------------------------------
create or replace view public.products_public as
select
  p.id, p.sku, p.barcode, p.category_id, p.name, p.description, p.specs,
  private.fn_effective_price(p.id)::numeric(12,2) as selling_price, p.is_active, p.created_at,
  coalesce(ws.total_qty, 0) > 0 as is_available,
  img.image_url as primary_image_url,
  p.is_featured,
  p.featured_sort
from public.products p
left join (
  select product_id, sum(quantity) as total_qty
  from public.warehouse_stock
  group by product_id
) ws on ws.product_id = p.id
left join lateral (
  select image_url from public.product_images pi
  where pi.product_id = p.id
  order by pi.is_primary desc, pi.sort_order asc
  limit 1
) img on true
where p.is_active = true and p.is_service = false;

-- ----------------------------------------------------------------------------
-- Cart: set/add, the live read, and price-change acknowledgment.
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

  if not exists (
    select 1 from public.products p
     where p.id = p_product_id and p.is_active and not p.is_service
  ) then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;
  v_price := private.fn_effective_price(p_product_id);

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
     set price_seen = private.fn_effective_price(ci.product_id) + coalesce((
           select sum(po.extra_price) from public.product_options po where po.id = any(ci.option_ids)), 0),
         updated_at = now()
    from public.products p
   where p.id = ci.product_id and ci.customer_id = auth.uid()
     and ci.price_seen <> (private.fn_effective_price(ci.product_id) + coalesce((
           select sum(po.extra_price) from public.product_options po where po.id = any(ci.option_ids)), 0));
  return public.rpc_get_my_cart();
end;
$$;

-- ----------------------------------------------------------------------------
-- rpc_create_order: same re-pricing discipline, effective price instead of
-- the raw column.
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

    v_unit_price := private.fn_effective_price(v_product.id) + v_options_total;
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

-- ----------------------------------------------------------------------------
-- rpc_admin_walk_in_sale: non-service lines charge the effective price.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_admin_walk_in_sale(
  p_customer_name text, p_customer_phone text, p_items jsonb,
  p_payment_method payment_method, p_discount numeric, p_client_request_id uuid, p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_sale_id uuid;
  v_existing uuid;
  v_warehouse_id uuid;
  v_cashbox_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_product record;
  v_qty int;
  v_unit_price numeric(12,2);
  v_line_discount numeric(12,2);
  v_discount numeric(12,2) := coalesce(p_discount, 0);
  v_subtotal numeric(12,2) := 0;
  v_total numeric(12,2);
  v_kind text;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_payment_method is null or p_payment_method = 'deferred' then
    raise exception 'DEFERRED_NOT_SUPPORTED';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_ORDER';
  end if;
  if jsonb_array_length(p_items) > 100 then raise exception 'TOO_MANY_ITEMS'; end if;
  if v_discount < 0 or v_discount <> round(v_discount, 2) then raise exception 'INVALID_DISCOUNT'; end if;

  if p_client_request_id is not null then
    select id into v_existing from public.sales where client_request_id = p_client_request_id;
    if v_existing is not null then return v_existing; end if;
  end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  v_kind := case when p_payment_method = 'cash' then 'cash' else 'transfer' end;
  select id into v_cashbox_id from public.cashboxes where kind = v_kind and is_active limit 1;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

  insert into public.sales (technician_id, customer_name, customer_phone, payment_method, discount, client_request_id)
  values (null, nullif(btrim(p_customer_name), ''), nullif(btrim(p_customer_phone), ''), p_payment_method, v_discount, p_client_request_id)
  returning id into v_sale_id;

  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) <> 'object' then raise exception 'INVALID_ITEM'; end if;
    begin
      v_product_id := (v_item ->> 'product_id')::uuid;
      v_qty := (v_item ->> 'quantity')::int;
      v_line_discount := coalesce((v_item ->> 'discount')::numeric, 0);
      v_unit_price := (v_item ->> 'unit_price')::numeric;
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'INVALID_ITEM';
    end;
    if v_product_id is null then raise exception 'INVALID_ITEM'; end if;
    if v_qty is null or v_qty <= 0 or v_qty > 999 then raise exception 'INVALID_QUANTITY'; end if;

    select id, name, selling_price, cost_price, is_service into v_product
      from public.products where id = v_product_id for update;
    if not found then raise exception 'PRODUCT_NOT_FOUND: %', v_product_id; end if;

    if v_product.is_service then
      if v_unit_price is null or v_unit_price <= 0 or v_unit_price <> round(v_unit_price, 2) then
        raise exception 'INVALID_AMOUNT';
      end if;
    else
      v_unit_price := private.fn_effective_price(v_product.id);
    end if;

    if v_line_discount < 0 or v_line_discount > v_qty * v_unit_price then
      raise exception 'INVALID_DISCOUNT';
    end if;

    v_subtotal := v_subtotal + v_qty * v_unit_price - v_line_discount;

    insert into public.sale_items (sale_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount)
    values (v_sale_id, v_product.id, v_product.name, v_qty, v_unit_price,
            case when v_product.is_service then 0 else v_product.cost_price end, v_line_discount);

    if not v_product.is_service then
      insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
      values (v_product.id, 'sale', v_qty, 'warehouse', v_warehouse_id, 'external', v_product.cost_price, 'sale', v_sale_id, p_notes, auth.uid());
    end if;
  end loop;

  if v_discount > v_subtotal then raise exception 'INVALID_DISCOUNT'; end if;
  v_total := v_subtotal - v_discount;
  update public.sales set subtotal = v_subtotal, paid_amount = v_total where id = v_sale_id;

  if v_total > 0 then
    insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
    values (v_cashbox_id, 'sale', v_total, 'sale', v_sale_id, coalesce(p_notes, 'بيع مباشر من المعرض'), auth.uid());
  end if;

  return v_sale_id;
end;
$$;

select private.apply_function_grants();
notify pgrst, 'reload schema';
