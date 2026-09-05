-- ============================================================================
-- 0027_service_items_and_maintenance_invoice.sql
--
-- Two requested features that share one foundation: a "service" line — sold
-- at a price typed in at sale time, with no cost and no stock movement.
--
--   * The technician finishes a job, then invoices it: the maintenance fee
--     plus whatever parts came out of their bag, so the customer can see what
--     was done and what it totalled.
--   * The same service line is sellable from the counter (walk-in sale).
--
-- Modelled as a flag on products rather than a separate table so the whole
-- existing sale_items / reporting / invoice machinery keeps working unchanged:
-- a service is just a product with is_service = true, cost 0, and a price
-- supplied per sale. Services are excluded from the customer catalogue and
-- from stock reporting, since neither concept applies to them.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Schema
-- ----------------------------------------------------------------------------

alter table public.products
  add column if not exists is_service boolean not null default false;

comment on column public.products.is_service is
  'A service (labour) line: no stock, cost always 0, price supplied per sale.';

-- One invoice per maintenance request. The UNIQUE also makes invoicing
-- idempotent: a double-tap can never produce two invoices for one job.
alter table public.sales
  add column if not exists maintenance_request_id uuid
    references public.maintenance_requests(id);

create unique index if not exists sales_maintenance_request_id_key
  on public.sales (maintenance_request_id)
  where maintenance_request_id is not null;

-- The single maintenance service line (one service, price set per invoice).
insert into public.products (sku, name, description, cost_price, selling_price, is_service)
select 'SERVICE-MAINT', 'خدمة صيانة', 'أجر خدمة الصيانة — السعر يُحدَّد وقت الفاتورة', 0, 0, true
where not exists (select 1 from public.products where sku = 'SERVICE-MAINT');

-- ----------------------------------------------------------------------------
-- 2. Keep services out of stock/catalogue surfaces
-- ----------------------------------------------------------------------------

-- Catalogue: a service is not something a customer browses or adds to a cart.
-- (Definer semantics deliberately retained — see 0024.)
alter view public.products_public set (security_invoker = false);

create or replace view public.products_public as
select
  p.id, p.sku, p.barcode, p.category_id, p.name, p.description, p.specs,
  p.selling_price, p.is_active, p.created_at,
  coalesce(ws.total_qty, 0) > 0 as is_available,
  img.image_url as primary_image_url
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

grant select on public.products_public to authenticated;

-- Low stock: a service has no stock row, so without this it would sit in the
-- low-stock list permanently (0 <= min_stock) and fire low-stock alerts.
create or replace view public.low_stock_products
  with (security_invoker = true) as
select p.id as product_id, p.name, p.sku, p.min_stock, coalesce(ws.quantity, 0) as current_quantity
from public.products p
left join public.warehouse_stock ws on ws.product_id = p.id
where p.is_active = true and p.is_service = false
  and coalesce(ws.quantity, 0) <= p.min_stock;

