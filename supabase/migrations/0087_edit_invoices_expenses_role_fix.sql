-- ============================================================================
-- 0087_edit_invoices_expenses_role_fix.sql
--
-- 1. A technician whose role was changed (e.g. to sales) stayed an "active
--    technician": still counted on the dashboard and still offered a bag to
--    stock. The technicians row now follows the role — active only while
--    the user IS a technician — and existing rows are put right once. The
--    row, bag and account are kept (their history is real), only the flag
--    changes, and it turns back on if the role is changed back.
--
-- 2. Re-pricing a line of an invoice. sale_items is append-only, so a new
--    price is: the old line marked returned (sale_item_returns, no stock
--    moves — the goods never left the customer) and a new line for the same
--    quantity at the new price, carrying the old line's cost and components.
--    rpc_admin_edit_sale (register invoices) takes it as {"reprice": true}
--    on an item; without that flag an item's unit_price means what it always
--    did, so an older app (or an edit still queued offline) is unaffected.
--
-- 3. Technician invoices can be edited and deleted — by the technician who
--    made them, or by admin:
--      rpc_edit_technician_sale    quantities, prices, items, discount
--      rpc_delete_technician_sale  everything back to the bag, cancelled
--    Stock moves between the sale and the technician's bag. Money follows
--    the technician's account: a higher paid total is a sale_credit, a lower
--    one an 'adjustment' with a negative amount (allowed from now on, for
--    that type only). A deferred sale moves the customer's account instead.
--    Technicians can now read the returns of their own sales, and
--    sale_items_display gains returned_quantity so an edited invoice shows
--    what is on it now.
--
-- 4. Expenses can be edited (amount, category, date, notes) by admin and
--    sales: rpc_edit_expense. The difference goes through the till the
--    expense was paid from. A salary's expense is refused (it belongs to its
--    payroll). expenses stays locked against any other UPDATE/DELETE.
--
-- Nothing here deletes or rewrites a ledger row.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Role change and the technicians row
-- ----------------------------------------------------------------------------
create or replace function public.sync_user_role_on_metadata_update()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_role user_role;
  v_employee_code text;
begin
  if new.raw_app_meta_data is not distinct from old.raw_app_meta_data then
    return new; -- routine auth.users update (e.g. last_sign_in_at) — nothing to do
  end if;

  v_role := coalesce((new.raw_app_meta_data ->> 'role')::user_role, 'customer');

  update public.users set role = v_role where id = new.id and role is distinct from v_role;

  if v_role = 'technician' then
    if not exists (select 1 from public.technicians where id = new.id) then
      v_employee_code := coalesce(new.raw_user_meta_data ->> 'employee_code', 'T-' || substr(new.id::text, 1, 8));
      insert into public.technicians (id, employee_code, created_by)
        values (new.id, v_employee_code, (new.raw_user_meta_data ->> 'created_by')::uuid)
        on conflict (id) do nothing;
      insert into public.technician_bags (technician_id) values (new.id) on conflict (technician_id) do nothing;
      insert into public.technician_accounts (id) values (new.id) on conflict (id) do nothing;
    end if;
    delete from public.customers c
    where c.id = new.id
      and not exists (select 1 from public.customer_account_transactions where customer_id = c.id)
      and not exists (select 1 from public.orders where customer_id = c.id)
      and not exists (select 1 from public.maintenance_requests where customer_id = c.id)
      and not exists (select 1 from public.sales where customer_id = c.id);
  elsif v_role = 'customer' then
    if not exists (select 1 from public.customers where id = new.id) then
      insert into public.customers (id) values (new.id) on conflict (id) do nothing;
      insert into public.customer_accounts (id) values (new.id) on conflict (id) do nothing;
    end if;
  elsif v_role = 'admin' then
    delete from public.customers c
    where c.id = new.id
      and not exists (select 1 from public.customer_account_transactions where customer_id = c.id)
      and not exists (select 1 from public.orders where customer_id = c.id)
      and not exists (select 1 from public.maintenance_requests where customer_id = c.id)
      and not exists (select 1 from public.sales where customer_id = c.id);
  end if;

  -- 0087: only a technician is an active technician. Only when the role
  -- itself changed, so other app-metadata updates leave the flag alone.
  if (old.raw_app_meta_data ->> 'role') is distinct from (new.raw_app_meta_data ->> 'role') then
    update public.technicians set is_active = (v_role = 'technician')
      where id = new.id and is_active is distinct from (v_role = 'technician');
  end if;

  return new;
