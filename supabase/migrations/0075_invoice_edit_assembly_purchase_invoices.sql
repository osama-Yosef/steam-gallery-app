-- ============================================================================
-- 0075_invoice_edit_assembly_purchase_invoices.sql
--
-- Three admin back-office additions:
--
-- 1. Editable walk-in invoices ("بيع مباشر"). An invoice can be opened from
--    the history and edited — add a product, remove one, change a quantity,
--    change the discount — or deleted outright.
--
--    sale_items / stock_movements / cash_transactions stay append-only
--    ledgers (prevent_mutation, 0003/0005/0006). An edit is expressed as
--    ledger entries, never as an UPDATE of an old line:
--      * less of a product  -> a sale_item_returns row through the same
--        private.fn_return_sale_item the returns screen uses (restock +
--        prorated amount), with its cash leg skipped;
--      * more of a product  -> a new sale_items row + its stock movement;
--      * money              -> ONE cash movement for the difference between
--        the invoice's new total and what the cash ledger currently holds
--        for this sale. Reconciling against the ledger (not against a stored
--        number) makes the RPC declarative: p_items is the invoice's final
--        state, so replaying the same call (an offline queue retry) is a
--        no-op.
--
--    To keep "sales.total = what the invoice is currently worth", a return
--    now also takes its value out of sales.subtotal/discount (the discount
--    by exactly the share the refund already excluded), so the invoice-level
--    discount ratio — and therefore every later prorated refund — is
--    unchanged.
--
-- 2. Assembly products ("صنف تجميع"): a product made of other products.
--    It holds no stock of its own; selling one takes its components out of
--    the main warehouse, and the sale is refused if any component is short.
--    The components used are snapshotted on the sale line so a return puts
--    back what was actually taken, even if the recipe changed since.
--
-- 3. Purchase invoices ("فاتورة شراء") replacing the bare "receive stock"
--    form: supplier, lines, discount, and how it was paid — cash or transfer
--    till, fully, partly, or deferred (آجل). Unpaid amounts are the
--    supplier's balance, settled later through rpc_pay_supplier.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2. Assembly products — schema first, the sale helpers below depend on it.
-- ----------------------------------------------------------------------------
alter table public.products add column if not exists is_assembly boolean not null default false;

create table if not exists public.product_components (
  id uuid primary key default gen_random_uuid(),
  assembly_id uuid not null references public.products(id) on delete cascade,
  component_id uuid not null references public.products(id),
  quantity int not null check (quantity > 0),
  unique (assembly_id, component_id),
  check (assembly_id <> component_id)
);
create index if not exists idx_product_components_assembly on public.product_components (assembly_id);

alter table public.product_components enable row level security;
drop policy if exists product_components_select on public.product_components;
create policy product_components_select on public.product_components for select to authenticated
  using (public.is_admin() or public.is_sales());

-- What was actually taken out of the warehouse for an assembly line:
-- [{"product_id": .., "quantity": <per unit>, "unit_cost": ..}, ...].
alter table public.sale_items add column if not exists components jsonb;

-- How many of each assembly product the warehouse can build right now.
-- Reads warehouse_stock only (v1 has a single, main warehouse): the sales
-- role can read warehouse_stock but not public.warehouses (0011/0047), and
-- this view runs as the caller.
create or replace view public.assembly_availability
  with (security_invoker = true) as
select pc.assembly_id as product_id,
  min(coalesce(ws.quantity, 0) / pc.quantity)::int as available
from public.product_components pc
left join (
  select product_id, sum(quantity)::int as quantity
  from public.warehouse_stock group by product_id
) ws on ws.product_id = pc.component_id
group by pc.assembly_id;

