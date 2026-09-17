-- ============================================================================
-- 0030_finance_and_workflow_fixes_p1.sql
--
-- Phase 0.5, second half: the P1 business-logic findings of the Phase 0
-- audit. Nothing here drops or rewrites ledger rows; every fix is either a
-- stricter RPC or an additive column.
--
--   P1-7   rpc_update_order_status had no state machine (pending -> completed
--          skipped stock deduction and the customer charge; a cancelled order
--          could be "delivered").
--   P1-8   rpc_cancel_order refunded paid cash from the till AND credited the
--          full order total back, leaving the customer with a phantom credit
--          equal to what they had already been refunded.
--   P1-9   rpc_record_customer_payment: no order/customer ownership check, no
--          idempotency, overpayment allowed, and a silent no-op on the till
--          when no cashbox exists (the exact failure mode 0023 fixed
--          elsewhere).
--   P1-10  rpc_technician_sale: a technician could raise deferred debt on any
--          customer id, attach an invoice to a job not assigned to them, and
--          record paid/discount amounts outside the sale total.
--   P1-11  rpc_technician_supply posted straight to the ledgers on the
--          technician's word, cutting their amount due and inflating the till
--          before anyone had received the cash.
--   P1-12  client_request_id idempotency was not scoped to the caller.
--   P1-13  Maintenance request input unbounded; a customer could cancel a job
--          already in progress; assignment accepted inactive technicians.
--   P1-guards  rpc_issue_stock_to_technician had no main-warehouse guard and
--          no item validation.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Order state machine (P1-7)
-- ----------------------------------------------------------------------------
create or replace function public.rpc_update_order_status(p_order_id uuid, p_new_status order_status)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_status order_status;
  v_customer_id uuid;
  v_label text;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;

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