end;
$$;

-- Accounts already moved off the technician role.
update public.technicians t set is_active = false
from public.users u
where u.id = t.id and u.role <> 'technician' and t.is_active;

-- ----------------------------------------------------------------------------
-- 3a. A technician's dues can go down: a negative 'adjustment'.
-- ----------------------------------------------------------------------------
alter table public.technician_account_transactions
  drop constraint if exists technician_account_transactions_amount_check;
alter table public.technician_account_transactions
  add constraint technician_account_transactions_amount_check
  check (amount > 0 or (transaction_type = 'adjustment' and amount <> 0));

-- 3b. Technicians read the returns of their own sales.
alter policy sale_item_returns_select on public.sale_item_returns
  using (
    public.is_admin() or public.is_sales()
    or sale_item_id in (
      select si.id from public.sale_items si
      join public.sales s on s.id = si.sale_id
      where s.technician_id = auth.uid()
    )
  );

-- 3c. What is still on each line. Same rows and row rules as 0029's view;
-- the new column is appended.
create or replace view public.sale_items_display as
select si.id, si.sale_id, si.product_id, si.product_name_snapshot, si.quantity,
  si.unit_price_snapshot, si.discount, si.line_total,
  coalesce((select sum(r.quantity) from public.sale_item_returns r where r.sale_item_id = si.id), 0)::int
    as returned_quantity
from public.sale_items si
where public.is_admin() or exists (
  select 1 from public.sales s
  where s.id = si.sale_id and (
    s.technician_id = auth.uid() or s.customer_id = auth.uid()
    or s.maintenance_request_id in (select mr.id from public.maintenance_requests mr where mr.customer_id = auth.uid())
  )
);
revoke all on public.sale_items_display from public, anon;
grant select on public.sale_items_display to authenticated;

