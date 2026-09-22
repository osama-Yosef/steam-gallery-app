-- ============================================================================
-- 0063_sale_return_refund_kind_choice.sql
--
-- 0059 made a sale return refund the same till the sale's own payment_method
-- credited (cash sale -> cash till, card/transfer sale -> transfer till),
-- decided automatically with no way to override it. Reported live: an item
-- returned on an invoice appeared to not deduct any money, because the
-- refund landed in a cashbox the person doing the return wasn't looking at.
-- The register is a physical/logical split the staff can see (cash drawer
-- vs. bank), so the return screen should ask -- same as deposit/withdraw/
-- expense already do via an explicit p_kind (0059) -- rather than infer it
-- silently from a column nobody at the till is looking at.
--
-- private.fn_return_sale_item now takes an explicit p_refund_kind ('cash' |
-- 'transfer'). It stays optional (default null, falls back to the old
-- payment_method-derived guess) so any other internal caller keeps working,
-- but both public entry points always pass it through from the app now.
-- ============================================================================

create or replace function private.fn_return_sale_item(
  p_sale_item_id uuid, p_quantity int, p_reason text, p_refund_kind text default null
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

  select coalesce(sum(quantity - returned_quantity), 0) into v_remaining_on_sale
    from public.sale_items_with_returns where sale_id = v_sale.id;

  if v_remaining_on_sale = 0 then
    update public.sales set status = 'returned' where id = v_sale.id;
  end if;
end;
$$;

-- New trailing parameter -> new signature -> a second overload, not a
-- replacement (the exact mistake found and fixed in 0050/0053 for the cart
-- RPCs). Drop the old 3-arg signatures explicitly before recreating.
drop function if exists public.rpc_return_sale_item(uuid, int, text);

create or replace function public.rpc_return_sale_item(
  p_sale_item_id uuid, p_quantity int, p_reason text, p_refund_kind text default null
)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_reason is null or btrim(p_reason) = '' then raise exception 'REASON_REQUIRED'; end if;
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;
  perform private.fn_return_sale_item(p_sale_item_id, p_quantity, p_reason, p_refund_kind);
end;
$$;

drop function if exists public.rpc_admin_return_sale(uuid, text);

create or replace function public.rpc_admin_return_sale(
  p_sale_id uuid, p_reason text, p_refund_kind text default null
)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_sale record;
  v_item record;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_reason is null or btrim(p_reason) = '' then raise exception 'REASON_REQUIRED'; end if;
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_sale from public.sales where id = p_sale_id;
  if not found then raise exception 'SALE_NOT_FOUND'; end if;
  if v_sale.technician_id is not null then raise exception 'NOT_A_WALK_IN_SALE'; end if;
  if v_sale.status <> 'completed' then raise exception 'SALE_NOT_RETURNABLE'; end if;

  for v_item in select * from public.sale_items_with_returns where sale_id = p_sale_id
  loop
    if v_item.returned_quantity < v_item.quantity then
      perform private.fn_return_sale_item(v_item.id, v_item.quantity - v_item.returned_quantity, p_reason, p_refund_kind);
    end if;
  end loop;
end;
$$;

select private.apply_function_grants();
notify pgrst, 'reload schema';
