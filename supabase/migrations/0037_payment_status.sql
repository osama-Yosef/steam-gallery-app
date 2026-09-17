-- ============================================================================
-- 0037_payment_status.sql  (Phase 9 — orders: order status ≠ payment status)
--
-- orders.status has always been the FULFILMENT state (pending → confirmed →
-- preparing → delivered → completed, or cancelled/returned). Whether the
-- order was PAID lived only implicitly in paid_amount vs total, with no
-- explicit state — an order that was fully paid then cancelled-and-refunded
-- looked identical (paid_amount unchanged) to one that was simply paid,
-- because nothing ever recorded "this money came back".
--
-- This adds an explicit, independent payment_status column that:
--   * starts 'unpaid' on every new order;
--   * is advanced by rpc_record_customer_payment as cash comes in
--     (unpaid → partially_paid → paid — never backwards, since that
--     function only ever adds a positive amount);
--   * becomes 'refunded' by rpc_cancel_order when it hands cash back.
-- A customer can be shown "الطلب: جاري التجهيز" and "الدفع: مدفوع بالكامل"
-- as two independent facts, exactly as the business rule requires. Nothing
-- here lets a customer set either status themselves — both remain
-- SECURITY DEFINER RPC-only, same as before.
-- ============================================================================

create type payment_status as enum ('unpaid', 'partially_paid', 'paid', 'refunded');

alter table public.orders
  add column payment_status payment_status not null default 'unpaid';

-- Backfill from the existing paid_amount/status data (additive only — no
-- rows are deleted or blanked, this only fills in the new column).
update public.orders set payment_status = (case
  when status in ('cancelled', 'returned') and paid_amount > 0 then 'refunded'
  when paid_amount <= 0 then 'unpaid'
  when paid_amount >= total then 'paid'
  else 'partially_paid'
end)::payment_status;

-- ----------------------------------------------------------------------------
-- rpc_record_customer_payment: advance payment_status alongside paid_amount
-- ----------------------------------------------------------------------------
-- Same signature as 0030's version — this only changes the body.
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

-- ----------------------------------------------------------------------------
-- rpc_cancel_order: mark payment_status 'refunded' when cash goes back
-- ----------------------------------------------------------------------------
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

  update public.orders
    set status = 'cancelled', cancelled_reason = btrim(p_reason),
        payment_status = case when v_order.paid_amount > 0 then 'refunded' else payment_status end
    where id = p_order_id;
  perform public.notify_user(v_order.customer_id, 'order_status', 'تم إلغاء طلبك', btrim(p_reason),
    jsonb_build_object('order_id', p_order_id, 'status', 'cancelled'));
end;
$$;

select private.apply_function_grants();
