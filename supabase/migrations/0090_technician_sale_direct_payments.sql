-- ============================================================================
-- 0090_technician_sale_direct_payments.sql
--
-- A customer of a technician can pay by bank transfer or e-wallet straight
-- into the shop's own accounts. That money never passes through the
-- technician's hands, so:
--
--   * it goes into the 'transfer' (حساب CIB) / 'wallet' (فودافون كاش) till
--     the moment the sale is made;
--   * it is NOT added to what the technician owes («المطلوب توريده») —
--     only the cash he collected is;
--   * it counts as paid on the invoice (sales.paid_amount), so the sale no
--     longer shows as unpaid by the customer.
--
-- A customer can split it: 2000 = 1000 by transfer + 1000 cash to the
-- technician. sales.transfer_amount / wallet_amount record the direct part;
-- paid_amount = cash + transfer + wallet.
--
-- rpc_technician_sale takes p_transfer_amount / p_wallet_amount (default 0,
-- so an older app behaves exactly as before); p_paid_amount stays the cash
-- the technician collected.
--
-- Edits keep the direct part fixed — the money is already in the shop's
-- accounts — and settle only the technician's cash part; an invoice can't
-- go below what was transferred (TOTAL_BELOW_DIRECT_PAYMENT). Deleting an
-- invoice with a transfer refunds it from that account, admin only.
-- ============================================================================

alter table public.sales
  add column if not exists transfer_amount numeric(12,2) not null default 0,
  add column if not exists wallet_amount numeric(12,2) not null default 0;
alter table public.sales drop constraint if exists sales_direct_amounts_check;
alter table public.sales add constraint sales_direct_amounts_check
  check (transfer_amount >= 0 and wallet_amount >= 0);

-- ----------------------------------------------------------------------------
-- The sale. 0030's body with 0086's price branch, plus the direct amounts.
-- The old signature is dropped: two overloads would make PostgREST's
-- named-argument call ambiguous.
-- ----------------------------------------------------------------------------
drop function if exists public.rpc_technician_sale(uuid, uuid, text, text, jsonb, payment_method, numeric, numeric, uuid, text, uuid);

