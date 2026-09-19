-- ============================================================================
-- 0047_sales_products_warehouse_lockdown.sql
--
-- Defense in depth to match 0046's UI change: sales no longer has a products
-- or warehouse-management screen at all (only "بيع مباشر", which reads
-- warehouse_stock to show what's actually in stock — that read stays).
-- This revokes the write/management-only grants 0044 gave sales, so a sales
-- account can't reach them even by calling the API directly, not just
-- through the app UI.
--
-- Left untouched on purpose (still genuinely used by "بيع مباشر" and the
-- rest of sales' current feature set):
--   * warehouse_stock SELECT — the walk-in sale screen's product picker
--     (AdminWalkInSaleScreen) is built directly from warehouseStockProvider,
--     filtered to quantity > 0; revoking this would break sales' own
--     landing screen, not just the warehouse-management screen it no
--     longer has.
--   * products SELECT (unrestricted for active rows since 0011; never
--     touched by 0044 or here) — also needed to sell.
--   * rpc_admin_walk_in_sale, orders RPCs, marketing, InstaPay review,
--     rpc_cashbox_withdraw (0045) — unrelated to products/warehouse
--     management, stay as they are.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Products — sales can no longer register or edit products.
-- ----------------------------------------------------------------------------
drop policy if exists products_insert_sales on public.products;
drop policy if exists products_update_sales on public.products;

-- ----------------------------------------------------------------------------
-- 2. Stock movement history — was only ever shown on the warehouse-
--    management screen sales no longer has; not read by "بيع مباشر".
-- ----------------------------------------------------------------------------
alter policy stock_movements_select on public.stock_movements
  using (
    public.is_admin()
    or (public.is_technician() and (
      from_location_id in (select id from public.technician_bags where technician_id = auth.uid())
      or to_location_id in (select id from public.technician_bags where technician_id = auth.uid())
    ))
  );

-- ----------------------------------------------------------------------------
-- 3. Receive purchase / issue stock to technician — back to admin-only.
--    Same bodies as 0044's versions, only the FORBIDDEN check narrows.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_receive_purchase(p_product_id uuid, p_quantity int, p_unit_cost numeric, p_notes text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_warehouse_id uuid;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_quantity <= 0 then raise exception 'INVALID_QUANTITY'; end if;
  if p_unit_cost < 0 then raise exception 'INVALID_AMOUNT'; end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, to_location_type, to_location_id, unit_cost, reference_type, notes, created_by)
  values (p_product_id, 'purchase', p_quantity, 'external', 'warehouse', v_warehouse_id, p_unit_cost, 'purchase', p_notes, auth.uid());

  update public.products set cost_price = p_unit_cost where id = p_product_id;
end;
$$;

create or replace function public.rpc_issue_stock_to_technician(p_technician_id uuid, p_items jsonb, p_notes text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_warehouse_id uuid;
  v_bag_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_qty int;
  v_product record;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_ORDER';
  end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  select id into v_bag_id from public.technician_bags where technician_id = p_technician_id;
  if v_bag_id is null then raise exception 'TECHNICIAN_BAG_NOT_FOUND'; end if;

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

    insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, to_location_id, unit_cost, reference_type, notes, created_by)
    values (v_product_id, 'issue_to_technician', v_qty, 'warehouse', v_warehouse_id, 'technician_bag', v_bag_id, v_product.cost_price, 'issue', p_notes, auth.uid());
  end loop;
end;
$$;

select private.apply_function_grants();
