-- ============================================================================
-- 0059_dual_cashbox_cash_transfer.sql
--
-- Splits the single till into two: a cash cashbox (physical money) and a
-- transfer cashbox (money moved by bank transfer/card) — every money-moving
-- RPC now credits/debits whichever one actually matches how the money moved,
-- instead of always "the" one active cashbox.
--
-- Deliberately NOT touched: InstaPay (0039/0040). rpc_admin_verify_instapay
-- has an explicit, considered comment that InstaPay money must never post to
-- cash_transactions — that ledger was scoped to the physical till on
-- purpose, and its refund path (wallet store credit) is a different
-- mechanism again. Folding InstaPay into the transfer cashbox is a bigger,
-- separate decision than "split cash from transfer" and isn't made here.
--
-- Mapping used everywhere below: payment_method 'cash' -> kind 'cash';
-- 'card'/'transfer' -> kind 'transfer'. A technician handing in cash is
-- always physical money by definition, so rpc_technician_supply stays on
-- 'cash' unconditionally — no signature change needed there.
-- ============================================================================

-- Guarded (if not exists / where not exists) throughout this section: live
-- drift discovered 2026-09-19 showed this had already been partially
-- applied out-of-band (ad hoc SQL, never through `db push`) — both
-- cashboxes already existed with the right `kind`. The original
-- unconditional `update ... set kind = 'cash'` that followed the ADD
-- COLUMN is dropped entirely on replay: it was already redundant even on
-- a fresh run (ADD COLUMN ... NOT NULL DEFAULT 'cash' already backfills
-- every pre-existing row), and on a replay it would silently reset the
-- transfer cashbox's kind back to 'cash', which the original file being
-- rerun verbatim would have done.
alter table public.cashboxes add column if not exists kind text not null default 'cash' check (kind in ('cash', 'transfer'));

insert into public.cashboxes (name, kind, is_active)
select 'خزنة التحويلات', 'transfer', true
where not exists (select 1 from public.cashboxes where kind = 'transfer');

-- At most one active cashbox per kind — mirrors every existing
-- "where is_active limit 1" lookup now needing "and kind = ...", and keeps
-- that assumption actually true.
create unique index if not exists idx_cashboxes_one_active_per_kind on public.cashboxes (kind) where is_active;

create or replace view public.cashbox_balances
  with (security_invoker = true) as
select
  cb.id as cashbox_id,
  cb.name,
  coalesce(sum(ct.amount), 0)::numeric(14,2) as balance,
  cb.kind
from public.cashboxes cb
left join public.cash_transactions ct on ct.cashbox_id = cb.id
group by cb.id, cb.name, cb.kind;

-- ----------------------------------------------------------------------------
-- rpc_admin_walk_in_sale: credit whichever till matches the payment method.
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
-- fn_return_sale_item (0058): refund into the same till the sale's own
-- payment_method credited, not "the" active cashbox.
-- ----------------------------------------------------------------------------
create or replace function private.fn_return_sale_item(p_sale_item_id uuid, p_quantity int, p_reason text)
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
begin
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

    insert into public.stock_movements (
      product_id, movement_type, quantity, from_location_type, to_location_type,
      to_location_id, unit_cost, reference_type, reference_id, notes, created_by
    ) values (
      v_item.product_id, 'return_from_customer', p_quantity, 'external', 'warehouse',
      v_warehouse_id, v_item.unit_cost_snapshot, 'sale', v_sale.id, btrim(p_reason), auth.uid()
    );
  end if;

  v_gross := v_item.unit_price_snapshot * p_quantity;
  v_line_discount_share := v_item.discount * p_quantity / v_item.quantity;
  v_pre_sale_discount := v_gross - v_line_discount_share;
  v_sale_discount_share := case when v_sale.subtotal > 0
    then v_sale.discount * v_pre_sale_discount / v_sale.subtotal else 0 end;
  v_refund := round(v_pre_sale_discount - v_sale_discount_share, 2);

  if v_refund > 0 then
    v_kind := case when v_sale.payment_method = 'cash' then 'cash' else 'transfer' end;
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

  select coalesce(sum(quantity - returned_quantity), 0) into v_remaining_on_sale
    from public.sale_items_with_returns where sale_id = v_sale.id;

  if v_remaining_on_sale = 0 then
    update public.sales set status = 'returned' where id = v_sale.id;
  end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- rpc_record_customer_payment: admin/sales now says which till a manually
-- recorded order payment landed in. New trailing parameter -> new
-- signature, so the old one is dropped explicitly (the exact mistake found
-- and fixed in 0050/0053 for the cart RPCs is not repeating here).
-- ----------------------------------------------------------------------------
drop function if exists public.rpc_record_customer_payment(uuid, numeric, uuid, text, uuid);