-- Sets (or clears) a product's recipe. p_components: [{product_id, quantity}].
create or replace function public.rpc_admin_set_assembly(
  p_product_id uuid, p_is_assembly boolean, p_components jsonb
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_product record;
  v_item jsonb;
  v_component record;
  v_component_id uuid;
  v_qty int;
  v_cost numeric(12,2) := 0;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;

  select * into v_product from public.products where id = p_product_id for update;
  if not found then raise exception 'PRODUCT_NOT_FOUND: %', p_product_id; end if;

  if not coalesce(p_is_assembly, false) then
    delete from public.product_components where assembly_id = p_product_id;
    update public.products set is_assembly = false where id = p_product_id;
    return;
  end if;

  if v_product.is_service then raise exception 'SERVICE_CANNOT_BE_ASSEMBLY'; end if;
  if exists (select 1 from public.product_components where component_id = p_product_id) then
    raise exception 'COMPONENT_CANNOT_BE_ASSEMBLY';
  end if;
  if exists (select 1 from public.warehouse_stock where product_id = p_product_id and quantity > 0) then
    raise exception 'ASSEMBLY_HAS_STOCK';
  end if;
  if p_components is null or jsonb_typeof(p_components) <> 'array' or jsonb_array_length(p_components) = 0 then
    raise exception 'ASSEMBLY_NEEDS_COMPONENTS';
  end if;
  if jsonb_array_length(p_components) > 50 then raise exception 'TOO_MANY_ITEMS'; end if;

  delete from public.product_components where assembly_id = p_product_id;

  for v_item in select value from jsonb_array_elements(p_components) loop
    begin
      v_component_id := (v_item ->> 'product_id')::uuid;
      v_qty := (v_item ->> 'quantity')::int;
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'INVALID_ITEM';
    end;
    if v_component_id is null then raise exception 'INVALID_ITEM'; end if;
    if v_qty is null or v_qty <= 0 or v_qty > 999 then raise exception 'INVALID_QUANTITY'; end if;
    if v_component_id = p_product_id then raise exception 'INVALID_ITEM'; end if;

    select id, cost_price, is_service, is_assembly into v_component
      from public.products where id = v_component_id;
    if not found then raise exception 'PRODUCT_NOT_FOUND: %', v_component_id; end if;
    if v_component.is_service or v_component.is_assembly then
      raise exception 'INVALID_COMPONENT';
    end if;

    insert into public.product_components (assembly_id, component_id, quantity)
    values (p_product_id, v_component_id, v_qty)
    on conflict (assembly_id, component_id)
      do update set quantity = public.product_components.quantity + excluded.quantity;
    v_cost := v_cost + v_qty * v_component.cost_price;
  end loop;

  -- The catalogue cost of an assembly is its components' cost — shown in the
  -- product list; the sale itself re-costs from the components at sale time.
  update public.products set is_assembly = true, cost_price = v_cost where id = p_product_id;
end;
$$;

-- Takes p_qty of a product out of the main warehouse for a sale and returns
-- {"unit_cost": .., "components": [...] | null}. Services take nothing.
create or replace function private.fn_sale_stock_out(
  p_product_id uuid, p_qty int, p_sale_id uuid, p_warehouse_id uuid, p_notes text
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
    values (v_product.id, 'sale', p_qty, 'warehouse', p_warehouse_id, 'external', v_product.cost_price, 'sale', p_sale_id, p_notes, auth.uid());
    return jsonb_build_object('unit_cost', v_product.cost_price, 'components', null);
  end if;

  if not exists (select 1 from public.product_components where assembly_id = v_product.id) then
    raise exception 'ASSEMBLY_HAS_NO_COMPONENTS: %', v_product.name;
  end if;

  -- Check every component before moving any, so the error names the short
  -- one instead of whichever the trigger happened to hit first.
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
    values (v_comp.component_id, 'sale', v_comp.quantity * p_qty, 'warehouse', p_warehouse_id, 'external', v_comp.cost_price, 'sale', p_sale_id,
            coalesce(p_notes || ' · ', '') || 'مكون من ' || v_product.name, auth.uid());
    v_cost := v_cost + v_comp.quantity * v_comp.cost_price;
    v_components := v_components || jsonb_build_object(
      'product_id', v_comp.component_id, 'quantity', v_comp.quantity, 'unit_cost', v_comp.cost_price);
  end loop;

  return jsonb_build_object('unit_cost', v_cost, 'components', v_components);
end;
$$;
revoke all on function private.fn_sale_stock_out(uuid, int, uuid, uuid, text) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- rpc_admin_walk_in_sale (0061's body) — stock now goes out through
-- fn_sale_stock_out so assembly products work at the counter.
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
  v_out jsonb;
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

    v_out := private.fn_sale_stock_out(v_product.id, v_qty, v_sale_id, v_warehouse_id, p_notes);

    insert into public.sale_items (sale_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount, components)
    values (v_sale_id, v_product.id, v_product.name, v_qty, v_unit_price,
            (v_out ->> 'unit_cost')::numeric, v_line_discount,
            case when jsonb_typeof(v_out -> 'components') = 'array' then v_out -> 'components' end);
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

-- ----------------------------------------------------------------------------
-- private.fn_return_sale_item (0063's body) plus:
--   * p_skip_cash: the invoice editor reconciles money once at the end;
--   * assembly lines put their snapshotted components back;
--   * the returned value leaves sales.subtotal/discount (see header).
-- A new trailing parameter is a new signature — drop the old one first
-- (0050/0053/0063 lesson) so the 4-arg callers resolve to this one.
-- ----------------------------------------------------------------------------
drop function if exists private.fn_return_sale_item(uuid, int, text, text);

create or replace function private.fn_return_sale_item(
  p_sale_item_id uuid, p_quantity int, p_reason text,
  p_refund_kind text default null, p_skip_cash boolean default false
)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_item record;
  v_sale record;
  v_already_returned int;
  v_warehouse_id uuid;
  v_cashbox_id uuid;
  v_balance numeric(14,2);
  v_gross numeric(12,2);
  v_line_discount_share numeric(12,2);
  v_pre_sale_discount numeric(12,2);
  v_sale_discount_share numeric(12,2);
  v_refund numeric(12,2);
  v_remaining_on_sale int;
  v_kind text;
  v_comp jsonb;
begin
  if p_refund_kind is not null and p_refund_kind not in ('cash', 'transfer') then
    raise exception 'INVALID_REFUND_KIND';
  end if;

  select si.*, p.is_service into v_item
    from public.sale_items si join public.products p on p.id = si.product_id
    where si.id = p_sale_item_id;
  if not found then raise exception 'SALE_ITEM_NOT_FOUND'; end if;

  select * into v_sale from public.sales where id = v_item.sale_id for update;
  if v_sale.technician_id is not null then raise exception 'NOT_A_WALK_IN_SALE'; end if;
  if v_sale.status <> 'completed' then raise exception 'SALE_NOT_RETURNABLE'; end if;

  if p_quantity is null or p_quantity <= 0 then raise exception 'INVALID_QUANTITY'; end if;

  select coalesce(sum(quantity), 0) into v_already_returned
    from public.sale_item_returns where sale_item_id = p_sale_item_id;
  if p_quantity > v_item.quantity - v_already_returned then
    raise exception 'RETURN_QUANTITY_EXCEEDS_REMAINING';
  end if;

  if not v_item.is_service then
    select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
    if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

    if jsonb_typeof(v_item.components) = 'array' then
      for v_comp in select value from jsonb_array_elements(v_item.components) loop
        insert into public.stock_movements (
          product_id, movement_type, quantity, from_location_type, to_location_type,
          to_location_id, unit_cost, reference_type, reference_id, notes, created_by
        ) values (
          (v_comp ->> 'product_id')::uuid, 'return_from_customer',
          (v_comp ->> 'quantity')::int * p_quantity, 'external', 'warehouse',
          v_warehouse_id, (v_comp ->> 'unit_cost')::numeric, 'sale', v_sale.id,
          btrim(p_reason) || ' · مكون من ' || v_item.product_name_snapshot, auth.uid()
        );
      end loop;
    else
      insert into public.stock_movements (
        product_id, movement_type, quantity, from_location_type, to_location_type,
        to_location_id, unit_cost, reference_type, reference_id, notes, created_by
      ) values (
        v_item.product_id, 'return_from_customer', p_quantity, 'external', 'warehouse',
        v_warehouse_id, v_item.unit_cost_snapshot, 'sale', v_sale.id, btrim(p_reason), auth.uid()
      );
    end if;
  end if;

  v_gross := v_item.unit_price_snapshot * p_quantity;
  v_line_discount_share := v_item.discount * p_quantity / v_item.quantity;
  v_pre_sale_discount := v_gross - v_line_discount_share;
  v_sale_discount_share := case when v_sale.subtotal > 0
    then v_sale.discount * v_pre_sale_discount / v_sale.subtotal else 0 end;
  v_refund := greatest(round(v_pre_sale_discount - v_sale_discount_share, 2), 0);

  if v_refund > 0 and not p_skip_cash then
    v_kind := coalesce(p_refund_kind, case when v_sale.payment_method = 'cash' then 'cash' else 'transfer' end);
    select id into v_cashbox_id from public.cashboxes where kind = v_kind and is_active limit 1 for update;
    if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

    select coalesce(sum(amount), 0) into v_balance
      from public.cash_transactions where cashbox_id = v_cashbox_id;
    if v_refund > v_balance then raise exception 'INSUFFICIENT_CASH: %', v_balance; end if;

    insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
    values (v_cashbox_id, 'refund', -v_refund, 'sale', v_sale.id, btrim(p_reason), auth.uid());
  end if;

  insert into public.sale_item_returns (sale_item_id, quantity, refund_amount, reason, created_by)
  values (p_sale_item_id, p_quantity, v_refund, btrim(p_reason), auth.uid());

  -- Keep sales.total equal to the invoice's current value: the subtotal
  -- loses the returned lines' value, the discount loses exactly the share
  -- the refund did not include. The discount/subtotal ratio is unchanged.
  update public.sales set
    subtotal = greatest(subtotal - v_pre_sale_discount, 0),
    discount = least(greatest(discount - (v_pre_sale_discount - v_refund), 0),
                     greatest(subtotal - v_pre_sale_discount, 0)),
    paid_amount = case when p_skip_cash then paid_amount else greatest(paid_amount - v_refund, 0) end
  where id = v_sale.id;

  if not p_skip_cash then
    select coalesce(sum(quantity - returned_quantity), 0) into v_remaining_on_sale
      from public.sale_items_with_returns where sale_id = v_sale.id;
    if v_remaining_on_sale = 0 then
      update public.sales set status = 'returned' where id = v_sale.id;
    end if;
  end if;
end;
$$;
revoke all on function private.fn_return_sale_item(uuid, int, text, text, boolean) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- 1. Invoice editing.
--
-- p_items is the invoice's FINAL content: [{product_id, quantity,
-- unit_price?}] — unit_price is only read for a service line being added.
-- A product missing from p_items is removed from the invoice. p_discount
-- null keeps the current discount. p_money_kind picks the till for the
-- difference (default: the till the sale was paid into).
-- ----------------------------------------------------------------------------
create or replace function public.rpc_admin_edit_sale(
  p_sale_id uuid, p_items jsonb, p_discount numeric, p_reason text,
  p_money_kind text default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_sale record;
  v_before jsonb;
  v_desired jsonb := '{}'::jsonb;
  v_item jsonb;
  v_product_id uuid;
  v_qty int;
  v_price numeric(12,2);
  v_line record;
  v_want int;
  v_have int;
  v_to_return int;
  v_take int;
  v_li record;
  v_product record;
  v_warehouse_id uuid;
  v_out jsonb;
  v_key text;
  v_discount numeric(12,2);
  v_target numeric(12,2);
  v_held numeric(12,2);
  v_delta numeric(12,2);
  v_kind text;
  v_cashbox_id uuid;
  v_balance numeric(14,2);
  v_remaining int;
  v_reason text := coalesce(nullif(btrim(p_reason), ''), 'تعديل فاتورة');
  v_note text;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if length(v_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;
  if p_money_kind is not null and p_money_kind not in ('cash', 'transfer') then
    raise exception 'INVALID_REFUND_KIND';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' then raise exception 'INVALID_ITEM'; end if;
  if jsonb_array_length(p_items) > 100 then raise exception 'TOO_MANY_ITEMS'; end if;

  select * into v_sale from public.sales where id = p_sale_id for update;
  if not found then raise exception 'SALE_NOT_FOUND'; end if;
  if v_sale.technician_id is not null then raise exception 'NOT_A_WALK_IN_SALE'; end if;
  if v_sale.status <> 'completed' then raise exception 'SALE_NOT_EDITABLE'; end if;
  v_before := to_jsonb(v_sale);
  v_note := v_reason || ' · فاتورة #' || v_sale.sale_number;

  -- Desired quantity (and optional service price) per product.
  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) <> 'object' then raise exception 'INVALID_ITEM'; end if;
    begin
      v_product_id := (v_item ->> 'product_id')::uuid;
      v_qty := (v_item ->> 'quantity')::int;
      v_price := (v_item ->> 'unit_price')::numeric;
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'INVALID_ITEM';
    end;
    if v_product_id is null then raise exception 'INVALID_ITEM'; end if;
    if v_qty is null or v_qty < 0 or v_qty > 999 then raise exception 'INVALID_QUANTITY'; end if;
    v_desired := jsonb_set(v_desired, array[v_product_id::text], jsonb_build_object(
      'quantity', coalesce((v_desired -> v_product_id::text ->> 'quantity')::int, 0) + v_qty,
      'unit_price', coalesce(v_price, (v_desired -> v_product_id::text ->> 'unit_price')::numeric)));
  end loop;

  -- Less of a product (or none): return the difference, newest lines first.
  for v_line in
    select product_id, sum(quantity - returned_quantity)::int as remaining
    from public.sale_items_with_returns where sale_id = p_sale_id
    group by product_id
  loop
    v_want := coalesce((v_desired -> v_line.product_id::text ->> 'quantity')::int, 0);
    if v_want < v_line.remaining then
      v_to_return := v_line.remaining - v_want;
      for v_li in
        select id, quantity - returned_quantity as left_qty
        from public.sale_items_with_returns
        where sale_id = p_sale_id and product_id = v_line.product_id and returned_quantity < quantity
        order by unit_price_snapshot asc, id
      loop
        exit when v_to_return <= 0;
        v_take := least(v_to_return, v_li.left_qty);
        perform private.fn_return_sale_item(v_li.id, v_take, v_note, null, true);
        v_to_return := v_to_return - v_take;
      end loop;
    end if;
  end loop;

  -- More of a product (or a new one): a new line at the invoice's existing
  -- price for it, else today's effective price (a service: the given price).
  for v_key in select jsonb_object_keys(v_desired) loop
    v_want := (v_desired -> v_key ->> 'quantity')::int;
    select coalesce(sum(quantity - returned_quantity), 0)::int into v_have
      from public.sale_items_with_returns where sale_id = p_sale_id and product_id = v_key::uuid;
    if v_want > v_have then
      v_qty := v_want - v_have;
      select id, name, is_service into v_product from public.products where id = v_key::uuid for update;
      if not found then raise exception 'PRODUCT_NOT_FOUND: %', v_key; end if;

      if v_product.is_service then
        v_price := (v_desired -> v_key ->> 'unit_price')::numeric;
        if v_price is null then
          select unit_price_snapshot into v_price from public.sale_items
            where sale_id = p_sale_id and product_id = v_product.id order by unit_price_snapshot desc limit 1;
        end if;
        if v_price is null or v_price <= 0 or v_price <> round(v_price, 2) then
          raise exception 'INVALID_AMOUNT';
        end if;
      else
        select unit_price_snapshot into v_price from public.sale_items_with_returns
          where sale_id = p_sale_id and product_id = v_product.id and returned_quantity < quantity
          order by unit_price_snapshot desc limit 1;
        v_price := coalesce(v_price, private.fn_effective_price(v_product.id));
      end if;

      if v_warehouse_id is null then
        select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
        if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;
      end if;

      v_out := private.fn_sale_stock_out(v_product.id, v_qty, p_sale_id, v_warehouse_id, v_note);

      insert into public.sale_items (sale_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount, components)
      values (p_sale_id, v_product.id, v_product.name, v_qty, v_price,
              (v_out ->> 'unit_cost')::numeric, 0,
              case when jsonb_typeof(v_out -> 'components') = 'array' then v_out -> 'components' end);

      update public.sales set subtotal = subtotal + v_qty * v_price where id = p_sale_id;
    end if;
  end loop;

  select * into v_sale from public.sales where id = p_sale_id;
  select coalesce(sum(quantity - returned_quantity), 0)::int into v_remaining
    from public.sale_items_with_returns where sale_id = p_sale_id;
  if v_remaining = 0 then raise exception 'EMPTY_ORDER'; end if;

  v_discount := coalesce(p_discount, v_sale.discount);
  if v_discount < 0 or v_discount <> round(v_discount, 2) or v_discount > v_sale.subtotal then
    raise exception 'INVALID_DISCOUNT';
  end if;
  v_target := v_sale.subtotal - v_discount;

  -- Money: settle the difference between the new total and what the cash
  -- ledger holds for this sale, in one movement.
  select coalesce(sum(amount), 0) into v_held
    from public.cash_transactions where reference_type = 'sale' and reference_id = p_sale_id;
  v_delta := v_target - v_held;

  if v_delta <> 0 then
    v_kind := coalesce(p_money_kind, case when v_sale.payment_method = 'cash' then 'cash' else 'transfer' end);
    select id into v_cashbox_id from public.cashboxes where kind = v_kind and is_active limit 1 for update;
    if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

    if v_delta > 0 then
      insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
      values (v_cashbox_id, 'sale', v_delta, 'sale', p_sale_id, v_note, auth.uid());
    else
      select coalesce(sum(amount), 0) into v_balance
        from public.cash_transactions where cashbox_id = v_cashbox_id;
      if -v_delta > v_balance then raise exception 'INSUFFICIENT_CASH: %', v_balance; end if;
      insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
      values (v_cashbox_id, 'refund', v_delta, 'sale', p_sale_id, v_note, auth.uid());
    end if;
  end if;

  update public.sales set discount = v_discount, paid_amount = v_target where id = p_sale_id;

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'SALE_EDITED', 'sales', p_sale_id, v_before,
          (select to_jsonb(s) from public.sales s where s.id = p_sale_id));
end;
$$;

-- Deletes (cancels) an invoice: everything still on it goes back to stock,
-- its money back out of the till, status -> cancelled. Repeating it on an
-- invoice that is already cancelled is a no-op, so an offline-queued delete
-- can be replayed safely.
create or replace function public.rpc_admin_delete_sale(
  p_sale_id uuid, p_reason text, p_refund_kind text default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_sale record;
  v_item record;
  v_reason text := coalesce(nullif(btrim(p_reason), ''), 'حذف فاتورة');
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if length(v_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_sale from public.sales where id = p_sale_id;
  if not found then raise exception 'SALE_NOT_FOUND'; end if;
  if v_sale.technician_id is not null then raise exception 'NOT_A_WALK_IN_SALE'; end if;
  if v_sale.status = 'cancelled' then return; end if;

  if v_sale.status = 'completed' then
    for v_item in select * from public.sale_items_with_returns where sale_id = p_sale_id
    loop
      if v_item.returned_quantity < v_item.quantity then
        perform private.fn_return_sale_item(v_item.id, v_item.quantity - v_item.returned_quantity,
          v_reason || ' · فاتورة #' || v_sale.sale_number, p_refund_kind);
      end if;
    end loop;
  end if;

  update public.sales set status = 'cancelled' where id = p_sale_id;

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'SALE_DELETED', 'sales', p_sale_id, to_jsonb(v_sale),
          (select to_jsonb(s) from public.sales s where s.id = p_sale_id));
end;
$$;

-- ----------------------------------------------------------------------------
-- 3. Suppliers & purchase invoices.
-- ----------------------------------------------------------------------------
create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create unique index if not exists idx_suppliers_name on public.suppliers (lower(btrim(name)));

create table if not exists public.purchase_invoices (
  id uuid primary key default gen_random_uuid(),
  invoice_number bigserial unique,
  supplier_id uuid not null references public.suppliers(id),
  supplier_invoice_ref text,
  invoice_date date not null default current_date,
  subtotal numeric(12,2) not null default 0 check (subtotal >= 0),
  discount numeric(12,2) not null default 0 check (discount >= 0),
  total numeric(12,2) generated always as (subtotal - discount) stored,
  notes text,
  client_request_id uuid unique,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);
create index if not exists idx_purchase_invoices_supplier on public.purchase_invoices (supplier_id);

create table if not exists public.purchase_invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.purchase_invoices(id),
  product_id uuid not null references public.products(id),
  product_name_snapshot text not null,
  quantity int not null check (quantity > 0),
  unit_cost numeric(12,2) not null check (unit_cost >= 0),
  line_total numeric(14,2) generated always as (quantity * unit_cost) stored
);
create index if not exists idx_purchase_invoice_items_invoice on public.purchase_invoice_items (invoice_id);

create table if not exists public.supplier_payments (
  id uuid primary key default gen_random_uuid(),
  payment_number bigserial unique,
  supplier_id uuid not null references public.suppliers(id),
  invoice_id uuid references public.purchase_invoices(id),
  amount numeric(12,2) not null check (amount > 0),
  kind text not null check (kind in ('cash', 'transfer')),
  notes text,
  client_request_id uuid,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);
create index if not exists idx_supplier_payments_supplier on public.supplier_payments (supplier_id);
create index if not exists idx_supplier_payments_invoice on public.supplier_payments (invoice_id);
create index if not exists idx_supplier_payments_request on public.supplier_payments (client_request_id);

drop trigger if exists trg_purchase_invoice_items_no_update on public.purchase_invoice_items;
create trigger trg_purchase_invoice_items_no_update
  before update or delete on public.purchase_invoice_items
  for each row execute function public.prevent_mutation();
drop trigger if exists trg_supplier_payments_no_update on public.supplier_payments;
create trigger trg_supplier_payments_no_update
  before update or delete on public.supplier_payments
  for each row execute function public.prevent_mutation();

alter table public.suppliers enable row level security;
alter table public.purchase_invoices enable row level security;
alter table public.purchase_invoice_items enable row level security;
alter table public.supplier_payments enable row level security;

-- Admin only, same audience as the warehouse since 0047. Writes go through
-- the RPCs below (no insert/update policies).
drop policy if exists suppliers_select on public.suppliers;
create policy suppliers_select on public.suppliers for select to authenticated using (public.is_admin());
drop policy if exists purchase_invoices_select on public.purchase_invoices;
create policy purchase_invoices_select on public.purchase_invoices for select to authenticated using (public.is_admin());
drop policy if exists purchase_invoice_items_select on public.purchase_invoice_items;
create policy purchase_invoice_items_select on public.purchase_invoice_items for select to authenticated using (public.is_admin());
drop policy if exists supplier_payments_select on public.supplier_payments;
create policy supplier_payments_select on public.supplier_payments for select to authenticated using (public.is_admin());

create or replace view public.purchase_invoices_summary
  with (security_invoker = true) as
select pi.*, s.name as supplier_name, s.phone as supplier_phone,
  coalesce(sp.paid, 0)::numeric(12,2) as paid_amount,
  (pi.total - coalesce(sp.paid, 0))::numeric(12,2) as remaining_amount,
  (select count(*) from public.purchase_invoice_items i where i.invoice_id = pi.id)::int as items_count
from public.purchase_invoices pi
join public.suppliers s on s.id = pi.supplier_id
left join (
  select invoice_id, sum(amount) as paid from public.supplier_payments
  where invoice_id is not null group by invoice_id
) sp on sp.invoice_id = pi.id;

create or replace view public.supplier_balances
  with (security_invoker = true) as
select s.id as supplier_id, s.name, s.phone, s.is_active,
  coalesce(inv.total, 0)::numeric(14,2) as total_invoices,
  coalesce(pay.total, 0)::numeric(14,2) as total_paid,
  (coalesce(inv.total, 0) - coalesce(pay.total, 0))::numeric(14,2) as balance,
  coalesce(inv.n, 0)::int as invoices_count
from public.suppliers s
left join (select supplier_id, sum(total) as total, count(*) as n from public.purchase_invoices group by supplier_id) inv
  on inv.supplier_id = s.id
left join (select supplier_id, sum(amount) as total from public.supplier_payments group by supplier_id) pay
  on pay.supplier_id = s.id;

-- Pays p_amount out of the p_kind till to a supplier, recorded against
-- p_invoice_id, or — when null — against their oldest unpaid invoices first.
create or replace function private.fn_pay_supplier(
  p_supplier_id uuid, p_amount numeric, p_kind text, p_invoice_id uuid,
  p_notes text, p_client_request_id uuid
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_cashbox_id uuid;
  v_balance numeric(14,2);
  v_left numeric(12,2) := p_amount;
  v_inv record;
  v_take numeric(12,2);
begin
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then raise exception 'INVALID_AMOUNT'; end if;
  if p_kind is null or p_kind not in ('cash', 'transfer') then raise exception 'INVALID_INPUT'; end if;

  select id into v_cashbox_id from public.cashboxes where kind = p_kind and is_active limit 1 for update;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;
  select coalesce(sum(amount), 0) into v_balance from public.cash_transactions where cashbox_id = v_cashbox_id;
  if p_amount > v_balance then raise exception 'INSUFFICIENT_CASH: %', v_balance; end if;

  for v_inv in
    select id, remaining_amount from public.purchase_invoices_summary
    where supplier_id = p_supplier_id and remaining_amount > 0
      and (p_invoice_id is null or id = p_invoice_id)
    order by invoice_date, invoice_number
  loop
    exit when v_left <= 0;
    v_take := least(v_left, v_inv.remaining_amount);
    insert into public.supplier_payments (supplier_id, invoice_id, amount, kind, notes, client_request_id, created_by)
    values (p_supplier_id, v_inv.id, v_take, p_kind, nullif(btrim(p_notes), ''), p_client_request_id, auth.uid());
    v_left := v_left - v_take;
  end loop;
  if v_left > 0 then raise exception 'AMOUNT_EXCEEDS_BALANCE'; end if;

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  values (v_cashbox_id, 'purchase', -p_amount, 'supplier', p_supplier_id,
          coalesce(nullif(btrim(p_notes), ''), 'سداد لمورد'), auth.uid());
end;
$$;
revoke all on function private.fn_pay_supplier(uuid, numeric, text, uuid, text, uuid) from public, anon, authenticated;

-- p_items: [{product_id, quantity, unit_cost}]. Supplier by id, or by name
-- (found case-insensitively, created if new). p_paid_amount: 0 = آجل,
-- total = نقدي, anything between = partly paid; out of the p_payment_kind
-- till. Each line updates the product's cost price, like rpc_receive_purchase.
create or replace function public.rpc_create_purchase_invoice(
  p_supplier_id uuid, p_supplier_name text, p_supplier_phone text,
  p_items jsonb, p_discount numeric, p_paid_amount numeric, p_payment_kind text,
  p_invoice_date date, p_supplier_invoice_ref text, p_notes text, p_client_request_id uuid
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_existing uuid;
  v_supplier_id uuid := p_supplier_id;
  v_invoice_id uuid;
  v_warehouse_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_product record;
  v_qty int;
  v_cost numeric(12,2);
  v_subtotal numeric(12,2) := 0;
  v_discount numeric(12,2) := coalesce(p_discount, 0);
  v_paid numeric(12,2) := coalesce(p_paid_amount, 0);
  v_total numeric(12,2);
  v_number bigint;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_ORDER';
  end if;
  if jsonb_array_length(p_items) > 200 then raise exception 'TOO_MANY_ITEMS'; end if;
  if v_discount < 0 or v_discount <> round(v_discount, 2) then raise exception 'INVALID_DISCOUNT'; end if;
  if v_paid < 0 or v_paid <> round(v_paid, 2) then raise exception 'INVALID_AMOUNT'; end if;
  if length(coalesce(p_notes, '')) > 1000 or length(coalesce(p_supplier_name, '')) > 200
     or length(coalesce(p_supplier_invoice_ref, '')) > 100 then
    raise exception 'INPUT_TOO_LONG';
  end if;

  if p_client_request_id is not null then
    select id into v_existing from public.purchase_invoices where client_request_id = p_client_request_id;
    if v_existing is not null then return v_existing; end if;
  end if;

  if v_supplier_id is null then
    if p_supplier_name is null or btrim(p_supplier_name) = '' then raise exception 'SUPPLIER_REQUIRED'; end if;
    select id into v_supplier_id from public.suppliers where lower(btrim(name)) = lower(btrim(p_supplier_name));
    if v_supplier_id is null then
      insert into public.suppliers (name, phone) values (btrim(p_supplier_name), nullif(btrim(p_supplier_phone), ''))
      returning id into v_supplier_id;
    end if;
  elsif not exists (select 1 from public.suppliers where id = v_supplier_id) then
    raise exception 'SUPPLIER_NOT_FOUND';
  end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  insert into public.purchase_invoices (supplier_id, supplier_invoice_ref, invoice_date, notes, client_request_id, created_by)
  values (v_supplier_id, nullif(btrim(p_supplier_invoice_ref), ''), coalesce(p_invoice_date, current_date),
          nullif(btrim(p_notes), ''), p_client_request_id, auth.uid())
  returning id, invoice_number into v_invoice_id, v_number;

  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) <> 'object' then raise exception 'INVALID_ITEM'; end if;
    begin
      v_product_id := (v_item ->> 'product_id')::uuid;
      v_qty := (v_item ->> 'quantity')::int;
      v_cost := (v_item ->> 'unit_cost')::numeric;
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'INVALID_ITEM';
    end;
    if v_product_id is null then raise exception 'INVALID_ITEM'; end if;
    if v_qty is null or v_qty <= 0 or v_qty > 100000 then raise exception 'INVALID_QUANTITY'; end if;
    if v_cost is null or v_cost < 0 or v_cost <> round(v_cost, 2) then raise exception 'INVALID_AMOUNT'; end if;

    select id, name, is_service, is_assembly into v_product from public.products where id = v_product_id for update;
    if not found then raise exception 'PRODUCT_NOT_FOUND: %', v_product_id; end if;
    if v_product.is_service or v_product.is_assembly then raise exception 'NOT_A_STOCK_PRODUCT: %', v_product.name; end if;

    insert into public.purchase_invoice_items (invoice_id, product_id, product_name_snapshot, quantity, unit_cost)
    values (v_invoice_id, v_product.id, v_product.name, v_qty, v_cost);

    insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, to_location_type, to_location_id, unit_cost, reference_type, reference_id, notes, created_by)
    values (v_product.id, 'purchase', v_qty, 'external', 'warehouse', v_warehouse_id, v_cost, 'purchase_invoice', v_invoice_id,
            'فاتورة شراء #' || v_number, auth.uid());

    update public.products set cost_price = v_cost where id = v_product.id;
    v_subtotal := v_subtotal + v_qty * v_cost;
  end loop;

  if v_discount > v_subtotal then raise exception 'INVALID_DISCOUNT'; end if;
  v_total := v_subtotal - v_discount;
  if v_paid > v_total then raise exception 'PAID_EXCEEDS_TOTAL'; end if;

  update public.purchase_invoices set subtotal = v_subtotal, discount = v_discount where id = v_invoice_id;

  if v_paid > 0 then
    perform private.fn_pay_supplier(v_supplier_id, v_paid, p_payment_kind, v_invoice_id,
      'دفعة فاتورة شراء #' || v_number, p_client_request_id);
  end if;

  insert into public.audit_logs (actor_id, action, table_name, record_id, new_data)
  values (auth.uid(), 'PURCHASE_INVOICE_CREATED', 'purchase_invoices', v_invoice_id,
          (select to_jsonb(p) from public.purchase_invoices p where p.id = v_invoice_id));

  return v_invoice_id;
end;
$$;

-- A later payment to a supplier (settling آجل). Idempotent on
-- p_client_request_id so an offline-queued payment cannot be paid twice.
create or replace function public.rpc_pay_supplier(
  p_supplier_id uuid, p_amount numeric, p_kind text, p_invoice_id uuid,
  p_notes text, p_client_request_id uuid
) returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if length(coalesce(p_notes, '')) > 500 then raise exception 'INPUT_TOO_LONG'; end if;
  if not exists (select 1 from public.suppliers where id = p_supplier_id) then raise exception 'SUPPLIER_NOT_FOUND'; end if;
  if p_client_request_id is not null
     and exists (select 1 from public.supplier_payments where client_request_id = p_client_request_id) then
    return;
  end if;
  perform private.fn_pay_supplier(p_supplier_id, p_amount, p_kind, p_invoice_id, p_notes, p_client_request_id);
end;
$$;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_admin_set_assembly', 'admin'),
  ('rpc_admin_edit_sale', 'admin/sales'),
  ('rpc_admin_delete_sale', 'admin/sales'),
  ('rpc_create_purchase_invoice', 'admin'),
  ('rpc_pay_supplier', 'admin'),
  -- 0074 granted this directly instead of allowlisting it, so the
  -- apply_function_grants() below would otherwise revoke it again.
  ('rpc_effective_prices', 'admin/sales (register prices)')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
