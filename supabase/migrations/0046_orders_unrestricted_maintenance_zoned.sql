-- ============================================================================
-- 0046_orders_unrestricted_maintenance_zoned.sql
--
-- Flips which flow enforces service-area coverage, server-side (0045 already
-- did the Flutter/client-side half of this — this migration is what actually
-- makes it binding, since both rpc_create_order and
-- rpc_create_maintenance_request re-validate everything themselves and never
-- trust the client):
--
--   * Orders (checkout) — used to hard-refuse a non-serviceable address
--     (ADDRESS_NOT_SERVICEABLE, 0036). Now delivers anywhere: the address
--     still has to be one of the customer's own saved, active addresses
--     (ADDRESS_NOT_FOUND still applies), just not necessarily inside a live
--     service area.
--
--   * Maintenance requests — used to take free-text address/lat/lng with NO
--     server-side coverage check at all (0010/0030: "no GPS picker in v1").
--     Now takes a saved address id, same pattern 0036 already established
--     for orders, and refuses one outside a live service area
--     (ADDRESS_NOT_SERVICEABLE) — a technician can only be dispatched inside
--     a service area, so this is the flow that actually needs the gate.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. rpc_create_order — drop the coverage check, keep everything else.
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

    v_subtotal := v_subtotal + v_qty * v_product.selling_price;

    insert into public.order_items (order_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount)
    values (v_order_id, v_product.id, v_product.name, v_qty, v_product.selling_price, v_product.cost_price, 0);
  end loop;

  update public.orders set subtotal = v_subtotal where id = v_order_id;
  return v_order_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 2. rpc_create_maintenance_request — now zone-restricted via a saved
--    address id instead of trusting client-typed free text/coordinates.
--    Different parameter list (p_address text/p_latitude/p_longitude
--    replaced by p_address_id uuid) — same reasoning as 0036's comment: drop
--    the old signature explicitly or both overloads would exist side by
--    side, and the client-callable one would still be the old, unchecked one.
-- ----------------------------------------------------------------------------
drop function if exists public.rpc_create_maintenance_request(uuid, text, text, text, numeric, numeric, text, text, text);

create or replace function public.rpc_create_maintenance_request(
  p_customer_id uuid, p_customer_name text, p_phone text, p_address_id uuid,
  p_device_type text, p_problem_description text, p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_address record;
begin
  if not (public.is_admin() or (public.is_customer() and p_customer_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;
  if not exists (select 1 from public.customers where id = p_customer_id) then
    raise exception 'CUSTOMER_NOT_FOUND';
  end if;

  if p_customer_name is null or btrim(p_customer_name) = ''
     or p_problem_description is null or btrim(p_problem_description) = '' then
    raise exception 'INVALID_INPUT';
  end if;
  if p_phone is null or regexp_replace(p_phone, '[\s-]', '', 'g') !~ '^\+?[0-9]{8,15}$' then
    raise exception 'INVALID_PHONE';
  end if;
  if length(p_customer_name) > 100 or length(p_device_type) > 100
     or length(p_problem_description) > 2000 or length(p_notes) > 1000 then
    raise exception 'INPUT_TOO_LONG';
  end if;

  select * into v_address from public.customer_addresses
    where id = p_address_id and customer_id = p_customer_id and is_active;
  if not found then raise exception 'ADDRESS_NOT_FOUND'; end if;
  -- Maintenance IS zone-restricted (0046, reverse of orders above) — a
  -- technician can only be dispatched inside a live service area.
  if not private.address_is_serviceable(p_address_id) then
    raise exception 'ADDRESS_NOT_SERVICEABLE';
  end if;

  -- Abuse guard: a customer flooding the shared queue pushes everyone back.
  if not public.is_admin() and (
    select count(*) from public.maintenance_requests
    where customer_id = p_customer_id and status in ('waiting', 'assigned', 'in_progress')
  ) >= 5 then
    raise exception 'TOO_MANY_ACTIVE_REQUESTS';
  end if;

  insert into public.maintenance_requests (customer_id, customer_name, phone, address, latitude, longitude, device_type, problem_description, notes)
  values (
    p_customer_id, btrim(p_customer_name), regexp_replace(p_phone, '[\s-]', '', 'g'),
    -- Mirrors CustomerAddress.detailsLine on the Flutter side: address line
    -- plus whichever of building/floor/apartment/landmark were filled in.
    concat_ws(
      ' — ', v_address.address_line,
      nullif(concat_ws(
        '، ',
        case when v_address.building is not null then 'عمارة ' || v_address.building end,
        case when v_address.floor is not null then 'الدور ' || v_address.floor end,
        case when v_address.apartment is not null then 'شقة ' || v_address.apartment end,
        v_address.landmark
      ), '')
    ),
    v_address.latitude, v_address.longitude, nullif(btrim(p_device_type), ''),
    btrim(p_problem_description), nullif(btrim(p_notes), '')
  )
  returning id into v_id;

  return v_id;
end;
$$;

select private.apply_function_grants();
