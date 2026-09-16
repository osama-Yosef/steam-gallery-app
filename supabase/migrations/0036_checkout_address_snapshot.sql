-- ============================================================================
-- 0036_checkout_address_snapshot.sql  (Phase 8 — checkout)
--
-- rpc_create_order used to take free-text delivery_address/latitude/longitude
-- typed straight into the checkout form: no link to a saved address, and no
-- server-side service-availability check at all (Phase 3/0032 built the
-- coverage machinery — private.address_is_serviceable() — and explicitly
-- deferred wiring it into checkout to this phase).
--
-- This makes checkout choose one of the customer's own saved addresses
-- (customer_addresses, 0032) and:
--   * refuses the order if that address isn't inside a live service area
--     (ADDRESS_NOT_SERVICEABLE) — server-side, same as every other rule here;
--   * snapshots the address onto the order at that moment (recipient, phone,
--     building/floor/apartment/landmark, coordinates, city/service area), so
--     later edits or deletions of the saved address never change a past
--     order (Customer Address ≠ Order Delivery Address).
--
-- No table is dropped; the old free-text delivery_* columns stay (now filled
-- from the snapshot instead of client text) so nothing else that reads them
-- breaks.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Snapshot columns on orders
-- ----------------------------------------------------------------------------
alter table public.orders
  add column delivery_address_id uuid references public.customer_addresses(id),
  add column delivery_recipient_name text,
  add column delivery_phone text,
  add column delivery_building text,
  add column delivery_floor text,
  add column delivery_apartment text,
  add column delivery_landmark text,
  add column delivery_city_id uuid references public.cities(id),
  add column delivery_service_area_id uuid references public.service_areas(id);

-- ----------------------------------------------------------------------------
-- 2. rpc_create_order: pick a saved, serviceable address (P8-1)
-- ----------------------------------------------------------------------------
-- Different parameter list than 0029's version (p_delivery_address/latitude/
-- longitude replaced by p_address_id) — Postgres treats that as a distinct
-- overload, so the old signature must be dropped explicitly or both would
-- exist side by side (the client-callable one would still be the old,
-- unchecked one).
drop function if exists public.rpc_create_order(uuid, jsonb, text, numeric, numeric, text, uuid);

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
  -- Re-checked here even though rpc_save_my_address already resolved it: the
  -- area may have been switched off, or the address saved before this rule
  -- existed. Same helper Phase 3 built for exactly this call site.
  if not private.address_is_serviceable(p_address_id) then
    raise exception 'ADDRESS_NOT_SERVICEABLE';
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

    v_subtotal := v_subtotal + v_qty * v_product.selling_price;

    insert into public.order_items (order_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount)
    values (v_order_id, v_product.id, v_product.name, v_qty, v_product.selling_price, v_product.cost_price, 0);
  end loop;

  update public.orders set subtotal = v_subtotal where id = v_order_id;
  return v_order_id;
end;
$$;

-- rpc_create_order keeps its allowlist entry (function_name is the same);
-- only re-apply the grants for the new overload.
select private.apply_function_grants();
