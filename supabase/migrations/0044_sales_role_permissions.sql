-- ============================================================================
-- 0044_sales_role_permissions.sql  (Phase 16 — sales role permissions)
--
-- A "sales" (مبيعات) staff account: can register products, see and handle
-- every order, receive/issue warehouse stock, record a walk-in sale, create
-- offers/banners, and approve/reject InstaPay transfers — but must NEVER
-- see reports, the dashboard, the cashbox ledger, expenses, customers,
-- wallets, users, the audit log, or change the InstaPay receiving handle.
--
-- Every one of those exclusions is already the default: they stay
-- is_admin()-only and this migration does not touch them at all. Only the
-- specific tables/RPCs the business explicitly asked for are widened, each
-- with `public.is_admin() or public.is_sales()`.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Role helper — same pattern as is_admin()/is_technician()/is_customer().
-- ----------------------------------------------------------------------------
create or replace function public.is_sales() returns boolean
language sql stable as $$ select public.auth_role() = 'sales'; $$;

insert into private.rpc_allowlist (function_name, note) values
  ('is_sales', 'RLS helper')
on conflict (function_name) do nothing;

-- ----------------------------------------------------------------------------
-- 2. Products — sales can register/edit products, but not delete them
--    (products_write stays admin-only for DELETE; these are additive INSERT/
--    UPDATE-only policies, OR'd together with it by Postgres RLS).
-- ----------------------------------------------------------------------------
create policy products_insert_sales on public.products for insert to authenticated
  with check (public.is_sales());
create policy products_update_sales on public.products for update to authenticated
  using (public.is_sales()) with check (public.is_sales());

-- ----------------------------------------------------------------------------
-- 3. Warehouse — sales can see stock levels and movement history (the writes
--    themselves happen through rpc_receive_purchase/rpc_issue_stock_to_technician,
--    widened in section 5 below; warehouse_stock/stock_movements have no
--    direct write grant for anyone).
-- ----------------------------------------------------------------------------
alter policy warehouse_stock_select on public.warehouse_stock
  using (public.is_admin() or public.is_sales());

alter policy stock_movements_select on public.stock_movements
  using (
    public.is_admin()
    or public.is_sales()
    or (public.is_technician() and (
      from_location_id in (select id from public.technician_bags where technician_id = auth.uid())
      or to_location_id in (select id from public.technician_bags where technician_id = auth.uid())
    ))
  );

-- ----------------------------------------------------------------------------
-- 4. Orders — sales can see every order (not just their own — there is no
--    "own" for staff) and act on it via the RPCs widened in section 5.
-- ----------------------------------------------------------------------------
alter policy orders_select on public.orders
  using (public.is_admin() or public.is_sales() or customer_id = auth.uid());

alter policy order_items_select on public.order_items
  using (
    public.is_admin()
    or public.is_sales()
    or order_id in (select id from public.orders where customer_id = auth.uid())
  );

-- ----------------------------------------------------------------------------
-- 5. Order-handling / warehouse / walk-in-sale RPCs — same bodies as their
--    current (latest) versions, only the FORBIDDEN check widens.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_confirm_order(p_order_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_warehouse_id uuid;
  v_item record;
  v_customer_id uuid;
  v_total numeric(12,2);
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  select customer_id, total into v_customer_id, v_total from public.orders where id = p_order_id and status = 'pending' for update;
  if v_customer_id is null then raise exception 'ORDER_NOT_PENDING'; end if;

  for v_item in select * from public.order_items where order_id = p_order_id loop
    insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
    values (v_item.product_id, 'sale', v_item.quantity, 'warehouse', v_warehouse_id, 'external', v_item.unit_cost_snapshot, 'order', p_order_id, 'بيع - تأكيد طلب', auth.uid());
  end loop;

  update public.orders set status = 'confirmed', confirmed_by = auth.uid() where id = p_order_id;

  insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
  values (v_customer_id, 'order_charge', v_total, p_order_id, 'قيمة الطلب', auth.uid());

  perform public.notify_user(v_customer_id, 'order_status', 'تم تأكيد طلبك', 'جاري تجهيز طلبك الآن', jsonb_build_object('order_id', p_order_id));
end;
$$;

create or replace function public.rpc_update_order_status(p_order_id uuid, p_new_status order_status)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_status order_status;
  v_customer_id uuid;
  v_label text;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;

  select status, customer_id into v_status, v_customer_id
    from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;

  -- pending -> confirmed is rpc_confirm_order (stock + charge); any -> cancelled
  -- is rpc_cancel_order (reversals). Only the pure fulfilment steps live here.
  if not (
       (v_status = 'confirmed' and p_new_status in ('preparing', 'delivered'))
    or (v_status = 'preparing' and p_new_status = 'delivered')
    or (v_status = 'delivered' and p_new_status = 'completed')
  ) then
    raise exception 'INVALID_STATUS_TRANSITION: % -> %', v_status, p_new_status;
  end if;

  update public.orders set status = p_new_status where id = p_order_id;

  v_label := case p_new_status
    when 'preparing' then 'جاري تجهيز طلبك'
    when 'delivered' then 'تم توصيل طلبك'
    when 'completed' then 'تم إكمال طلبك'
  end;
  perform public.notify_user(v_customer_id, 'order_status', 'تحديث حالة الطلب', v_label,
    jsonb_build_object('order_id', p_order_id, 'status', p_new_status));
end;
$$;

create or replace function public.rpc_cancel_order(p_order_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_warehouse_id uuid;
  v_item record;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_reason is null or btrim(p_reason) = '' then raise exception 'REASON_REQUIRED'; end if;
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.status in ('completed', 'cancelled', 'returned') then
    raise exception 'ORDER_NOT_CANCELLABLE';
  end if;

  if v_order.status <> 'pending' then
    select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
    if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

    for v_item in select * from public.order_items where order_id = p_order_id loop
      insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, to_location_type, to_location_id, unit_cost, reference_type, reference_id, notes, created_by)
      values (v_item.product_id, 'return_from_customer', v_item.quantity, 'external', 'warehouse', v_warehouse_id, v_item.unit_cost_snapshot, 'order', p_order_id, 'إلغاء طلب', auth.uid());
    end loop;

    insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
    values (v_order.customer_id, 'return_credit', -v_order.total, p_order_id, 'إلغاء طلب', auth.uid());
  end if;

  perform private.fn_apply_order_refund(p_order_id, p_reason);

  update public.orders
    set status = 'cancelled', cancelled_reason = btrim(p_reason),
        payment_status = case when v_order.paid_amount > 0 then 'refunded' else payment_status end
    where id = p_order_id;
  perform public.notify_user(v_order.customer_id, 'order_status', 'تم إلغاء طلبك', btrim(p_reason),
    jsonb_build_object('order_id', p_order_id, 'status', 'cancelled'));
end;
$$;

create or replace function public.rpc_admin_return_order(p_order_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_warehouse_id uuid;
  v_item record;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_reason is null or btrim(p_reason) = '' then raise exception 'REASON_REQUIRED'; end if;
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.status not in ('delivered', 'completed') then
    raise exception 'ORDER_NOT_RETURNABLE';
  end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  for v_item in select * from public.order_items where order_id = p_order_id loop
    insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, to_location_type, to_location_id, unit_cost, reference_type, reference_id, notes, created_by)
    values (v_item.product_id, 'return_from_customer', v_item.quantity, 'external', 'warehouse', v_warehouse_id, v_item.unit_cost_snapshot, 'order', p_order_id, 'إرجاع طلب', auth.uid());
  end loop;

  insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
  values (v_order.customer_id, 'return_credit', -v_order.total, p_order_id, 'إرجاع طلب', auth.uid());

  perform private.fn_apply_order_refund(p_order_id, p_reason);

  update public.orders
    set status = 'returned', cancelled_reason = btrim(p_reason),
        payment_status = case when v_order.paid_amount > 0 then 'refunded' else payment_status end
    where id = p_order_id;
  perform public.notify_user(v_order.customer_id, 'order_status', 'تم استلام إرجاع طلبك', btrim(p_reason),
    jsonb_build_object('order_id', p_order_id, 'status', 'returned'));
end;
$$;

create or replace function public.rpc_record_customer_payment(
  p_customer_id uuid, p_amount numeric, p_order_id uuid, p_notes text,
  p_client_request_id uuid default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_cashbox_id uuid;
  v_existing record;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then
    raise exception 'INVALID_AMOUNT';
  end if;
  if length(p_notes) > 500 then raise exception 'INPUT_TOO_LONG'; end if;
  if not exists (select 1 from public.customers where id = p_customer_id) then
    raise exception 'CUSTOMER_NOT_FOUND';
  end if;

  if p_client_request_id is not null then
    select customer_id, amount into v_existing
      from public.customer_account_transactions where client_request_id = p_client_request_id;
    if found then
      if v_existing.customer_id <> p_customer_id or -v_existing.amount <> p_amount then
        raise exception 'IDEMPOTENCY_KEY_CONFLICT';
      end if;
      return; -- already recorded
    end if;
  end if;

  if p_order_id is not null then
    select * into v_order from public.orders where id = p_order_id for update;
    if not found then raise exception 'ORDER_NOT_FOUND'; end if;
    if v_order.customer_id <> p_customer_id then raise exception 'ORDER_CUSTOMER_MISMATCH'; end if;
    if v_order.status in ('cancelled', 'returned') then raise exception 'ORDER_NOT_PAYABLE'; end if;
    if p_amount > v_order.total - v_order.paid_amount then
      raise exception 'AMOUNT_EXCEEDS_REMAINING';
    end if;
  end if;

  select id into v_cashbox_id from public.cashboxes where is_active limit 1;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

  begin
    insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by, client_request_id)
    values (p_customer_id, 'payment', -p_amount, p_order_id, p_notes, auth.uid(), p_client_request_id);
  exception when unique_violation then
    return; -- a concurrent retry with the same key already recorded it
  end;

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  values (v_cashbox_id, 'sale', p_amount, 'order', p_order_id, p_notes, auth.uid());

  if p_order_id is not null then
    update public.orders
      set paid_amount = paid_amount + p_amount,
          payment_status = (case
            when v_order.paid_amount + p_amount >= v_order.total then 'paid'
            else 'partially_paid'
          end)::payment_status
      where id = p_order_id;
  end if;
end;
$$;

create or replace function public.rpc_receive_purchase(p_product_id uuid, p_quantity int, p_unit_cost numeric, p_notes text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_warehouse_id uuid;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
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
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
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
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  -- The till is credited in full below, so a deferred counter sale would book
  -- cash that never arrived. The UI never offers it; refuse it here too.
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

  select id into v_cashbox_id from public.cashboxes where is_active limit 1;
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
      v_unit_price := v_product.selling_price;
    end if;

    if v_line_discount < 0 or v_line_discount > v_qty * v_unit_price then
      raise exception 'INVALID_DISCOUNT';
    end if;

    v_subtotal := v_subtotal + v_qty * v_unit_price - v_line_discount;

    insert into public.sale_items (sale_id, product_id, product_name_snapshot, quantity, unit_price_snapshot, unit_cost_snapshot, discount)
    values (v_sale_id, v_product.id, v_product.name, v_qty, v_unit_price,
            case when v_product.is_service then 0 else v_product.cost_price end, v_line_discount);

    if not v_product.is_service then
      insert into public.stock_movements (product_id, movement_type, quantity, from_location_type, from_location_id, to_location_type, unit_cost, reference_type, reference_id, notes, created_by)
      values (v_product.id, 'sale', v_qty, 'warehouse', v_warehouse_id, 'external', v_product.cost_price, 'sale', v_sale_id, p_notes, auth.uid());
    end if;
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
-- 6. Marketing (offers/banners) — sales can create/edit, same as admin.
--    No delete policy existed for offers/home_banners before this (admin
--    never had one either), so none is added for sales.
-- ----------------------------------------------------------------------------
alter policy offers_admin_insert on public.offers
  with check (public.is_admin() or public.is_sales());
alter policy offers_admin_update on public.offers
  using (public.is_admin() or public.is_sales()) with check (public.is_admin() or public.is_sales());

alter policy offer_products_admin_write on public.offer_products
  using (public.is_admin() or public.is_sales()) with check (public.is_admin() or public.is_sales());

alter policy home_banners_admin_insert on public.home_banners
  with check (public.is_admin() or public.is_sales());
alter policy home_banners_admin_update on public.home_banners
  using (public.is_admin() or public.is_sales()) with check (public.is_admin() or public.is_sales());

alter policy "marketing_admin_insert" on storage.objects
  with check (bucket_id = 'marketing' and (public.is_admin() or public.is_sales()));
alter policy "marketing_admin_update" on storage.objects
  using (bucket_id = 'marketing' and (public.is_admin() or public.is_sales()));
alter policy "marketing_admin_delete" on storage.objects
  using (bucket_id = 'marketing' and (public.is_admin() or public.is_sales()));

-- ----------------------------------------------------------------------------
-- 7. InstaPay review — approve/reject only. rpc_admin_set_text_setting (the
--    InstaPay handle/beneficiary name) is deliberately left admin-only: sales
--    reviews transfers, it does not change where customer money is expected
--    to land.
-- ----------------------------------------------------------------------------
alter policy payments_select on public.payments
  using (customer_id = auth.uid() or public.is_admin() or public.is_sales());

alter policy "payment_proofs_owner_read" on storage.objects
  using (
    bucket_id = 'payment_proofs'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin() or public.is_sales())
  );

create or replace function public.rpc_admin_verify_instapay(
  p_payment_id uuid, p_approve boolean, p_rejection_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_payment record;
  v_order record;
  v_attempt_no int;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_approve is null then raise exception 'INVALID_INPUT'; end if;
  if not p_approve and (p_rejection_reason is null or btrim(p_rejection_reason) = '') then
    raise exception 'REASON_REQUIRED';
  end if;
  if length(p_rejection_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_payment from public.payments where id = p_payment_id for update;
  if not found then raise exception 'PAYMENT_NOT_FOUND'; end if;
  if v_payment.channel <> 'instapay' then raise exception 'NOT_AN_INSTAPAY_PAYMENT'; end if;
  -- Locked by the SELECT ... FOR UPDATE above: a second concurrent verify
  -- call blocks until the first commits, then finds this false and stops —
  -- no double-apply (master prompt Test 9).
  if v_payment.status <> 'pending_verification' then
    raise exception 'PAYMENT_NOT_PENDING_VERIFICATION';
  end if;

  select coalesce(max(attempt_no), 0) + 1 into v_attempt_no
    from public.payment_attempts where payment_id = p_payment_id;

  if p_approve then
    update public.payments set status = 'succeeded', paid_at = now() where id = p_payment_id;
    insert into public.payment_attempts (payment_id, attempt_no, status)
    values (p_payment_id, v_attempt_no, 'succeeded');

    if v_payment.order_id is not null then
      select * into v_order from public.orders where id = v_payment.order_id for update;
      -- InstaPay money lands in the bank account, not the physical
      -- cashbox — unlike rpc_record_customer_payment's cash path, this
      -- must NOT touch cash_transactions (that ledger is physical-till
      -- only). The customer account ledger still reconciles either way.
      insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
      values (v_payment.customer_id, 'payment', -v_payment.amount, v_payment.order_id, 'تحويل InstaPay مؤكَّد', auth.uid());

      update public.orders
        set paid_amount = paid_amount + v_payment.amount,
            payment_status = (case
              when v_order.paid_amount + v_payment.amount >= v_order.total then 'paid'
              else 'partially_paid'
            end)::payment_status
        where id = v_payment.order_id;
    end if;

    perform public.notify_user(v_payment.customer_id, 'payment_confirmed', 'تم تأكيد تحويلك',
      format('تم تأكيد تحويل InstaPay بقيمة %s ج.م', v_payment.amount),
      jsonb_build_object('payment_id', p_payment_id, 'order_id', v_payment.order_id));
  else
    update public.payments
      set status = 'failed', metadata = metadata || jsonb_build_object('rejection_reason', btrim(p_rejection_reason))
      where id = p_payment_id;
    insert into public.payment_attempts (payment_id, attempt_no, status, failure_reason)
    values (p_payment_id, v_attempt_no, 'failed', btrim(p_rejection_reason));

    perform public.notify_user(v_payment.customer_id, 'payment_rejected', 'تعذَّر تأكيد تحويلك',
      btrim(p_rejection_reason),
      jsonb_build_object('payment_id', p_payment_id, 'order_id', v_payment.order_id));
  end if;
end;
$$;

select private.apply_function_grants();
