-- ============================================================================
-- 0058_partial_sale_item_returns.sql
--
-- Extends 0057: admin/sales can now open a walk-in sale's invoice and return
-- a single line item (any quantity up to what's left) or the whole invoice,
-- instead of only "the whole thing or nothing".
--
-- sale_items has trg_sale_items_no_update (0005) — it is an immutable
-- ledger row, same as stock_movements/cash_transactions/wallet_transactions
-- elsewhere in this schema, so "how much of this line has been returned"
-- cannot live as a mutable column on it. Tracked instead as its own
-- append-only ledger, sale_item_returns, one row per return event; "how
-- much is left" is always a SUM over it, computed at read time — the same
-- pattern every other running balance in this schema already uses.
--
-- Refund math for a partial line return prorates BOTH the per-line discount
-- and the sale-level discount (rpc_admin_walk_in_sale has both), so a
-- return's refund always matches what that portion actually cost the
-- customer, not just qty * unit_price.
--
-- private.fn_return_sale_item does the real work; both RPCs below are thin
-- callers of it (one item, or every remaining item on the invoice).
-- ============================================================================

create table public.sale_item_returns (
  id uuid primary key default gen_random_uuid(),
  sale_item_id uuid not null references public.sale_items(id),
  quantity int not null check (quantity > 0),
  refund_amount numeric(12,2) not null check (refund_amount >= 0),
  reason text not null,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);
create index idx_sale_item_returns_item on public.sale_item_returns (sale_item_id);

alter table public.sale_item_returns enable row level security;
create trigger trg_sale_item_returns_no_update
  before update or delete on public.sale_item_returns
  for each row execute function public.prevent_mutation();

-- Same audience as sale_items_select below (admin/sales) — return history
-- is a staff concern, not exposed to the technician/customer views.
create policy sale_item_returns_select on public.sale_item_returns for select to authenticated
  using (public.is_admin() or public.is_sales());

-- sale_items_select (0029) never had is_sales() — needed now for the
-- returns screen, same as sales_select already widened in 0057.
alter policy sale_items_select on public.sale_items
  using (
    public.is_admin()
    or public.is_sales()
    or sale_id in (select s.id from public.sales s where s.technician_id = auth.uid())
  );

-- "Remaining" is always current_quantity minus every return on record —
-- exposed here so the app never has to compute the aggregate itself.
create view public.sale_items_with_returns
  with (security_invoker = true) as
select si.*, coalesce(sr.total_returned, 0)::int as returned_quantity
from public.sale_items si
left join (
  select sale_item_id, sum(quantity) as total_returned
  from public.sale_item_returns group by sale_item_id
) sr on sr.sale_item_id = si.id;

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

  -- Prorate both the line's own discount and the invoice-level discount
  -- across the quantity actually being returned, so a partial return never
  -- over- or under-refunds relative to what the customer really paid.
  v_gross := v_item.unit_price_snapshot * p_quantity;
  v_line_discount_share := v_item.discount * p_quantity / v_item.quantity;
  v_pre_sale_discount := v_gross - v_line_discount_share;
  v_sale_discount_share := case when v_sale.subtotal > 0
    then v_sale.discount * v_pre_sale_discount / v_sale.subtotal else 0 end;
  v_refund := round(v_pre_sale_discount - v_sale_discount_share, 2);

  if v_refund > 0 then
    select id into v_cashbox_id from public.cashboxes where is_active limit 1 for update;
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
revoke all on function private.fn_return_sale_item(uuid, int, text) from public, anon, authenticated;

create or replace function public.rpc_return_sale_item(p_sale_item_id uuid, p_quantity int, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_reason is null or btrim(p_reason) = '' then raise exception 'REASON_REQUIRED'; end if;
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;
  perform private.fn_return_sale_item(p_sale_item_id, p_quantity, p_reason);
end;
$$;

-- Whole-invoice return, now aware of lines already partially returned
-- (e.g. one item returned earlier, then the rest of the invoice returned
-- at once) — every line's remaining quantity goes through the same helper.
create or replace function public.rpc_admin_return_sale(p_sale_id uuid, p_reason text)
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
      perform private.fn_return_sale_item(v_item.id, v_item.quantity - v_item.returned_quantity, p_reason);
    end if;
  end loop;
end;
$$;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_return_sale_item', 'admin/sales')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
