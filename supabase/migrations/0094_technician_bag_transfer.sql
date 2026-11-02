-- ============================================================================
-- 0094_technician_bag_transfer.sql
--
-- The technician moves stock himself between the main warehouse and his own
-- bag, both ways, from "شنطتي" — no admin approval:
--   * to_bag       → 'issue_to_technician', exactly like the admin's صرف
--   * to_warehouse → 'transfer' (enum value from 0001, unused until now)
-- apply_stock_movement (0010) moves the balances and refuses a quantity the
-- source doesn't hold, so neither side can go negative.
--
-- His bag only: the bag is looked up from auth.uid(), never passed in.
-- Every move stays in stock_movements with created_by = the technician.
--
-- The technician can't read warehouse_stock (admin/sales only, 0044), so
-- rpc_technician_warehouse_stock gives him just what he needs to pick from:
-- product, name, sku and quantity on hand — no prices.
--
-- p_client_request_id makes a retried call (response lost on a bad
-- connection) a no-op instead of a second move.
--
-- No table or column changes.
-- ============================================================================

create or replace function public.rpc_technician_warehouse_stock()
returns table (product_id uuid, name text, sku text, quantity int)
language plpgsql stable security definer set search_path = public as $$
begin
  if not (public.is_technician() or public.is_admin()) then raise exception 'FORBIDDEN'; end if;
  return query
    select p.id, p.name, p.sku, ws.quantity
    from public.warehouse_stock ws
    join public.warehouses w on w.id = ws.warehouse_id and w.type = 'main' and w.is_active
    join public.products p on p.id = ws.product_id
    where ws.quantity > 0 and p.is_active and not p.is_service
    order by p.name;
end;
$$;

create or replace function public.rpc_technician_bag_transfer(
  p_direction text, p_items jsonb, p_notes text, p_client_request_id uuid
) returns int language plpgsql security definer set search_path = public as $$
declare
  v_warehouse_id uuid;
  v_bag_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_qty int;
  v_product record;
  v_moved int := 0;
  v_notes text := nullif(btrim(coalesce(p_notes, '')), '');
begin
  if not public.is_technician() then raise exception 'FORBIDDEN'; end if;
  if p_direction is null or p_direction not in ('to_bag', 'to_warehouse') then
    raise exception 'INVALID_INPUT';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_ORDER';
  end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  select id into v_bag_id from public.technician_bags where technician_id = auth.uid();
  if v_bag_id is null then raise exception 'TECHNICIAN_BAG_NOT_FOUND'; end if;

  -- Claimed in this transaction: a failed transfer releases the id.
  if p_client_request_id is not null then
    insert into private.processed_requests (id, rpc, user_id)
    values (p_client_request_id, 'rpc_technician_bag_transfer', auth.uid())
    on conflict (id) do nothing;
    if not found then return 0; end if;
  end if;

  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) <> 'object' then raise exception 'INVALID_ITEM'; end if;
    begin
      v_product_id := (v_item ->> 'product_id')::uuid;
      v_qty := (v_item ->> 'quantity')::int;
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'INVALID_ITEM';
    end;
    if v_product_id is null then raise exception 'INVALID_ITEM'; end if;
    if v_qty is null or v_qty <= 0 then raise exception 'INVALID_QUANTITY'; end if;

    select id, cost_price, is_service into v_product from public.products where id = v_product_id;
    if not found or v_product.is_service then raise exception 'PRODUCT_NOT_FOUND: %', v_product_id; end if;

    if p_direction = 'to_bag' then
      insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, to_location_id, unit_cost, reference_type, notes, created_by)
      values (v_product_id, 'issue_to_technician', v_qty, 'warehouse', v_warehouse_id, 'technician_bag', v_bag_id, v_product.cost_price, 'technician_transfer',
              coalesce(v_notes, 'الصنايعي حوّل من المخزن لشنطته'), auth.uid());
    else
      insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, to_location_id, unit_cost, reference_type, notes, created_by)
      values (v_product_id, 'transfer', v_qty, 'technician_bag', v_bag_id, 'warehouse', v_warehouse_id, v_product.cost_price, 'technician_transfer',
              coalesce(v_notes, 'الصنايعي رجّع من شنطته للمخزن'), auth.uid());
    end if;
    v_moved := v_moved + 1;
  end loop;

  return v_moved;
end;
$$;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_technician_warehouse_stock', 'technician/admin'),
  ('rpc_technician_bag_transfer', 'technician (own bag)')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