create or replace function public.rpc_technician_sale(
  p_technician_id uuid, p_customer_id uuid, p_customer_name text, p_customer_phone text,
  p_items jsonb, p_payment_method payment_method, p_discount numeric, p_paid_amount numeric,
  p_client_request_id uuid, p_notes text, p_maintenance_request_id uuid default null,
  p_transfer_amount numeric default 0, p_wallet_amount numeric default 0
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_sale_id uuid;
  v_sale_number bigint;
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
  v_transfer numeric(12,2) := coalesce(p_transfer_amount, 0);
  v_wallet numeric(12,2) := coalesce(p_wallet_amount, 0);
  v_subtotal numeric(12,2) := 0;
  v_total numeric(12,2);
  v_cashbox_id uuid;
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
  if v_paid < 0 or v_paid <> round(v_paid, 2)
     or v_transfer < 0 or v_transfer <> round(v_transfer, 2)
     or v_wallet < 0 or v_wallet <> round(v_wallet, 2) then
    raise exception 'INVALID_AMOUNT';
  end if;

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
    if v_paid > 0 or v_transfer > 0 or v_wallet > 0 then raise exception 'INVALID_AMOUNT'; end if;
  end if;

  select id into v_bag_id from public.technician_bags where technician_id = p_technician_id;
  if v_bag_id is null then raise exception 'TECHNICIAN_BAG_NOT_FOUND'; end if;

  begin
    insert into public.sales (technician_id, customer_id, customer_name, customer_phone, payment_method, discount, paid_amount, client_request_id, maintenance_request_id)
    values (p_technician_id, v_customer_id, nullif(btrim(p_customer_name), ''), nullif(btrim(p_customer_phone), ''),
            p_payment_method, v_discount, v_paid, p_client_request_id, p_maintenance_request_id)
    returning id, sale_number into v_sale_id, v_sale_number;
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
    elsif v_unit_price is null then
      v_unit_price := v_product.selling_price;
    elsif v_unit_price <= 0 or v_unit_price <> round(v_unit_price, 2) then
      raise exception 'INVALID_AMOUNT';
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
  if v_paid + v_transfer + v_wallet > v_total then raise exception 'PAYMENT_EXCEEDS_TOTAL'; end if;

  update public.sales
    set subtotal = v_subtotal,
        paid_amount = v_paid + v_transfer + v_wallet,
        transfer_amount = v_transfer,
        wallet_amount = v_wallet
    where id = v_sale_id;

  if p_payment_method = 'deferred' then
    insert into public.customer_account_transactions (customer_id, transaction_type, amount, notes, created_by)
    values (v_customer_id, 'order_charge', v_total, 'بيع صنايعي آجل', auth.uid());
  elsif v_paid > 0 then
    -- Only the cash in his hand is his to remit.
    insert into public.technician_account_transactions (technician_id, transaction_type, amount, sale_id, notes, created_by)
    values (p_technician_id, 'sale_credit', v_paid, v_sale_id, 'تحصيل بيع', auth.uid());
  end if;

  -- Transferred straight into the shop's accounts.
  if v_transfer > 0 then
    select id into v_cashbox_id from public.cashboxes where kind = 'transfer' and is_active limit 1;
    if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;
    insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
    values (v_cashbox_id, 'sale', v_transfer, 'sale', v_sale_id,
            'تحويل بنكي من عميل · فاتورة صنايعي #' || v_sale_number, auth.uid());
  end if;
  if v_wallet > 0 then
    select id into v_cashbox_id from public.cashboxes where kind = 'wallet' and is_active limit 1;
    if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;
    insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
    values (v_cashbox_id, 'sale', v_wallet, 'sale', v_sale_id,
            'تحويل محفظة من عميل · فاتورة صنايعي #' || v_sale_number, auth.uid());
  end if;

  return v_sale_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- Settling an edited / deleted technician invoice. 0088's body, worked out
-- on the technician's cash part only: the transferred part is fixed.
-- ----------------------------------------------------------------------------
create or replace function private.fn_tech_sale_settle(
  p_sale_id uuid, p_old_total numeric, p_old_paid numeric, p_note text
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_sale record;
  v_direct numeric(12,2);
  v_old_total numeric(12,2);
  v_old_cash numeric(12,2);
  v_new_total numeric(12,2);
  v_new_cash numeric(12,2);
  v_delta numeric(12,2);
  v_due numeric(14,2);
begin
  select * into v_sale from public.sales where id = p_sale_id for update;

  -- 1. A technician's own window; admin is not limited.
  if not public.is_admin() and v_sale.created_at < now() - interval '3 days' then
    raise exception 'EDIT_WINDOW_EXPIRED';
  end if;

  if v_sale.payment_method = 'deferred' then
    v_delta := v_sale.total - p_old_total;
    if v_delta <> 0 and v_sale.customer_id is not null then
      insert into public.customer_account_transactions (customer_id, transaction_type, amount, sale_id, notes, created_by)
      values (v_sale.customer_id, case when v_delta > 0 then 'order_charge' else 'return_credit' end::cust_txn_type,
              v_delta, p_sale_id, p_note, auth.uid());
    end if;
    return;
  end if;

  v_direct := v_sale.transfer_amount + v_sale.wallet_amount;
  if v_sale.total < v_direct then
    raise exception 'TOTAL_BELOW_DIRECT_PAYMENT: %', v_direct;
  end if;
  v_old_total := p_old_total - v_direct;
  v_old_cash := p_old_paid - v_direct;
  v_new_total := v_sale.total - v_direct;

  v_new_cash := case when v_old_cash >= v_old_total then v_new_total
                     else least(v_old_cash, v_new_total) end;
  v_delta := v_new_cash - v_old_cash;
  if v_delta > 0 then
    insert into public.technician_account_transactions (technician_id, transaction_type, amount, sale_id, notes, created_by)
    values (v_sale.technician_id, 'sale_credit', v_delta, p_sale_id, p_note, auth.uid());
  elsif v_delta < 0 then
    -- 2. What he still owes must cover the reduction.
    perform 1 from public.technicians where id = v_sale.technician_id for update;
    select coalesce(sum(case when transaction_type = 'supply_debit' then -amount else amount end), 0)
      into v_due
    from public.technician_account_transactions
    where technician_id = v_sale.technician_id;
    if v_due + v_delta < 0 then
      raise exception 'TECHNICIAN_DUE_NEGATIVE: %', greatest(v_due, 0);
    end if;

    insert into public.technician_account_transactions (technician_id, transaction_type, amount, sale_id, notes, created_by)
    values (v_sale.technician_id, 'adjustment', v_delta, p_sale_id, p_note, auth.uid());
  end if;
  update public.sales set paid_amount = v_new_cash + v_direct where id = p_sale_id;
end;
$$;
revoke all on function private.fn_tech_sale_settle(uuid, numeric, numeric, text) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- Deleting an invoice. 0087's body; a transferred part is refunded from the
-- account it went into first (admin only), then the cash part settles as
-- before.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_delete_technician_sale(p_sale_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_sale record;
  v_before jsonb;
  v_bag_id uuid;
  v_li record;
  v_reason text := coalesce(nullif(btrim(p_reason), ''), 'حذف فاتورة');
  v_note text;
  v_direct numeric(12,2);
  v_kind text;
  v_amount numeric(12,2);
  v_cashbox_id uuid;
  v_balance numeric(14,2);
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
  v_direct := v_sale.transfer_amount + v_sale.wallet_amount;

  if v_direct > 0 then
    -- Handing transferred money back is the shop's call, not the technician's.
    if not public.is_admin() then raise exception 'DIRECT_PAYMENT_ADMIN_ONLY'; end if;
    foreach v_kind in array array['transfer', 'wallet'] loop
      v_amount := case v_kind when 'transfer' then v_sale.transfer_amount else v_sale.wallet_amount end;
      continue when v_amount = 0;
      select id into v_cashbox_id from public.cashboxes where kind = v_kind and is_active limit 1 for update;
      if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;
      select coalesce(sum(amount), 0) into v_balance from public.cash_transactions where cashbox_id = v_cashbox_id;
      if v_amount > v_balance then raise exception 'INSUFFICIENT_CASH: %', v_balance; end if;
      insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
      values (v_cashbox_id, 'refund', -v_amount, 'sale', p_sale_id, v_note, auth.uid());
    end loop;
    update public.sales set transfer_amount = 0, wallet_amount = 0,
                            paid_amount = paid_amount - v_direct
      where id = p_sale_id;
  end if;

  select id into v_bag_id from public.technician_bags where technician_id = v_sale.technician_id;
  if v_bag_id is null then raise exception 'TECHNICIAN_BAG_NOT_FOUND'; end if;

  for v_li in
    select id, quantity - returned_quantity as left_qty
    from public.sale_items_with_returns where sale_id = p_sale_id and returned_quantity < quantity
  loop
    perform private.fn_tech_return_sale_item(v_li.id, v_li.left_qty, v_bag_id, v_note);
  end loop;

  -- Nothing is left on it: the whole total and (cash) payment are reversed.
  update public.sales set subtotal = 0, discount = 0 where id = p_sale_id;
  perform private.fn_tech_sale_settle(p_sale_id, (v_before ->> 'total')::numeric - v_direct,
                                      (v_before ->> 'paid_amount')::numeric - v_direct, v_note);

  update public.sales set status = 'cancelled', maintenance_request_id = null where id = p_sale_id;

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'TECHNICIAN_SALE_DELETED', 'sales', p_sale_id, v_before,
          (select to_jsonb(s) from public.sales s where s.id = p_sale_id));
end;
$$;

select private.apply_function_grants();
notify pgrst, 'reload schema';
