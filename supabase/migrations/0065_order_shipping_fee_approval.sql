-- ============================================================================
-- 0065_order_shipping_fee_approval.sql
--
-- New requirement (owner, 2026-09-22): admin/sales must set a shipping fee
-- on every order while it's still "قيد المراجعة" (pending) — an order can
-- no longer be confirmed without one — and the customer must explicitly
-- agree to it before the order is allowed to proceed.
--
-- Design: shipping_fee + shipping_fee_status ('not_set' | 'pending_approval'
-- | 'approved' | 'rejected') on orders. `total` only ever includes the fee
-- once it's actually approved — while it's merely proposed (or was
-- rejected), the customer's displayed total stays unchanged, matching "the
-- customer must agree before it counts". Rejecting keeps the rejected
-- amount + reason visible (not nulled out) so admin/sales can see exactly
-- what was turned down before proposing a different number.
--
-- `total` is a generated column; Postgres has no ALTER ... expression, so
-- it's dropped and re-added. Confirmed no view/RPC references orders.total
-- directly (only ever read via `select`/`v_order.total` inside functions,
-- which keep working unchanged against the new formula).
-- ============================================================================

alter table public.orders
  add column if not exists shipping_fee numeric(12,2) check (shipping_fee is null or shipping_fee >= 0),
  add column if not exists shipping_fee_status text not null default 'not_set'
    check (shipping_fee_status in ('not_set', 'pending_approval', 'approved', 'rejected')),
  add column if not exists shipping_fee_rejection_reason text,
  add column if not exists shipping_fee_set_by uuid references public.users(id),
  add column if not exists shipping_fee_set_at timestamptz,
  add column if not exists shipping_fee_responded_at timestamptz;

alter table public.orders drop column total;
alter table public.orders add column total numeric(12,2) generated always as (
  subtotal - discount + case when shipping_fee_status = 'approved' then coalesce(shipping_fee, 0) else 0 end
) stored;

-- ----------------------------------------------------------------------------
-- rpc_admin_set_shipping_fee: admin/sales proposes (or re-proposes, after a
-- rejection) a shipping fee while the order is still pending.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_admin_set_shipping_fee(p_order_id uuid, p_amount numeric)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_customer_id uuid;
  v_order_number bigint;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount < 0 or p_amount <> round(p_amount, 2) then
    raise exception 'INVALID_AMOUNT';
  end if;

  select customer_id, order_number into v_customer_id, v_order_number
    from public.orders where id = p_order_id and status = 'pending' for update;
  if v_customer_id is null then raise exception 'ORDER_NOT_PENDING'; end if;

  update public.orders set
    shipping_fee = p_amount,
    shipping_fee_status = 'pending_approval',
    shipping_fee_rejection_reason = null,
    shipping_fee_set_by = auth.uid(),
    shipping_fee_set_at = now(),
    shipping_fee_responded_at = null
  where id = p_order_id;

  perform public.notify_user(v_customer_id, 'shipping_fee', 'تكلفة شحن طلبك',
    format('تكلفة شحن طلبك رقم #%s هي %s ج.م — يرجى الموافقة لإتمام الطلب', v_order_number, p_amount),
    jsonb_build_object('order_id', p_order_id, 'shipping_fee', p_amount));
end;
$$;

-- ----------------------------------------------------------------------------
-- rpc_customer_respond_shipping_fee: the customer's own order only, and
-- only while a fee is actually awaiting their answer.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_customer_respond_shipping_fee(
  p_order_id uuid, p_approve boolean, p_rejection_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  if p_approve is null then raise exception 'INVALID_INPUT'; end if;
  if not p_approve and (p_rejection_reason is null or btrim(p_rejection_reason) = '') then
    raise exception 'REASON_REQUIRED';
  end if;
  if length(p_rejection_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.customer_id <> auth.uid() then raise exception 'ORDER_CUSTOMER_MISMATCH'; end if;
  if v_order.shipping_fee_status <> 'pending_approval' then
    raise exception 'SHIPPING_FEE_NOT_PENDING';
  end if;

  if p_approve then
    update public.orders set
      shipping_fee_status = 'approved',
      shipping_fee_responded_at = now()
    where id = p_order_id;
    perform public.notify_all_admins('shipping_fee', 'العميل وافق على سعر الشحن',
      format('طلب #%s — العميل وافق على %s ج.م شحن', v_order.order_number, v_order.shipping_fee),
      jsonb_build_object('order_id', p_order_id));
  else
    update public.orders set
      shipping_fee_status = 'rejected',
      shipping_fee_rejection_reason = btrim(p_rejection_reason),
      shipping_fee_responded_at = now()
    where id = p_order_id;
    perform public.notify_all_admins('shipping_fee', 'العميل رفض سعر الشحن',
      format('طلب #%s — رفض %s ج.م شحن: %s', v_order.order_number, v_order.shipping_fee, btrim(p_rejection_reason)),
      jsonb_build_object('order_id', p_order_id));
  end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- rpc_confirm_order: now also gated on an approved shipping fee.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_confirm_order(p_order_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_warehouse_id uuid;
  v_item record;
  v_customer_id uuid;
  v_total numeric(12,2);
  v_shipping_fee_status text;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  select customer_id, total, shipping_fee_status into v_customer_id, v_total, v_shipping_fee_status
    from public.orders where id = p_order_id and status = 'pending' for update;
  if v_customer_id is null then raise exception 'ORDER_NOT_PENDING'; end if;
  if v_shipping_fee_status <> 'approved' then raise exception 'SHIPPING_FEE_NOT_APPROVED'; end if;

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

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_admin_set_shipping_fee', 'admin/sales'),
  ('rpc_customer_respond_shipping_fee', 'customer')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