create or replace function public.rpc_record_customer_payment(
  p_customer_id uuid, p_amount numeric, p_order_id uuid, p_notes text,
  p_client_request_id uuid default null, p_payment_method payment_method default 'cash'
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_cashbox_id uuid;
  v_existing record;
  v_kind text;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then
    raise exception 'INVALID_AMOUNT';
  end if;
  if p_payment_method is null or p_payment_method = 'deferred' then
    raise exception 'DEFERRED_NOT_SUPPORTED';
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

  v_kind := case when p_payment_method = 'cash' then 'cash' else 'transfer' end;
  select id into v_cashbox_id from public.cashboxes where kind = v_kind and is_active limit 1;
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
-- fn_apply_order_refund: the "physical till" portion is no longer a single
-- guessed number — it reverses exactly the cash_transactions rows this
-- order actually posted, per cashbox, so a manually-recorded payment always
-- refunds back into the same till it came from (no re-asking needed, and
-- correct even if an order somehow mixed cash and transfer payments).
-- ----------------------------------------------------------------------------
create or replace function private.fn_apply_order_refund(p_order_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_wallet_paid numeric(12,2);
  v_instapay_paid numeric(12,2);
  v_gateway_paid numeric(12,2);
  v_wallet record;
  v_till_row record;
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

  -- Every manually-recorded payment (rpc_record_customer_payment) posted an
  -- exact cash_transactions row to a specific till; reverse each one
  -- exactly rather than guessing a single channel.
  for v_till_row in
    select cashbox_id, sum(amount) as amount from public.cash_transactions
    where reference_type = 'order' and reference_id = p_order_id and transaction_type = 'sale'
    group by cashbox_id
  loop
    if v_till_row.amount > 0 then
      select coalesce(sum(amount), 0) into v_balance
        from public.cash_transactions where cashbox_id = v_till_row.cashbox_id;
      if v_till_row.amount > v_balance then
        raise exception 'INSUFFICIENT_CASH: %', v_balance;
      end if;

      insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
      values (v_till_row.cashbox_id, 'refund', -v_till_row.amount, 'order', p_order_id, btrim(p_reason), auth.uid());

      insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
      values (v_order.customer_id, 'adjustment', v_till_row.amount, p_order_id, btrim(p_reason), auth.uid());
    end if;
  end loop;
end;
$$;

-- ----------------------------------------------------------------------------
-- rpc_cashbox_deposit / rpc_cashbox_withdraw / rpc_record_expense: which
-- till, chosen explicitly rather than assumed. New trailing parameters ->
-- new signatures, old ones dropped explicitly.
-- ----------------------------------------------------------------------------
drop function if exists public.rpc_cashbox_deposit(numeric, text);

create or replace function public.rpc_cashbox_deposit(
  p_amount numeric, p_notes text, p_kind text default 'cash'
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_cashbox_id uuid;
  v_txn_id uuid;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;
  if p_kind not in ('cash', 'transfer') then raise exception 'INVALID_INPUT'; end if;

  select id into v_cashbox_id from public.cashboxes where kind = p_kind and is_active limit 1;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

  insert into public.cash_transactions
    (cashbox_id, transaction_type, amount, reference_type, notes, created_by)
  values
    (v_cashbox_id, 'other_income', p_amount, 'manual_deposit',
     coalesce(nullif(btrim(p_notes), ''), 'إيداع نقدي'), auth.uid())
  returning id into v_txn_id;

  return v_txn_id;
end;
$$;

drop function if exists public.rpc_cashbox_withdraw(numeric, text);

create or replace function public.rpc_cashbox_withdraw(
  p_amount numeric, p_notes text, p_kind text default 'cash'
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_cashbox_id uuid;
  v_balance numeric(14,2);
  v_txn_id uuid;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;
  if p_kind not in ('cash', 'transfer') then raise exception 'INVALID_INPUT'; end if;

  select id into v_cashbox_id from public.cashboxes where kind = p_kind and is_active limit 1 for update;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

  select coalesce(sum(amount), 0) into v_balance
    from public.cash_transactions where cashbox_id = v_cashbox_id;

  if p_amount > v_balance then
    raise exception 'INSUFFICIENT_CASH: %', v_balance;
  end if;

  insert into public.cash_transactions
    (cashbox_id, transaction_type, amount, reference_type, notes, created_by)
  values
    (v_cashbox_id, 'other_expense', -p_amount, 'manual_withdrawal',
     coalesce(nullif(btrim(p_notes), ''), 'سحب نقدي'), auth.uid())
  returning id into v_txn_id;

  return v_txn_id;
end;
$$;

drop function if exists public.rpc_record_expense(uuid, numeric, date, text, text);

create or replace function public.rpc_record_expense(
  p_category_id uuid, p_amount numeric, p_expense_date date, p_notes text, p_attachment_url text,
  p_kind text default 'cash'
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_expense_id uuid;
  v_cashbox_id uuid;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;
  if p_kind not in ('cash', 'transfer') then raise exception 'INVALID_INPUT'; end if;

  select id into v_cashbox_id from public.cashboxes where kind = p_kind and is_active limit 1;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

  insert into public.expenses (category_id, amount, expense_date, notes, attachment_url, created_by)
  values (p_category_id, p_amount, coalesce(p_expense_date, current_date), p_notes, p_attachment_url, auth.uid())
  returning id into v_expense_id;

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  values (v_cashbox_id, 'expense', -p_amount, 'expense', v_expense_id, p_notes, auth.uid());

  return v_expense_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- post_technician_supply: a technician handing in cash is always physical
-- money — pin it to the cash till explicitly instead of "the" active one.
-- ----------------------------------------------------------------------------
create or replace function public.post_technician_supply(p_supply_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_supply record;
  v_cashbox_id uuid;
begin
  select * into v_supply from public.technician_supplies where id = p_supply_id;

  select id into v_cashbox_id from public.cashboxes where kind = 'cash' and is_active limit 1;
  if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

  insert into public.technician_account_transactions (technician_id, transaction_type, amount, supply_id, notes, created_by)
  values (v_supply.technician_id, 'supply_debit', v_supply.amount, v_supply.id, 'توريد للخزنة', auth.uid());

  insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
  values (v_cashbox_id, 'technician_deposit', v_supply.amount, 'technician_supply', v_supply.id, v_supply.notes, auth.uid());
end;
$$;

select private.apply_function_grants();
notify pgrst, 'reload schema';
