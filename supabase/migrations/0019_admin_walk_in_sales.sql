-- ============================================================================
-- 0019_admin_walk_in_sales.sql
--
-- Lets an admin sell directly from the main warehouse to a walk-in customer
-- who doesn't have the app (counter sale). Reuses the existing sales /
-- sale_items tables — technician_id becomes optional so a walk-in sale can
-- have no technician attached; sales_select RLS already handles this
-- correctly (is_admin() OR technician_id = auth.uid(), and NULL never
-- equals auth.uid() so technicians simply never see these rows).
--
-- daily_sales_summary / monthly_sales_summary (0009_views.sql) already
-- aggregate every row in `sales` regardless of technician_id, so walk-in
-- sales show up in reporting for free — no view changes needed.
-- ============================================================================

alter table public.sales alter column technician_id drop not null;

create or replace function public.rpc_admin_walk_in_sale(
  p_customer_name text, p_customer_phone text, p_items jsonb,
  p_payment_method payment_method, p_discount numeric, p_client_request_id uuid, p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_sale_id uuid;
  v_existing uuid;
  v_warehouse_id uuid;
  v_item jsonb;
  v_product record;
  v_subtotal numeric(12,2) := 0;
  v_line_total numeric(12,2);
  v_total numeric(12,2);
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;

  if p_client_request_id is not null then
    select id into v_existing from public.sales where client_request_id = p_client_request_id;
    if v_existing is not null then return v_existing; end if;
  end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  insert into public.sales (technician_id, customer_name, customer_phone, payment_method, discount, client_request_id)
  values (null, p_customer_name, p_customer_phone, p_payment_method, coalesce(p_discount, 0), p_client_request_id)
  returning id into v_sale_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select id, name, selling_price, cost_price into v_product
      from public.products where id = (v_item ->> 'product_id')::uuid for update;
    if v_product.id is null then raise exception 'PRODUCT_NOT_FOUND: %', v_item ->> 'product_id'; end if;

    v_line_total := (v_item ->> 'quantity')::int * v_product.selling_price - coalesce((v_item ->> 'discount')::numeric, 0);
    v_subtotal := v_subtotal + v_line_total;

    insert into public.sale_items (sale_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount)
    values (v_sale_id, v_product.id, v_product.name, (v_item ->> 'quantity')::int, v_product.selling_price, v_product.cost_price, coalesce((v_item ->> 'discount')::numeric, 0));

    -- Atomic decrement + INSUFFICIENT_STOCK guard happens inside apply_stock_movement().
    insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
    values (v_product.id, 'sale', (v_item ->> 'quantity')::int, 'warehouse', v_warehouse_id, 'external', v_product.cost_price, 'sale', v_sale_id, p_notes, auth.uid());
  end loop;

  v_total := v_subtotal - coalesce(p_discount, 0);
  update public.sales set subtotal = v_subtotal, paid_amount = v_total where id = v_sale_id;

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  select id, 'sale', v_total, 'sale', v_sale_id, coalesce(p_notes, 'بيع مباشر من المعرض'), auth.uid()
  from public.cashboxes where is_active limit 1;

  return v_sale_id;
end;
$$;
