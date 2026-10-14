-- ============================================================================
-- 0084_walk_in_credit_and_bag.sql
--
-- The walk-in register (admin and sales) can now:
--
--   1. Sell on credit (آجل) or take part of the money now (جزئي). Whatever
--      is not paid becomes the customer's debt ('order_charge' on their
--      account, tagged with the sale), so it shows under "ديون العملاء" and
--      is collected from the customer's page like any other debt. Credit
--      needs a registered customer (p_customer_id) — the register can add
--      one on the spot through the create-user Edge Function.
--
--   2. Sell from a technician's bag (p_technician_id) instead of the main
--      warehouse. The stock leaves the bag; the money goes into the shop's
--      till like any walk-in sale (the technician owes nothing for it), and
--      sales.technician_id stays null — it is the shop's sale, editable and
--      returnable like the others. sales.source_bag_id records the bag.
--
-- Re-pricing a line (0082) works the same from either source.
--
-- Returns and invoice edits follow the money: refunding a credit sale
-- first cancels what the customer still owes ('return_credit'), and only
-- the rest comes out of a till. Returned goods go to the main warehouse —
-- they are back at the shop, wherever they were sold from.
-- ============================================================================

alter table public.sales
  add column if not exists source_bag_id uuid references public.technician_bags(id);

alter table public.customer_account_transactions
  add column if not exists sale_id uuid references public.sales(id);
create index if not exists idx_cust_txn_sale on public.customer_account_transactions (sale_id)
  where sale_id is not null;

-- ----------------------------------------------------------------------------
-- Stock out of a technician's bag for a register sale. Assembly products are
-- built in the shop from warehouse parts and never sit in a bag.
-- ----------------------------------------------------------------------------
create or replace function private.fn_sale_stock_out_bag(
  p_product_id uuid, p_qty int, p_sale_id uuid, p_bag_id uuid, p_notes text
) returns numeric language plpgsql security definer set search_path = public as $$
declare
  v_product record;
begin
  select id, name, cost_price, is_service, is_assembly into v_product
    from public.products where id = p_product_id;
  if not found then raise exception 'PRODUCT_NOT_FOUND: %', p_product_id; end if;
  if v_product.is_service then return 0; end if;
  if v_product.is_assembly then raise exception 'ASSEMBLY_NOT_IN_BAG: %', v_product.name; end if;

  insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
  values (v_product.id, 'sale', p_qty, 'technician_bag', p_bag_id, 'external', v_product.cost_price, 'sale', p_sale_id, p_notes, auth.uid());
  return v_product.cost_price;
end;
$$;

-- What [p_customer_id] owes right now (never negative).
create or replace function private.fn_customer_debt(p_customer_id uuid)
returns numeric language sql stable security definer set search_path = public as $$
  select greatest(coalesce(sum(amount), 0), 0)::numeric(14,2)
  from public.customer_account_transactions where customer_id = p_customer_id;
$$;

-- ----------------------------------------------------------------------------
-- The register sale. Same body as 0082's, plus customer / paid amount /
-- source bag. Dropped first: a second overload would make PostgREST's
-- named-argument call ambiguous.
-- ----------------------------------------------------------------------------
drop function if exists public.rpc_admin_walk_in_sale(text, text, jsonb, payment_method, numeric, uuid, text);

