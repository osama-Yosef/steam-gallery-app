-- ============================================================================
-- 0041_refunds.sql  (Phase 14 — refunds)
--
-- Bug fixed here: rpc_cancel_order (0037) always refunded the ENTIRE
-- paid_amount out of the physical cashbox, assuming every order was paid in
-- cash. That stopped being true once InstaPay (Phase 12) and the wallet
-- (Phase 13) existed — an order paid via wallet or InstaPay never put money
-- in the cashbox, so refunding it from there would either wrongly drain a
-- cashbox that never received it, or fail with INSUFFICIENT_CASH for money
-- that was never physical cash to begin with. Money paid through the wallet
-- or InstaPay must go back through that same channel, not the cashbox.
--
-- private.fn_apply_order_refund is the one place that now knows how to undo
-- a payment, split by the channel it actually came through:
--   * wallet    -> credited back to the customer's wallet
--                  (wallet_transactions.type = 'refund_credit', reserved for
--                  this since 0040 but unused until now).
--   * instapay  -> credited to the wallet as store credit. There is no
--                  automated bank reversal for a manual InstaPay transfer
--                  (Phase 12 is a one-way "customer transfers, admin
--                  verifies" flow) - crediting the wallet is the same
--                  mechanism the business already uses to hand a customer
--                  money back without touching physical cash.
--   * gateway   -> not reachable yet (Phase 11 is not wired up); guarded so
--                  it fails loudly instead of silently mis-refunding if it
--                  ever is.
--   * anything else (the manually-recorded cash portion from
--     rpc_record_customer_payment, which never creates a `payments` row) ->
--     the existing physical cashbox refund, unchanged.
--
-- Both call sites (rpc_cancel_order for pre-fulfilment cancellation, and the
-- new rpc_admin_return_order for a post-delivery return) share this one
-- function, so there is exactly one place that reasons about "where did
-- this money actually come from".
--
-- Scope note: this refunds a cancelled/returned ORDER as a whole (full
-- paid_amount), matching the order_status/payment_status model that already
-- exists. Partial, per-item returns would need per-item return-quantity
-- tracking that does not exist anywhere in the schema yet - out of scope
-- here, left for a future phase if the business needs it.
-- ============================================================================

create or replace function private.fn_apply_order_refund(p_order_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_wallet_paid numeric(12,2);
  v_instapay_paid numeric(12,2);
  v_gateway_paid numeric(12,2);
  v_cash_paid numeric(12,2);
  v_wallet record;
  v_cashbox_id uuid;
  v_balance numeric(14,2);
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.paid_amount <= 0 then return; end if;

  select coalesce(sum(amount), 0) into v_wallet_paid
    from public.payments where order_id = p_order_id and channel = 'wallet' and status = 'succeeded';
  select coalesce(sum(amount), 0) into v_instapay_paid
    from public.payments where order_id = p_order_id and channel = 'instapay' and status = 'succeeded';
  select coalesce(sum(amount), 0) into v_gateway_paid
    from public.payments where order_id = p_order_id and channel = 'gateway' and status = 'succeeded';
  v_cash_paid := greatest(0, v_order.paid_amount - v_wallet_paid - v_instapay_paid - v_gateway_paid);

  if v_gateway_paid > 0 then
    raise exception 'GATEWAY_REFUND_NOT_IMPLEMENTED';
  end if;

  if v_wallet_paid > 0 then
    insert into public.wallets (customer_id) values (v_order.customer_id)
    on conflict (customer_id, currency) do nothing;
    select * into v_wallet from public.wallets
      where customer_id = v_order.customer_id and currency = 'EGP' for update;

    insert into public.wallet_transactions (
      wallet_id, type, amount, balance_before, balance_after,
      reference_type, reference_id, notes, created_by
    ) values (
      v_wallet.id, 'refund_credit', v_wallet_paid, v_wallet.balance, v_wallet.balance + v_wallet_paid,
      'order', p_order_id, btrim(p_reason), auth.uid()
    );
    update public.wallets set balance = balance + v_wallet_paid where id = v_wallet.id;

    update public.payments set status = 'refunded'
      where order_id = p_order_id and channel = 'wallet' and status = 'succeeded';
  end if;

  if v_instapay_paid > 0 then
    insert into public.wallets (customer_id) values (v_order.customer_id)
    on conflict (customer_id, currency) do nothing;
    select * into v_wallet from public.wallets
      where customer_id = v_order.customer_id and currency = 'EGP' for update;

    insert into public.wallet_transactions (
      wallet_id, type, amount, balance_before, balance_after,
      reference_type, reference_id, notes, created_by
    ) values (
      v_wallet.id, 'refund_credit', v_instapay_paid, v_wallet.balance, v_wallet.balance + v_instapay_paid,
      'order', p_order_id, 'استرداد تحويل InstaPay إلى رصيد المحفظة: ' || btrim(p_reason), auth.uid()
    );
    update public.wallets set balance = balance + v_instapay_paid where id = v_wallet.id;

    update public.payments set status = 'refunded'
      where order_id = p_order_id and channel = 'instapay' and status = 'succeeded';
  end if;

  if v_cash_paid > 0 then
    select id into v_cashbox_id from public.cashboxes where is_active limit 1 for update;
    if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

    select coalesce(sum(amount), 0) into v_balance
      from public.cash_transactions where cashbox_id = v_cashbox_id;
    if v_cash_paid > v_balance then
      raise exception 'INSUFFICIENT_CASH: %', v_balance;
    end if;

    insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
    values (v_cashbox_id, 'refund', -v_cash_paid, 'order', p_order_id, btrim(p_reason), auth.uid());

    insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
    values (v_order.customer_id, 'adjustment', v_cash_paid, p_order_id, btrim(p_reason), auth.uid());
  end if;
end;
$$;

revoke all on function private.fn_apply_order_refund(uuid, text) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- rpc_cancel_order: same signature as 0037/0010 - only the refund block
-- changes, from "always the cashbox" to private.fn_apply_order_refund.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_cancel_order(p_order_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_warehouse_id uuid;
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

  perform private.fn_apply_order_refund(p_order_id, p_reason);

  update public.orders
    set status = 'cancelled', cancelled_reason = btrim(p_reason),
        payment_status = case when v_order.paid_amount > 0 then 'refunded' else payment_status end
    where id = p_order_id;
  perform public.notify_user(v_order.customer_id, 'order_status', 'تم إلغاء طلبك', btrim(p_reason),
    jsonb_build_object('order_id', p_order_id, 'status', 'cancelled'));
end;
$$;

-- ----------------------------------------------------------------------------
-- rpc_admin_return_order: the post-delivery counterpart to rpc_cancel_order.
-- Admin-only, same as every other order-state-changing RPC in this project.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_admin_return_order(p_order_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_warehouse_id uuid;
  v_item record;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
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

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_admin_return_order', 'admin')
on conflict (function_name) do nothing;

select private.apply_function_grants();