-- ----------------------------------------------------------------------------
-- 2. Re-price p_quantity of a sale line: the old line is marked returned
-- for that quantity (its value leaves the invoice exactly as a return's
-- does, see fn_return_sale_item) and a new line takes it at p_price, with
-- the old line's cost and components. No stock and no money moves here —
-- the caller settles the money once for the whole edit.
-- ----------------------------------------------------------------------------
create or replace function private.fn_reprice_sale_item(
  p_sale_item_id uuid, p_quantity int, p_price numeric, p_note text
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_item record;
  v_sale record;
  v_left int;
  v_gross numeric(12,2);
  v_pre_sale_discount numeric(12,2);
  v_sale_discount_share numeric(12,2);
  v_refund numeric(12,2);
begin
  if p_price is null or p_price <= 0 or p_price <> round(p_price, 2) then raise exception 'INVALID_AMOUNT'; end if;

  -- sale_items itself: sale_items_with_returns predates 0075's components.
  select * into v_item from public.sale_items where id = p_sale_item_id;
  if not found then raise exception 'SALE_ITEM_NOT_FOUND'; end if;
  select * into v_sale from public.sales where id = v_item.sale_id for update;
  if v_sale.status <> 'completed' then raise exception 'SALE_NOT_EDITABLE'; end if;

  select v_item.quantity - coalesce(sum(quantity), 0) into v_left
    from public.sale_item_returns where sale_item_id = p_sale_item_id;
  if p_quantity is null or p_quantity <= 0 or p_quantity > v_left then raise exception 'INVALID_QUANTITY'; end if;

  v_gross := v_item.unit_price_snapshot * p_quantity;
  v_pre_sale_discount := v_gross - v_item.discount * p_quantity / v_item.quantity;
  v_sale_discount_share := case when v_sale.subtotal > 0
    then v_sale.discount * v_pre_sale_discount / v_sale.subtotal else 0 end;
  v_refund := greatest(round(v_pre_sale_discount - v_sale_discount_share, 2), 0);

  insert into public.sale_item_returns (sale_item_id, quantity, refund_amount, reason, created_by)
  values (p_sale_item_id, p_quantity, v_refund, btrim(p_note), auth.uid());

  update public.sales set
    subtotal = greatest(subtotal - v_pre_sale_discount, 0),
    discount = least(greatest(discount - (v_pre_sale_discount - v_refund), 0),
                     greatest(subtotal - v_pre_sale_discount, 0))
  where id = v_sale.id;

  insert into public.sale_items (sale_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount, components)
  values (v_item.sale_id, v_item.product_id, v_item.product_name_snapshot, p_quantity, p_price,
          v_item.unit_cost_snapshot, 0, v_item.components);

  update public.sales set subtotal = subtotal + p_quantity * p_price where id = v_sale.id;
end;
$$;
revoke all on function private.fn_reprice_sale_item(uuid, int, numeric, text) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- 2. rpc_admin_edit_sale — 0084's body, plus re-pricing: an item with
-- "reprice": true sets every unit of its product still on the invoice to
-- its unit_price, and units added for it are charged that price too.
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
  v_reprice boolean;
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

  -- Desired quantity (and optional price) per product.
  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) <> 'object' then raise exception 'INVALID_ITEM'; end if;
    begin
      v_product_id := (v_item ->> 'product_id')::uuid;
      v_qty := (v_item ->> 'quantity')::int;
      v_price := (v_item ->> 'unit_price')::numeric;
      v_reprice := coalesce((v_item ->> 'reprice')::boolean, false);
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'INVALID_ITEM';
    end;
    if v_product_id is null then raise exception 'INVALID_ITEM'; end if;
    if v_qty is null or v_qty < 0 or v_qty > 999 then raise exception 'INVALID_QUANTITY'; end if;
    if v_reprice and (v_price is null or v_price <= 0 or v_price <> round(v_price, 2)) then
      raise exception 'INVALID_AMOUNT';
    end if;
    v_desired := jsonb_set(v_desired, array[v_product_id::text], jsonb_build_object(
      'quantity', coalesce((v_desired -> v_product_id::text ->> 'quantity')::int, 0) + v_qty,
      'unit_price', coalesce(v_price, (v_desired -> v_product_id::text ->> 'unit_price')::numeric),
      'reprice', v_reprice or coalesce((v_desired -> v_product_id::text ->> 'reprice')::boolean, false)));
  end loop;

  -- Less of a product (or none): return the difference, cheapest lines first.
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

  -- A new price: every unit still on the invoice at another price is
  -- re-priced (0087).
  for v_key in select jsonb_object_keys(v_desired) loop
    if (v_desired -> v_key ->> 'reprice')::boolean then
      v_price := (v_desired -> v_key ->> 'unit_price')::numeric;
      for v_li in
        select id, quantity - returned_quantity as left_qty
        from public.sale_items_with_returns
        where sale_id = p_sale_id and product_id = v_key::uuid and returned_quantity < quantity
          and unit_price_snapshot <> v_price
        order by id
      loop
        perform private.fn_reprice_sale_item(v_li.id, v_li.left_qty, v_price, 'تعديل سعر · ' || v_note);
      end loop;
    end if;
  end loop;

  -- More of a product (or a new one): a new line at the given price when
  -- re-priced, else the invoice's existing price for it, else today's
  -- effective price (a service: the given price).
  for v_key in select jsonb_object_keys(v_desired) loop
    v_want := (v_desired -> v_key ->> 'quantity')::int;
    select coalesce(sum(quantity - returned_quantity), 0)::int into v_have
      from public.sale_items_with_returns where sale_id = p_sale_id and product_id = v_key::uuid;
    if v_want > v_have then
      v_qty := v_want - v_have;
      select id, name, is_service into v_product from public.products where id = v_key::uuid for update;
      if not found then raise exception 'PRODUCT_NOT_FOUND: %', v_key; end if;

      if (v_desired -> v_key ->> 'reprice')::boolean then
        v_price := (v_desired -> v_key ->> 'unit_price')::numeric;
      elsif v_product.is_service then
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