-- ----------------------------------------------------------------------------
-- 3. Sales RPCs accept service lines
--
-- Item contract (jsonb): { product_id, quantity, discount?, unit_price? }
--   * stock product — unit_price is ignored; the product's selling_price is
--     authoritative, so a client can't quietly re-price the catalogue.
--   * service      — unit_price is required (that's the whole point), cost is
--     forced to 0, and no stock movement is written.
-- ----------------------------------------------------------------------------

-- Signature gains p_maintenance_request_id, so the old one must go rather than
-- become an overload PostgREST can't choose between.
drop function if exists public.rpc_technician_sale(uuid, uuid, text, text, jsonb, payment_method, numeric, numeric, uuid, text);

create or replace function public.rpc_technician_sale(
  p_technician_id uuid, p_customer_id uuid, p_customer_name text, p_customer_phone text,
  p_items jsonb, p_payment_method payment_method, p_discount numeric, p_paid_amount numeric,
  p_client_request_id uuid, p_notes text, p_maintenance_request_id uuid default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_sale_id uuid;
  v_existing uuid;
  v_bag_id uuid;
  v_item jsonb;
  v_product record;
  v_qty int;
  v_unit_price numeric(12,2);
  v_subtotal numeric(12,2) := 0;
  v_line_total numeric(12,2);
begin
  if not (public.is_admin() or (public.is_technician() and p_technician_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;

  if p_client_request_id is not null then
    select id into v_existing from public.sales where client_request_id = p_client_request_id;
    if v_existing is not null then return v_existing; end if;
  end if;

  -- Re-invoicing the same job returns the existing invoice instead of failing
  -- on the unique index.
  if p_maintenance_request_id is not null then
    select id into v_existing from public.sales where maintenance_request_id = p_maintenance_request_id;
    if v_existing is not null then return v_existing; end if;
  end if;

  select id into v_bag_id from public.technician_bags where technician_id = p_technician_id;
  if v_bag_id is null then raise exception 'TECHNICIAN_BAG_NOT_FOUND'; end if;

  insert into public.sales (technician_id, customer_id, customer_name, customer_phone, payment_method, discount, paid_amount, client_request_id, maintenance_request_id)
  values (p_technician_id, p_customer_id, p_customer_name, p_customer_phone, p_payment_method, coalesce(p_discount, 0), coalesce(p_paid_amount, 0), p_client_request_id, p_maintenance_request_id)
  returning id into v_sale_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    select id, name, selling_price, cost_price, is_service into v_product
      from public.products where id = (v_item ->> 'product_id')::uuid;
    if v_product.id is null then raise exception 'PRODUCT_NOT_FOUND: %', v_item ->> 'product_id'; end if;

    v_qty := (v_item ->> 'quantity')::int;
    if v_qty <= 0 then raise exception 'INVALID_QUANTITY'; end if;

    if v_product.is_service then
      v_unit_price := coalesce((v_item ->> 'unit_price')::numeric, 0);
      if v_unit_price <= 0 then raise exception 'INVALID_AMOUNT'; end if;
    else
      v_unit_price := v_product.selling_price;
    end if;

    v_line_total := v_qty * v_unit_price - coalesce((v_item ->> 'discount')::numeric, 0);
    v_subtotal := v_subtotal + v_line_total;

    insert into public.sale_items (sale_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount)
    values (v_sale_id, v_product.id, v_product.name, v_qty, v_unit_price,
            case when v_product.is_service then 0 else v_product.cost_price end,
            coalesce((v_item ->> 'discount')::numeric, 0));

    -- Labour has nothing to take out of the bag.
    if not v_product.is_service then
      -- Atomic decrement happens inside apply_stock_movement(); raises
      -- INSUFFICIENT_STOCK and rolls back the whole sale if the bag is short.
      insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
      values (v_product.id, 'technician_sale', v_qty, 'technician_bag', v_bag_id, 'external', v_product.cost_price, 'sale', v_sale_id, p_notes, auth.uid());
    end if;
  end loop;

  update public.sales set subtotal = v_subtotal where id = v_sale_id;

  if p_payment_method = 'deferred' and p_customer_id is not null then
    insert into public.customer_account_transactions (customer_id, transaction_type, amount, notes, created_by)
    values (p_customer_id, 'order_charge', v_subtotal - coalesce(p_discount, 0), 'بيع صنايعي آجل', auth.uid());
  elsif coalesce(p_paid_amount, 0) > 0 then
    insert into public.technician_account_transactions (technician_id, transaction_type, amount, sale_id, notes, created_by)
    values (p_technician_id, 'sale_credit', p_paid_amount, v_sale_id, 'تحصيل بيع', auth.uid());
  end if;

  return v_sale_id;
end;
$$;

-- Walk-in counter sale: same service support (feature 7). Signature unchanged.
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
  v_qty int;
  v_unit_price numeric(12,2);
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
    select id, name, selling_price, cost_price, is_service into v_product
      from public.products where id = (v_item ->> 'product_id')::uuid for update;
    if v_product.id is null then raise exception 'PRODUCT_NOT_FOUND: %', v_item ->> 'product_id'; end if;

    v_qty := (v_item ->> 'quantity')::int;
    if v_qty <= 0 then raise exception 'INVALID_QUANTITY'; end if;

    if v_product.is_service then
      v_unit_price := coalesce((v_item ->> 'unit_price')::numeric, 0);
      if v_unit_price <= 0 then raise exception 'INVALID_AMOUNT'; end if;
    else
      v_unit_price := v_product.selling_price;
    end if;

    v_line_total := v_qty * v_unit_price - coalesce((v_item ->> 'discount')::numeric, 0);
    v_subtotal := v_subtotal + v_line_total;

    insert into public.sale_items (sale_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount)
    values (v_sale_id, v_product.id, v_product.name, v_qty, v_unit_price,
            case when v_product.is_service then 0 else v_product.cost_price end,
            coalesce((v_item ->> 'discount')::numeric, 0));

    if not v_product.is_service then
      insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
      values (v_product.id, 'sale', v_qty, 'warehouse', v_warehouse_id, 'external', v_product.cost_price, 'sale', v_sale_id, p_notes, auth.uid());
    end if;
  end loop;

  v_total := v_subtotal - coalesce(p_discount, 0);
  update public.sales set subtotal = v_subtotal, paid_amount = v_total where id = v_sale_id;

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  values (v_cashbox_id, 'sale', v_total, 'sale', v_sale_id, coalesce(p_notes, 'بيع مباشر من المعرض'), auth.uid());

  return v_sale_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. The customer must be able to read the invoice for their own job.
--    sales_select is admin/own-technician only, so a customer could never see
--    the invoice raised against their maintenance request.
-- ----------------------------------------------------------------------------
drop policy if exists sales_select on public.sales;
create policy sales_select on public.sales for select to authenticated
  using (
    public.is_admin()
    or technician_id = auth.uid()
    or customer_id = auth.uid()
    or maintenance_request_id in (
      select id from public.maintenance_requests where customer_id = auth.uid()
    )
  );

-- Mirrors sales_select explicitly rather than leaning on RLS-inside-subquery,
-- so the two can be read side by side and can't silently diverge.
drop policy if exists sale_items_select on public.sale_items;
create policy sale_items_select on public.sale_items for select to authenticated
  using (
    public.is_admin()
    or sale_id in (
      select s.id from public.sales s
      where s.technician_id = auth.uid()
         or s.customer_id = auth.uid()
         or s.maintenance_request_id in (
           select mr.id from public.maintenance_requests mr where mr.customer_id = auth.uid()
         )
    )
  );