create or replace function public.rpc_admin_walk_in_sale(
  p_customer_name text,
  p_customer_phone text,
  p_items jsonb,
  p_payment_method payment_method,
  p_discount numeric,
  p_client_request_id uuid,
  p_notes text,
  p_customer_id uuid default null,
  p_paid_amount numeric default null,
  p_technician_id uuid default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_sale_id uuid;
  v_sale_number bigint;
  v_existing uuid;
  v_warehouse_id uuid;
  v_bag_id uuid;
  v_cashbox_id uuid;
  v_customer_name text;
  v_customer_phone text;
  v_item jsonb;
  v_product_id uuid;
  v_product record;
  v_qty int;
  v_unit_price numeric(12,2);
  v_unit_cost numeric(12,2);
  v_line_discount numeric(12,2);
  v_discount numeric(12,2) := coalesce(p_discount, 0);
  v_subtotal numeric(12,2) := 0;
  v_total numeric(12,2);
  v_paid numeric(12,2);
  v_kind text;
  v_out jsonb;
  v_components jsonb;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_payment_method is null then raise exception 'INVALID_INPUT'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_ORDER';
  end if;
  if jsonb_array_length(p_items) > 100 then raise exception 'TOO_MANY_ITEMS'; end if;
  if v_discount < 0 or v_discount <> round(v_discount, 2) then raise exception 'INVALID_DISCOUNT'; end if;
  if p_paid_amount is not null and (p_paid_amount < 0 or p_paid_amount <> round(p_paid_amount, 2)) then
    raise exception 'INVALID_AMOUNT';
  end if;
  if p_payment_method = 'deferred' and coalesce(p_paid_amount, 0) > 0 then
    raise exception 'INVALID_AMOUNT';
  end if;

  if p_client_request_id is not null then
    select id into v_existing from public.sales where client_request_id = p_client_request_id;
    if v_existing is not null then return v_existing; end if;
  end if;

  if p_customer_id is not null then
    select u.full_name, u.phone into v_customer_name, v_customer_phone
      from public.customers c join public.users u on u.id = c.id where c.id = p_customer_id;
    if not found then raise exception 'CUSTOMER_NOT_FOUND'; end if;
  end if;

  if p_technician_id is not null then
    select id into v_bag_id from public.technician_bags where technician_id = p_technician_id;
    if v_bag_id is null then raise exception 'TECHNICIAN_BAG_NOT_FOUND'; end if;
  else
    select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
    if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;
  end if;

  insert into public.sales (technician_id, customer_id, customer_name, customer_phone, payment_method,
                            discount, client_request_id, source_bag_id)
  values (null, p_customer_id,
          coalesce(nullif(btrim(p_customer_name), ''), v_customer_name),
          coalesce(nullif(btrim(p_customer_phone), ''), v_customer_phone),
          p_payment_method, v_discount, p_client_request_id, v_bag_id)
  returning id, sale_number into v_sale_id, v_sale_number;

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
    elsif v_unit_price is null then
      v_unit_price := private.fn_effective_price(v_product.id);
    elsif v_unit_price <= 0 or v_unit_price <> round(v_unit_price, 2) then
      raise exception 'INVALID_AMOUNT';
    end if;

    if v_line_discount < 0 or v_line_discount > v_qty * v_unit_price then
      raise exception 'INVALID_DISCOUNT';
    end if;

    v_subtotal := v_subtotal + v_qty * v_unit_price - v_line_discount;

    if v_bag_id is not null then
      v_unit_cost := private.fn_sale_stock_out_bag(v_product.id, v_qty, v_sale_id, v_bag_id, p_notes);
      v_components := null;
    else
      v_out := private.fn_sale_stock_out(v_product.id, v_qty, v_sale_id, v_warehouse_id, p_notes);
      v_unit_cost := (v_out ->> 'unit_cost')::numeric;
      v_components := case when jsonb_typeof(v_out -> 'components') = 'array' then v_out -> 'components' end;
    end if;

    insert into public.sale_items (sale_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount, components)
    values (v_sale_id, v_product.id, v_product.name, v_qty, v_unit_price, v_unit_cost, v_line_discount, v_components);
  end loop;

  if v_discount > v_subtotal then raise exception 'INVALID_DISCOUNT'; end if;
  v_total := v_subtotal - v_discount;

  v_paid := case when p_payment_method = 'deferred' then 0 else coalesce(p_paid_amount, v_total) end;
  if v_paid > v_total then raise exception 'PAYMENT_EXCEEDS_TOTAL'; end if;
  -- Money left owing must land on a customer's account, or it is lost.
  if v_paid < v_total and p_customer_id is null then raise exception 'DEFERRED_REQUIRES_CUSTOMER'; end if;

  update public.sales set subtotal = v_subtotal, paid_amount = v_paid where id = v_sale_id;

  if v_paid > 0 then
    v_kind := private.fn_till_kind(p_payment_method);
    select id into v_cashbox_id from public.cashboxes where kind = v_kind and is_active limit 1;
    if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;
    insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
    values (v_cashbox_id, 'sale', v_paid, 'sale', v_sale_id, coalesce(p_notes, 'بيع مباشر من المعرض'), auth.uid());
  end if;

  if v_paid < v_total then
    insert into public.customer_account_transactions (customer_id, transaction_type, amount, sale_id, notes, created_by)
    values (p_customer_id, 'order_charge', v_total - v_paid, v_sale_id,
            'بيع آجل · فاتورة #' || v_sale_number, auth.uid());
  end if;

  return v_sale_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- Return part of a register sale. 0075's body; the refund now cancels what
-- the sale's customer still owes before any cash leaves a till.
-- ----------------------------------------------------------------------------
create or replace function private.fn_return_sale_item(
  p_sale_item_id uuid, p_quantity integer, p_reason text,
  p_refund_kind text default null, p_skip_cash boolean default false
) returns void language plpgsql security definer set search_path = public as $$
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
  v_credit numeric(12,2) := 0;
  v_cash numeric(12,2) := 0;
  v_remaining_on_sale int;
  v_kind text;
  v_comp jsonb;
begin
  if p_refund_kind is not null and p_refund_kind not in ('main', 'cash', 'transfer', 'wallet') then
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
    -- What the customer still owes is cancelled first; only the rest is
    -- handed back.
    if v_sale.customer_id is not null then
      v_credit := least(v_refund, private.fn_customer_debt(v_sale.customer_id));
      if v_credit > 0 then
        insert into public.customer_account_transactions (customer_id, transaction_type, amount, sale_id, notes, created_by)
        values (v_sale.customer_id, 'return_credit', -v_credit, v_sale.id,
                btrim(p_reason) || ' · فاتورة #' || v_sale.sale_number, auth.uid());
      end if;
    end if;
    v_cash := v_refund - v_credit;

    if v_cash > 0 then
      v_kind := coalesce(p_refund_kind, private.fn_till_kind(v_sale.payment_method));
      select id into v_cashbox_id from public.cashboxes where kind = v_kind and is_active limit 1 for update;
      if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

      select coalesce(sum(amount), 0) into v_balance
        from public.cash_transactions where cashbox_id = v_cashbox_id;
      if v_cash > v_balance then raise exception 'INSUFFICIENT_CASH: %', v_balance; end if;

      insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
      values (v_cashbox_id, 'refund', -v_cash, 'sale', v_sale.id, btrim(p_reason), auth.uid());
    end if;
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
    paid_amount = case when p_skip_cash then paid_amount else greatest(paid_amount - v_cash, 0) end
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

-- ----------------------------------------------------------------------------
-- Edit a register invoice. 0075's body, with two changes:
--   * more of a product on a bag sale comes out of the same bag;
--   * on a sale with a customer, the invoice's value is what the till holds
--     for it plus what was put on the customer's account for it. A higher
--     total is added to their debt; a lower one cancels debt first, then
--     refunds cash.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_admin_edit_sale(
  p_sale_id uuid, p_items jsonb, p_discount numeric, p_reason text, p_money_kind text default null
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
  v_unit_cost numeric(12,2);
  v_components jsonb;
  v_key text;
  v_discount numeric(12,2);
  v_target numeric(12,2);
  v_held numeric(12,2);
  v_on_account numeric(12,2) := 0;
  v_delta numeric(12,2);
  v_credit numeric(12,2);
  v_kind text;
  v_cashbox_id uuid;
  v_balance numeric(14,2);
  v_remaining int;
  v_reason text := coalesce(nullif(btrim(p_reason), ''), 'تعديل فاتورة');
  v_note text;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if length(v_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;
  if p_money_kind is not null and p_money_kind not in ('main', 'cash', 'transfer', 'wallet') then
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

      if v_sale.source_bag_id is not null then
        v_unit_cost := private.fn_sale_stock_out_bag(v_product.id, v_qty, p_sale_id, v_sale.source_bag_id, v_note);
        v_components := null;
      else
        if v_warehouse_id is null then
          select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
          if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;
        end if;
        v_out := private.fn_sale_stock_out(v_product.id, v_qty, p_sale_id, v_warehouse_id, v_note);
        v_unit_cost := (v_out ->> 'unit_cost')::numeric;
        v_components := case when jsonb_typeof(v_out -> 'components') = 'array' then v_out -> 'components' end;
      end if;

      insert into public.sale_items (sale_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount, components)
      values (p_sale_id, v_product.id, v_product.name, v_qty, v_price, v_unit_cost, 0, v_components);

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

  -- Money: settle the difference between the new total and what the sale
  -- has brought in so far — the till, plus the customer's account for it.
  select coalesce(sum(amount), 0) into v_held
    from public.cash_transactions where reference_type = 'sale' and reference_id = p_sale_id;
  if v_sale.customer_id is not null then
    select coalesce(sum(amount), 0) into v_on_account
      from public.customer_account_transactions where sale_id = p_sale_id;
  end if;
  v_delta := v_target - v_held - v_on_account;

  if v_delta > 0 and v_sale.customer_id is not null and v_on_account > 0 then
    -- A credit sale grew: the customer owes the difference.
    insert into public.customer_account_transactions (customer_id, transaction_type, amount, sale_id, notes, created_by)
    values (v_sale.customer_id, 'order_charge', v_delta, p_sale_id, v_note, auth.uid());
    v_delta := 0;
  elsif v_delta < 0 and v_sale.customer_id is not null then
    -- It shrank: cancel what they still owe first.
    v_credit := least(-v_delta, private.fn_customer_debt(v_sale.customer_id));
    if v_credit > 0 then
      insert into public.customer_account_transactions (customer_id, transaction_type, amount, sale_id, notes, created_by)
      values (v_sale.customer_id, 'return_credit', -v_credit, p_sale_id, v_note, auth.uid());
      v_delta := v_delta + v_credit;
    end if;
  end if;

  if v_delta <> 0 then
    v_kind := coalesce(p_money_kind, private.fn_till_kind(v_sale.payment_method));
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

  select coalesce(sum(amount), 0) into v_held
    from public.cash_transactions where reference_type = 'sale' and reference_id = p_sale_id;
  update public.sales set discount = v_discount, paid_amount = greatest(v_held, 0) where id = p_sale_id;

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'SALE_EDITED', 'sales', p_sale_id, v_before,
          (select to_jsonb(s) from public.sales s where s.id = p_sale_id));
end;
$$;

select private.apply_function_grants();
notify pgrst, 'reload schema';