-- ----------------------------------------------------------------------------
-- 3. Technician invoices
-- ----------------------------------------------------------------------------

-- Takes p_quantity of a technician sale's line back into the technician's
-- bag (a service: nothing to put back) and its value off the invoice, the
-- same arithmetic as fn_return_sale_item. Money is settled by the caller.
create or replace function private.fn_tech_return_sale_item(
  p_sale_item_id uuid, p_quantity int, p_bag_id uuid, p_note text
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_item record;
  v_sale record;
  v_is_service boolean;
  v_pre_sale_discount numeric(12,2);
  v_sale_discount_share numeric(12,2);
  v_refund numeric(12,2);
begin
  select * into v_item from public.sale_items_with_returns where id = p_sale_item_id;
  if not found then raise exception 'SALE_ITEM_NOT_FOUND'; end if;
  select * into v_sale from public.sales where id = v_item.sale_id for update;
  if p_quantity is null or p_quantity <= 0 or p_quantity > v_item.quantity - v_item.returned_quantity then
    raise exception 'RETURN_QUANTITY_EXCEEDS_REMAINING';
  end if;

  select is_service into v_is_service from public.products where id = v_item.product_id;
  if not coalesce(v_is_service, false) then
    insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, to_location_type,
      to_location_id, unit_cost, reference_type, reference_id, notes, created_by)
    values (v_item.product_id, 'return_from_customer', p_quantity, 'external', 'technician_bag',
      p_bag_id, v_item.unit_cost_snapshot, 'sale', v_sale.id, btrim(p_note), auth.uid());
  end if;

  v_pre_sale_discount := v_item.unit_price_snapshot * p_quantity - v_item.discount * p_quantity / v_item.quantity;
  v_sale_discount_share := case when v_sale.subtotal > 0
    then v_sale.discount * v_pre_sale_discount / v_sale.subtotal else 0 end;
  v_refund := greatest(round(v_pre_sale_discount - v_sale_discount_share, 2), 0);

  insert into public.sale_item_returns (sale_item_id, quantity, refund_amount, reason, created_by)
  values (p_sale_item_id, p_quantity, v_refund, btrim(p_note), auth.uid());

  update public.sales set
    subtotal = greatest(subtotal - v_pre_sale_discount, 0),
    discount = least(greatest(discount - (v_pre_sale_discount - v_refund), 0),
                     greatest(subtotal - v_pre_sale_discount, 0))
  where id = v_sale.id;
end;
$$;
revoke all on function private.fn_tech_return_sale_item(uuid, int, uuid, text) from public, anon, authenticated;

