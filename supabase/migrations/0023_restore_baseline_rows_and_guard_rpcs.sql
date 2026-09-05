-- ============================================================================
-- 0023_restore_baseline_rows_and_guard_rpcs.sql
--
-- Found via live admin testing: "استلام بضاعة" always failed with the generic
-- "تعذَّر تنفيذ العملية" and the expense "التصنيف" dropdown was empty. Root
-- cause was not the app: the baseline rows seeded by 0013_seed.sql — the main
-- warehouse, the cashbox, and every expense category — had been deleted from
-- the database, so:
--
--   * rpc_receive_purchase resolved v_warehouse_id to NULL, then inserted a
--     stock_movement with to_location_id = NULL, which apply_stock_movement()
--     turned into a NOT NULL violation on warehouse_stock.warehouse_id —
--     surfacing as an opaque failure with no hint of the real problem.
--   * rpc_record_expense's cash_transactions INSERT ... SELECT matched zero
--     cashbox rows, so it silently inserted the expense while never debiting
--     the till — worse than an error, because the books quietly drift.
--   * expense_categories was empty, so the category dropdown had nothing to
--     show and the screen looked broken.
--
-- Part 1 restores those baseline rows idempotently. Part 2 makes the RPCs
-- fail loudly and specifically if the rows ever go missing again, so the
-- cause is obvious instead of being hidden behind a constraint violation or,
-- worse, silently swallowed.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Restore the baseline setup rows (idempotent — safe to re-run).
--    Deliberately NOT re-seeding business data (products, orders, customers):
--    only the singleton config rows the system cannot operate without.
-- ----------------------------------------------------------------------------

insert into public.warehouses (name, type)
select 'المخزن الرئيسي', 'main'
where not exists (select 1 from public.warehouses where type = 'main' and is_active);

insert into public.cashboxes (name)
select 'خزنة المعرض الرئيسية'
where not exists (select 1 from public.cashboxes where is_active);

insert into public.expense_categories (name)
select v.name
from (values ('كهرباء'), ('إيجار'), ('نقل'), ('مرتبات'), ('صيانة'), ('شراء أدوات'), ('مصاريف أخرى'))
  as v(name)
on conflict (name) do nothing;

-- ----------------------------------------------------------------------------
-- 2. Guard the RPCs so a missing singleton is reported precisely.
-- ----------------------------------------------------------------------------

-- rpc_receive_purchase: NO_MAIN_WAREHOUSE instead of a NOT NULL violation.
-- (rpc_admin_walk_in_sale already raises this; receiving never did.)
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

-- rpc_record_expense: refuse rather than record an expense that never hits
-- the cashbox. The two writes must both happen or neither.
create or replace function public.rpc_record_expense(p_category_id uuid, p_amount numeric, p_expense_date date, p_notes text, p_attachment_url text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_expense_id uuid;
  v_cashbox_id uuid;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;

  select id into v_cashbox_id from public.cashboxes where is_active limit 1;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

  insert into public.expenses (category_id, amount, expense_date, notes, attachment_url, created_by)
  values (p_category_id, p_amount, coalesce(p_expense_date, current_date), p_notes, p_attachment_url, auth.uid())
  returning id into v_expense_id;

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  values (v_cashbox_id, 'expense', -p_amount, 'expense', v_expense_id, p_notes, auth.uid());

  return v_expense_id;
end;
$$;

-- rpc_admin_walk_in_sale: same silent-no-op risk on its cashbox write — the
-- sale would be recorded and stock deducted while the till never saw the cash.
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

  select id into v_cashbox_id from public.cashboxes where is_active limit 1;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

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
  values (v_cashbox_id, 'sale', v_total, 'sale', v_sale_id, coalesce(p_notes, 'بيع مباشر من المعرض'), auth.uid());

  return v_sale_id;
end;
$$;