-- ----------------------------------------------------------------------------
-- 2. Cancellation without the double refund (P1-8)
-- ----------------------------------------------------------------------------
-- Customer account after cancelling a confirmed order that had P paid:
--   order_charge +T, payment -P, return_credit -T, refund adjustment +P = 0
-- and the till: +P (payment) -P (refund) = 0. Before this fix the +P
-- adjustment was missing, so the account showed -P (money owed back) even
-- though the cash had already been handed back.
create or replace function public.rpc_cancel_order(p_order_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_warehouse_id uuid;
  v_cashbox_id uuid;
  v_balance numeric(14,2);
  v_item record;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
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

  if v_order.paid_amount > 0 then
    select id into v_cashbox_id from public.cashboxes where is_active limit 1 for update;
    if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

    select coalesce(sum(amount), 0) into v_balance
      from public.cash_transactions where cashbox_id = v_cashbox_id;
    if v_order.paid_amount > v_balance then
      raise exception 'INSUFFICIENT_CASH: %', v_balance;
    end if;

    insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
    values (v_cashbox_id, 'refund', -v_order.paid_amount, 'order', p_order_id, 'استرداد إلغاء طلب', auth.uid());

    insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
    values (v_order.customer_id, 'adjustment', v_order.paid_amount, p_order_id, 'استرداد مدفوعات طلب ملغي', auth.uid());
  end if;

  update public.orders set status = 'cancelled', cancelled_reason = btrim(p_reason) where id = p_order_id;
  perform public.notify_user(v_order.customer_id, 'order_status', 'تم إلغاء طلبك', btrim(p_reason),
    jsonb_build_object('order_id', p_order_id, 'status', 'cancelled'));
end;
$$;

-- ----------------------------------------------------------------------------
-- 3. Customer payments: ownership, bounds, idempotency (P1-9)
-- ----------------------------------------------------------------------------
-- Additive column on an append-only table (ALTER, not UPDATE — the
-- immutability trigger is untouched). Existing rows keep NULL.
alter table public.customer_account_transactions
  add column if not exists client_request_id uuid;
create unique index if not exists customer_account_transactions_client_request_id_key
  on public.customer_account_transactions (client_request_id)
  where client_request_id is not null;

-- The signature gains an optional key; drop the old one so PostgREST never
-- has two candidates. Old clients calling without the key still resolve here.
drop function if exists public.rpc_record_customer_payment(uuid, numeric, uuid, text);

create or replace function public.rpc_record_customer_payment(
  p_customer_id uuid, p_amount numeric, p_order_id uuid, p_notes text,
  p_client_request_id uuid default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_cashbox_id uuid;
  v_existing record;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
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
    update public.orders set paid_amount = paid_amount + p_amount where id = p_order_id;
  end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Technician sale / maintenance invoice (P1-10, P1-12)
-- ----------------------------------------------------------------------------
create or replace function public.rpc_technician_sale(
  p_technician_id uuid, p_customer_id uuid, p_customer_name text, p_customer_phone text,
  p_items jsonb, p_payment_method payment_method, p_discount numeric, p_paid_amount numeric,
  p_client_request_id uuid, p_notes text, p_maintenance_request_id uuid default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_sale_id uuid;
  v_existing record;
  v_bag_id uuid;
  v_request record;
  v_customer_id uuid := p_customer_id;
  v_item jsonb;
  v_product_id uuid;
  v_product record;
  v_qty int;
  v_unit_price numeric(12,2);
  v_line_discount numeric(12,2);
  v_discount numeric(12,2) := coalesce(p_discount, 0);
  v_paid numeric(12,2) := coalesce(p_paid_amount, 0);
  v_subtotal numeric(12,2) := 0;
  v_total numeric(12,2);
begin
  if not (public.is_admin() or (public.is_technician() and p_technician_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;
  if p_payment_method is null then raise exception 'INVALID_INPUT'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_ORDER';
  end if;
  if jsonb_array_length(p_items) > 100 then raise exception 'TOO_MANY_ITEMS'; end if;
  if length(p_customer_name) > 100 or length(p_customer_phone) > 20 or length(p_notes) > 1000 then
    raise exception 'INPUT_TOO_LONG';
  end if;
  if v_discount < 0 or v_discount <> round(v_discount, 2) then raise exception 'INVALID_DISCOUNT'; end if;
  if v_paid < 0 or v_paid <> round(v_paid, 2) then raise exception 'INVALID_AMOUNT'; end if;

  if p_client_request_id is not null then
    select id, technician_id into v_existing from public.sales where client_request_id = p_client_request_id;
    if found then
      if v_existing.technician_id is distinct from p_technician_id then
        raise exception 'IDEMPOTENCY_KEY_CONFLICT';
      end if;
      return v_existing.id;
    end if;
  end if;

  if p_maintenance_request_id is not null then
    select id, customer_id, assigned_technician_id, status into v_request
      from public.maintenance_requests where id = p_maintenance_request_id for update;
    if not found then raise exception 'REQUEST_NOT_FOUND'; end if;
    -- Only the job's own technician invoices it (an admin acts on their behalf
    -- by passing that technician's id).
    if v_request.assigned_technician_id is distinct from p_technician_id then
      raise exception 'FORBIDDEN';
    end if;
    if v_request.status not in ('in_progress', 'completed') then
      raise exception 'REQUEST_NOT_INVOICEABLE';
    end if;

    select id, technician_id into v_existing from public.sales where maintenance_request_id = p_maintenance_request_id;
    if found then return v_existing.id; end if;

    if p_customer_id is not null and p_customer_id <> v_request.customer_id then
      raise exception 'FORBIDDEN';
    end if;
    v_customer_id := v_request.customer_id;
  elsif p_customer_id is not null then
    -- A technician can't pick an arbitrary registered customer to bill.
    if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
    if not exists (select 1 from public.customers where id = p_customer_id) then
      raise exception 'CUSTOMER_NOT_FOUND';
    end if;
  end if;

  if p_payment_method = 'deferred' then
    -- Deferred debt must land on a real customer account, or it is untracked.
    if v_customer_id is null then raise exception 'DEFERRED_REQUIRES_CUSTOMER'; end if;
    if v_paid > 0 then raise exception 'INVALID_AMOUNT'; end if;
  end if;

  select id into v_bag_id from public.technician_bags where technician_id = p_technician_id;
  if v_bag_id is null then raise exception 'TECHNICIAN_BAG_NOT_FOUND'; end if;

  begin
    insert into public.sales (technician_id, customer_id, customer_name, customer_phone, payment_method, discount, paid_amount, client_request_id, maintenance_request_id)
    values (p_technician_id, v_customer_id, nullif(btrim(p_customer_name), ''), nullif(btrim(p_customer_phone), ''),
            p_payment_method, v_discount, v_paid, p_client_request_id, p_maintenance_request_id)
    returning id into v_sale_id;
  exception when unique_violation then
    select id, technician_id into v_existing from public.sales
      where (p_client_request_id is not null and client_request_id = p_client_request_id)
         or (p_maintenance_request_id is not null and maintenance_request_id = p_maintenance_request_id)
      limit 1;
    if v_existing.technician_id is distinct from p_technician_id then
      raise exception 'IDEMPOTENCY_KEY_CONFLICT';
    end if;
    return v_existing.id;
  end;

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
      from public.products where id = v_product_id;
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
      values (v_product.id, 'technician_sale', v_qty, 'technician_bag', v_bag_id, 'external', v_product.cost_price, 'sale', v_sale_id, p_notes, auth.uid());
    end if;
  end loop;

  if v_discount > v_subtotal then raise exception 'INVALID_DISCOUNT'; end if;
  v_total := v_subtotal - v_discount;
  if v_paid > v_total then raise exception 'PAYMENT_EXCEEDS_TOTAL'; end if;

  update public.sales set subtotal = v_subtotal where id = v_sale_id;

  if p_payment_method = 'deferred' then
    insert into public.customer_account_transactions (customer_id, transaction_type, amount, notes, created_by)
    values (v_customer_id, 'order_charge', v_total, 'بيع صنايعي آجل', auth.uid());
  elsif v_paid > 0 then
    insert into public.technician_account_transactions (technician_id, transaction_type, amount, sale_id, notes, created_by)
    values (p_technician_id, 'sale_credit', v_paid, v_sale_id, 'تحصيل بيع', auth.uid());
  end if;

  return v_sale_id;
end;
$$;

-- Counter sale: admin-only, so the risk is integrity rather than abuse — a
-- mistyped discount must not produce a negative sale or till entry.
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
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
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
-- 5. Technician supply needs admin confirmation (P1-11)
-- ----------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'supply_status') then
    create type supply_status as enum ('pending', 'confirmed', 'rejected');
  end if;
end $$;

-- Existing rows already hit the ledgers, so they backfill as 'confirmed';
-- the default then flips to 'pending' for everything recorded from now on.
alter table public.technician_supplies
  add column if not exists status supply_status not null default 'confirmed',
  add column if not exists reviewed_by uuid references public.users(id),
  add column if not exists reviewed_at timestamptz,
  add column if not exists rejection_reason text;
alter table public.technician_supplies alter column status set default 'pending';

create index if not exists idx_tech_supplies_pending
  on public.technician_supplies (technician_id, created_at desc)
  where status = 'pending';

-- Posts a confirmed supply to both ledgers. Internal only (not allowlisted).
create or replace function public.post_technician_supply(p_supply_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_supply record;
  v_cashbox_id uuid;
begin
  select * into v_supply from public.technician_supplies where id = p_supply_id;

  select id into v_cashbox_id from public.cashboxes where is_active limit 1;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

  insert into public.technician_account_transactions (technician_id, transaction_type, amount, supply_id, notes, created_by)
  values (v_supply.technician_id, 'supply_debit', v_supply.amount, v_supply.id, 'توريد للخزنة', auth.uid());

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  values (v_cashbox_id, 'technician_deposit', v_supply.amount, 'technician_supply', v_supply.id, v_supply.notes, auth.uid());
end;
$$;

-- Same signature. An admin recording a supply is confirming cash in hand, so
-- it posts immediately; a technician's own entry waits for an admin.
create or replace function public.rpc_technician_supply(p_technician_id uuid, p_amount numeric, p_notes text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_supply_id uuid;
  v_name text;
begin
  if not (public.is_admin() or (public.is_technician() and p_technician_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then
    raise exception 'INVALID_AMOUNT';
  end if;
  if length(p_notes) > 500 then raise exception 'INPUT_TOO_LONG'; end if;
  if not exists (select 1 from public.technicians where id = p_technician_id) then
    raise exception 'TECHNICIAN_NOT_AVAILABLE';
  end if;

  if public.is_admin() then
    if not exists (select 1 from public.cashboxes where is_active) then raise exception 'NO_CASHBOX'; end if;
    insert into public.technician_supplies (technician_id, amount, notes, recorded_by, status, reviewed_by, reviewed_at)
    values (p_technician_id, p_amount, nullif(btrim(p_notes), ''), auth.uid(), 'confirmed', auth.uid(), now())
    returning id into v_supply_id;
    perform public.post_technician_supply(v_supply_id);
  else
    insert into public.technician_supplies (technician_id, amount, notes, recorded_by, status)
    values (p_technician_id, p_amount, nullif(btrim(p_notes), ''), auth.uid(), 'pending')
    returning id into v_supply_id;

    select full_name into v_name from public.users where id = p_technician_id;
    perform public.notify_all_admins('supply_pending', 'توريد بانتظار التأكيد',
      format('%s سجّل توريد %s ج.م — راجِع الاستلام وأكِّده', v_name, p_amount),
      jsonb_build_object('supply_id', v_supply_id, 'technician_id', p_technician_id));
  end if;

  return v_supply_id;
end;
$$;

-- Approve or reject a pending supply. Repeating the same decision is a no-op
-- (never a second ledger posting); contradicting an earlier decision fails.
create or replace function public.rpc_admin_review_technician_supply(
  p_supply_id uuid, p_approve boolean, p_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_supply record;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_approve is null then raise exception 'INVALID_INPUT'; end if;
  if not p_approve and (p_reason is null or btrim(p_reason) = '') then
    raise exception 'REASON_REQUIRED';
  end if;
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_supply from public.technician_supplies where id = p_supply_id for update;
  if not found then raise exception 'SUPPLY_NOT_FOUND'; end if;

  if v_supply.status <> 'pending' then
    if (p_approve and v_supply.status = 'confirmed') or (not p_approve and v_supply.status = 'rejected') then
      return;
    end if;
    raise exception 'SUPPLY_NOT_PENDING';
  end if;

  if p_approve then
    update public.technician_supplies
      set status = 'confirmed', reviewed_by = auth.uid(), reviewed_at = now()
      where id = p_supply_id;
    perform public.post_technician_supply(p_supply_id);
    perform public.notify_user(v_supply.technician_id, 'supply_confirmed', 'تم تأكيد التوريد',
      format('تم استلام توريد %s ج.م', v_supply.amount), jsonb_build_object('supply_id', p_supply_id));
  else
    update public.technician_supplies
      set status = 'rejected', reviewed_by = auth.uid(), reviewed_at = now(), rejection_reason = btrim(p_reason)
      where id = p_supply_id;
    perform public.notify_user(v_supply.technician_id, 'supply_rejected', 'تم رفض التوريد',
      btrim(p_reason), jsonb_build_object('supply_id', p_supply_id));
  end if;

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), case when p_approve then 'SUPPLY_CONFIRMED' else 'SUPPLY_REJECTED' end,
          'technician_supplies', p_supply_id, to_jsonb(v_supply),
          (select to_jsonb(s) from public.technician_supplies s where s.id = p_supply_id));
end;
$$;

-- ----------------------------------------------------------------------------
-- 6. Maintenance input bounds and cancellation window (P1-13)
-- ----------------------------------------------------------------------------
create or replace function public.rpc_create_maintenance_request(
  p_customer_id uuid, p_customer_name text, p_phone text, p_address text,
  p_latitude numeric, p_longitude numeric, p_device_type text, p_problem_description text, p_notes text
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
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
  if length(p_customer_name) > 100 or length(p_address) > 500 or length(p_device_type) > 100
     or length(p_problem_description) > 2000 or length(p_notes) > 1000 then
    raise exception 'INPUT_TOO_LONG';
  end if;
  if (p_latitude is not null and (p_latitude < -90 or p_latitude > 90))
     or (p_longitude is not null and (p_longitude < -180 or p_longitude > 180)) then
    raise exception 'INVALID_LOCATION';
  end if;

  -- Abuse guard: a customer flooding the shared queue pushes everyone back.
  if not public.is_admin() and (
    select count(*) from public.maintenance_requests
    where customer_id = p_customer_id and status in ('waiting', 'assigned', 'in_progress')
  ) >= 5 then
    raise exception 'TOO_MANY_ACTIVE_REQUESTS';
  end if;

  insert into public.maintenance_requests (customer_id, customer_name, phone, address, latitude, longitude, device_type, problem_description, notes)
  values (p_customer_id, btrim(p_customer_name), regexp_replace(p_phone, '[\s-]', '', 'g'),
          nullif(btrim(p_address), ''), p_latitude, p_longitude, nullif(btrim(p_device_type), ''),
          btrim(p_problem_description), nullif(btrim(p_notes), ''))
  returning id into v_id;

  return v_id;
end;
$$;

-- A customer may withdraw a job until a technician starts on it; after that
-- only an admin can cancel (the technician is already on site / working).
create or replace function public.rpc_cancel_maintenance(p_request_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  update public.maintenance_requests
    set status = 'cancelled', cancelled_at = now(), cancelled_reason = nullif(btrim(p_reason), '')
    where id = p_request_id
      and (
        (public.is_admin() and status in ('waiting', 'assigned', 'in_progress'))
        or (public.is_customer() and customer_id = auth.uid() and status in ('waiting', 'assigned'))
      );
  if not found then raise exception 'FORBIDDEN_OR_NOT_CANCELLABLE'; end if;
end;
$$;

create or replace function public.rpc_assign_maintenance(p_request_id uuid, p_technician_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if not exists (
    select 1 from public.technicians t join public.users u on u.id = t.id
    where t.id = p_technician_id and t.is_active and u.is_active
  ) then
    raise exception 'TECHNICIAN_NOT_AVAILABLE';
  end if;

  update public.maintenance_requests
    set status = 'assigned', assigned_technician_id = p_technician_id, assigned_at = now()
    where id = p_request_id and status = 'waiting';
  if not found then raise exception 'REQUEST_NOT_WAITING'; end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- 7. Stock issue guards
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- 8. Grants (see the rule in 0029's header)
-- ----------------------------------------------------------------------------
insert into private.rpc_allowlist (function_name, note) values
  ('rpc_admin_review_technician_supply', 'admin')
on conflict (function_name) do nothing;

select private.apply_function_grants();