-- Moves the money of a technician sale from [p_old_total, p_old_paid] to
-- its current total: the technician's account for a paid sale (a sale paid
-- in full stays paid in full; a part-paid one keeps what was paid, capped
-- at the new total), the customer's account for a deferred one.
create or replace function private.fn_tech_sale_settle(
  p_sale_id uuid, p_old_total numeric, p_old_paid numeric, p_note text
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_sale record;
  v_new_paid numeric(12,2);
  v_delta numeric(12,2);
begin
  select * into v_sale from public.sales where id = p_sale_id for update;

  if v_sale.payment_method = 'deferred' then
    v_delta := v_sale.total - p_old_total;
    if v_delta <> 0 and v_sale.customer_id is not null then
      insert into public.customer_account_transactions (customer_id, transaction_type, amount, sale_id, notes, created_by)
      values (v_sale.customer_id, case when v_delta > 0 then 'order_charge' else 'return_credit' end::cust_txn_type,
              v_delta, p_sale_id, p_note, auth.uid());
    end if;
    return;
  end if;

  v_new_paid := case when p_old_paid >= p_old_total then v_sale.total
                     else least(p_old_paid, v_sale.total) end;
  v_delta := v_new_paid - p_old_paid;
  if v_delta > 0 then
    insert into public.technician_account_transactions (technician_id, transaction_type, amount, sale_id, notes, created_by)
    values (v_sale.technician_id, 'sale_credit', v_delta, p_sale_id, p_note, auth.uid());
  elsif v_delta < 0 then
    insert into public.technician_account_transactions (technician_id, transaction_type, amount, sale_id, notes, created_by)
    values (v_sale.technician_id, 'adjustment', v_delta, p_sale_id, p_note, auth.uid());
  end if;
  update public.sales set paid_amount = v_new_paid where id = p_sale_id;
end;
$$;
revoke all on function private.fn_tech_sale_settle(uuid, numeric, numeric, text) from public, anon, authenticated;

-- p_items is the invoice's FINAL content: [{product_id, quantity,
-- unit_price?, reprice?}] — as rpc_admin_edit_sale. Stock comes from and
-- goes back to the technician's own bag.
create or replace function public.rpc_edit_technician_sale(
  p_sale_id uuid, p_items jsonb, p_discount numeric, p_reason text
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_sale record;
  v_before jsonb;
  v_bag_id uuid;
  v_desired jsonb := '{}'::jsonb;
  v_item jsonb;
  v_product_id uuid;
  v_qty int;
  v_price numeric(12,2);
  v_reprice boolean;
  v_line record;
  v_li record;
  v_product record;
  v_key text;
  v_want int;
  v_have int;
  v_to_return int;
  v_take int;
  v_discount numeric(12,2);
  v_remaining int;
  v_reason text := coalesce(nullif(btrim(p_reason), ''), 'تعديل فاتورة');
  v_note text;
begin
  if length(v_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' then raise exception 'INVALID_ITEM'; end if;
  if jsonb_array_length(p_items) > 100 then raise exception 'TOO_MANY_ITEMS'; end if;

  select * into v_sale from public.sales where id = p_sale_id for update;
  if not found then raise exception 'SALE_NOT_FOUND'; end if;
  if not (public.is_admin() or (public.is_technician() and v_sale.technician_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;
  if v_sale.technician_id is null then raise exception 'NOT_A_TECHNICIAN_SALE'; end if;
  if v_sale.status <> 'completed' then raise exception 'SALE_NOT_EDITABLE'; end if;
  v_before := to_jsonb(v_sale);
  v_note := v_reason || ' · فاتورة #' || v_sale.sale_number;

  select id into v_bag_id from public.technician_bags where technician_id = v_sale.technician_id;
  if v_bag_id is null then raise exception 'TECHNICIAN_BAG_NOT_FOUND'; end if;

  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) <> 'object' then raise exception 'INVALID_ITEM'; end if;
    begin
      v_product_id := (v_item ->> 'product_id')::uuid;
      v_qty := (v_item ->> 'quantity')::int;
      v_price := (v_item ->> 'unit_price')::numeric;
      v_reprice := coalesce((v_item ->> 'reprice')::boolean, false);
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'INVALID_ITEM';
    end;
    if v_product_id is null then raise exception 'INVALID_ITEM'; end if;
    if v_qty is null or v_qty < 0 or v_qty > 999 then raise exception 'INVALID_QUANTITY'; end if;
    if v_reprice and (v_price is null or v_price <= 0 or v_price <> round(v_price, 2)) then
      raise exception 'INVALID_AMOUNT';
    end if;
    v_desired := jsonb_set(v_desired, array[v_product_id::text], jsonb_build_object(
      'quantity', coalesce((v_desired -> v_product_id::text ->> 'quantity')::int, 0) + v_qty,
      'unit_price', coalesce(v_price, (v_desired -> v_product_id::text ->> 'unit_price')::numeric),
      'reprice', v_reprice or coalesce((v_desired -> v_product_id::text ->> 'reprice')::boolean, false)));
  end loop;

  -- Less of a product: back into the bag, cheapest lines first.
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
        perform private.fn_tech_return_sale_item(v_li.id, v_take, v_bag_id, v_note);
        v_to_return := v_to_return - v_take;
      end loop;
    end if;
  end loop;

  -- A new price.
  for v_key in select jsonb_object_keys(v_desired) loop
    if (v_desired -> v_key ->> 'reprice')::boolean then
      v_price := (v_desired -> v_key ->> 'unit_price')::numeric;
      for v_li in
        select id, quantity - returned_quantity as left_qty
        from public.sale_items_with_returns
        where sale_id = p_sale_id and product_id = v_key::uuid and returned_quantity < quantity
          and unit_price_snapshot <> v_price
        order by id
      loop
        perform private.fn_reprice_sale_item(v_li.id, v_li.left_qty, v_price, 'تعديل سعر · ' || v_note);
      end loop;
    end if;
  end loop;

  -- More of a product: out of the bag.
  for v_key in select jsonb_object_keys(v_desired) loop
    v_want := (v_desired -> v_key ->> 'quantity')::int;
    select coalesce(sum(quantity - returned_quantity), 0)::int into v_have
      from public.sale_items_with_returns where sale_id = p_sale_id and product_id = v_key::uuid;
    if v_want > v_have then
      v_qty := v_want - v_have;
      select id, name, selling_price, cost_price, is_service, is_assembly into v_product
        from public.products where id = v_key::uuid;
      if not found then raise exception 'PRODUCT_NOT_FOUND: %', v_key; end if;
      if v_product.is_assembly then raise exception 'ASSEMBLY_NOT_IN_BAG: %', v_product.name; end if;

      v_price := (v_desired -> v_key ->> 'unit_price')::numeric;
      if not (v_desired -> v_key ->> 'reprice')::boolean then
        if v_product.is_service then
          if v_price is null then
            select unit_price_snapshot into v_price from public.sale_items
              where sale_id = p_sale_id and product_id = v_product.id order by unit_price_snapshot desc limit 1;
          end if;
        else
          select unit_price_snapshot into v_price from public.sale_items_with_returns
            where sale_id = p_sale_id and product_id = v_product.id and returned_quantity < quantity
            order by unit_price_snapshot desc limit 1;
          v_price := coalesce(v_price, v_product.selling_price);
        end if;
      end if;
      if v_price is null or v_price <= 0 or v_price <> round(v_price, 2) then
        raise exception 'INVALID_AMOUNT';
      end if;

      insert into public.sale_items (sale_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount)
      values (p_sale_id, v_product.id, v_product.name, v_qty, v_price,
              case when v_product.is_service then 0 else v_product.cost_price end, 0);

      if not v_product.is_service then
        insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
        values (v_product.id, 'technician_sale', v_qty, 'technician_bag', v_bag_id, 'external', v_product.cost_price, 'sale', p_sale_id, v_note, auth.uid());
      end if;

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
  update public.sales set discount = v_discount where id = p_sale_id;

  perform private.fn_tech_sale_settle(p_sale_id, (v_before ->> 'total')::numeric,
                                      (v_before ->> 'paid_amount')::numeric, v_note);

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'TECHNICIAN_SALE_EDITED', 'sales', p_sale_id, v_before,
          (select to_jsonb(s) from public.sales s where s.id = p_sale_id));
end;
$$;

-- Cancels a technician invoice: everything still on it back into the bag,
-- the technician's (or a deferred customer's) account reversed, status ->
-- cancelled. A maintenance job's invoice is unlinked from the job so the
-- job can be invoiced again. Repeating it is a no-op.
create or replace function public.rpc_delete_technician_sale(p_sale_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_sale record;
  v_before jsonb;
  v_bag_id uuid;
  v_li record;
  v_reason text := coalesce(nullif(btrim(p_reason), ''), 'حذف فاتورة');
  v_note text;
begin
  if length(v_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_sale from public.sales where id = p_sale_id for update;
  if not found then raise exception 'SALE_NOT_FOUND'; end if;
  if not (public.is_admin() or (public.is_technician() and v_sale.technician_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;
  if v_sale.technician_id is null then raise exception 'NOT_A_TECHNICIAN_SALE'; end if;
  if v_sale.status = 'cancelled' then return; end if;
  if v_sale.status <> 'completed' then raise exception 'SALE_NOT_EDITABLE'; end if;
  v_before := to_jsonb(v_sale);
  v_note := v_reason || ' · فاتورة #' || v_sale.sale_number;

  select id into v_bag_id from public.technician_bags where technician_id = v_sale.technician_id;
  if v_bag_id is null then raise exception 'TECHNICIAN_BAG_NOT_FOUND'; end if;

  for v_li in
    select id, quantity - returned_quantity as left_qty
    from public.sale_items_with_returns where sale_id = p_sale_id and returned_quantity < quantity
  loop
    perform private.fn_tech_return_sale_item(v_li.id, v_li.left_qty, v_bag_id, v_note);
  end loop;

  -- Nothing is left on it: the whole total and payment are reversed.
  update public.sales set subtotal = 0, discount = 0 where id = p_sale_id;
  perform private.fn_tech_sale_settle(p_sale_id, (v_before ->> 'total')::numeric,
                                      (v_before ->> 'paid_amount')::numeric, v_note);

  update public.sales set status = 'cancelled', maintenance_request_id = null where id = p_sale_id;

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'TECHNICIAN_SALE_DELETED', 'sales', p_sale_id, v_before,
          (select to_jsonb(s) from public.sales s where s.id = p_sale_id));
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Expenses
-- ----------------------------------------------------------------------------

-- expenses stays immutable except for the update rpc_edit_expense makes,
-- flagged for its own transaction only.
create or replace function private.prevent_expense_mutation()
returns trigger language plpgsql as $$
begin
  if tg_op = 'UPDATE' and current_setting('app.expense_edit', true) = 'on' then
    return new;
  end if;
  raise exception 'Ledger rows are immutable: % on % is not allowed', tg_op, tg_table_name;
end;
$$;

drop trigger if exists trg_expenses_no_update on public.expenses;
create trigger trg_expenses_no_update
  before update or delete on public.expenses
  for each row execute function private.prevent_expense_mutation();

create or replace function public.rpc_edit_expense(
  p_expense_id uuid, p_category_id uuid, p_amount numeric, p_expense_date date, p_notes text
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_exp record;
  v_delta numeric(12,2);
  v_cashbox_id uuid;
  v_notes text := nullif(btrim(p_notes), '');
  v_note text;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then raise exception 'INVALID_AMOUNT'; end if;
  if length(v_notes) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_exp from public.expenses where id = p_expense_id for update;
  if not found then raise exception 'EXPENSE_NOT_FOUND'; end if;
  if exists (select 1 from public.employee_payrolls where expense_id = p_expense_id) then
    raise exception 'EXPENSE_IS_PAYROLL';
  end if;
  if p_category_id is not null and p_category_id <> v_exp.category_id
     and not exists (select 1 from public.expense_categories where id = p_category_id and is_active) then
    raise exception 'CATEGORY_NOT_FOUND';
  end if;

  v_note := 'تعديل مصروف #' || v_exp.expense_number;
  v_delta := p_amount - v_exp.amount;
  if v_delta <> 0 then
    -- The till the expense was paid from; the drawer if it can't be told.
    select cashbox_id into v_cashbox_id from public.cash_transactions
      where reference_type = 'expense' and reference_id = p_expense_id
      order by created_at limit 1;
    if v_cashbox_id is null then
      select id into v_cashbox_id from public.cashboxes where kind = 'cash' and is_active limit 1;
    end if;
    if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

    if v_delta > 0 then
      insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
      values (v_cashbox_id, 'expense', -v_delta, 'expense', p_expense_id, v_note, auth.uid());
    else
      insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
      values (v_cashbox_id, 'adjustment', -v_delta, 'expense', p_expense_id, v_note, auth.uid());
    end if;
  end if;

  perform set_config('app.expense_edit', 'on', true);
  update public.expenses set
    amount = p_amount,
    category_id = coalesce(p_category_id, category_id),
    expense_date = coalesce(p_expense_date, expense_date),
    notes = v_notes
  where id = p_expense_id;
  perform set_config('app.expense_edit', 'off', true);

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'EXPENSE_EDITED', 'expenses', p_expense_id, to_jsonb(v_exp),
          (select to_jsonb(e) from public.expenses e where e.id = p_expense_id));
end;
$$;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_edit_technician_sale', 'admin / the sale''s technician'),
  ('rpc_delete_technician_sale', 'admin / the sale''s technician'),
  ('rpc_edit_expense', 'admin/sales')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
