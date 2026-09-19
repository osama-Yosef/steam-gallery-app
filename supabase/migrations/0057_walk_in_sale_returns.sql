-- ============================================================================
-- 0057_walk_in_sale_returns.sql
--
-- New capability: returning a completed walk-in sale ("بيع مباشر"). Order
-- returns already exist (rpc_admin_return_order, 0041); sale returns never
-- did — sale_status even had a 'returned' value since 0001 that nothing
-- ever wrote.
--
-- Scoped to walk-in sales only (technician_id is null — rpc_admin_walk_in_sale
-- always inserts null there, 0044), matching what was asked for. A
-- technician's own field sale (technician_id set) is refused here on
-- purpose: reversing one would also need to reverse the technician's
-- amount-due credit (tech_txn_type 'sale_credit'), a different and untested
-- code path — out of scope.
--
-- Mirrors rpc_admin_walk_in_sale's own effects in reverse:
--   * stock: every non-service line's 'sale' movement gets a matching
--     'return_from_customer' movement back into the main warehouse.
--   * cash: walk-in sales always credit the till in full regardless of
--     payment_method (deferred is refused at sale time) — refunding is
--     always a cash-till reversal, same as fn_apply_order_refund's cash
--     branch, INSUFFICIENT_CASH guarded the same way.
--   * status -> 'returned'.
-- ============================================================================

create or replace function public.rpc_admin_return_sale(p_sale_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_sale record;
  v_warehouse_id uuid;
  v_cashbox_id uuid;
  v_balance numeric(14,2);
  v_item record;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
  if p_reason is null or btrim(p_reason) = '' then raise exception 'REASON_REQUIRED'; end if;
  if length(p_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_sale from public.sales where id = p_sale_id for update;
  if not found then raise exception 'SALE_NOT_FOUND'; end if;
  if v_sale.technician_id is not null then raise exception 'NOT_A_WALK_IN_SALE'; end if;
  if v_sale.status <> 'completed' then raise exception 'SALE_NOT_RETURNABLE'; end if;

  select id into v_warehouse_id from public.warehouses where type = 'main' and is_active limit 1;
  if v_warehouse_id is null then raise exception 'NO_MAIN_WAREHOUSE'; end if;

  for v_item in
    select si.*, p.is_service from public.sale_items si
    join public.products p on p.id = si.product_id
    where si.sale_id = p_sale_id
  loop
    if not v_item.is_service then
      insert into public.stock_movements (
        product_id, movement_type, quantity, from_location_type, to_location_type,
        to_location_id, unit_cost, reference_type, reference_id, notes, created_by
      ) values (
        v_item.product_id, 'return_from_customer', v_item.quantity, 'external', 'warehouse',
        v_warehouse_id, v_item.unit_cost_snapshot, 'sale', p_sale_id, btrim(p_reason), auth.uid()
      );
    end if;
  end loop;

  if v_sale.paid_amount > 0 then
    select id into v_cashbox_id from public.cashboxes where is_active limit 1 for update;
    if v_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

    select coalesce(sum(amount), 0) into v_balance
      from public.cash_transactions where cashbox_id = v_cashbox_id;
    if v_sale.paid_amount > v_balance then
      raise exception 'INSUFFICIENT_CASH: %', v_balance;
    end if;

    insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
    values (v_cashbox_id, 'refund', -v_sale.paid_amount, 'sale', p_sale_id, btrim(p_reason), auth.uid());
  end if;

  update public.sales set status = 'returned' where id = p_sale_id;

  insert into public.audit_logs (actor_id, action, table_name, record_id, old_data, new_data)
  values (auth.uid(), 'SALE_RETURNED', 'sales', p_sale_id, to_jsonb(v_sale),
          (select to_jsonb(s) from public.sales s where s.id = p_sale_id));
end;
$$;

-- Walk-in sales list needs to be readable for the returns screen. Extending
-- 0027's actual policy (admin / own technician / own customer / own
-- maintenance invoice) with is_sales() — every other clause kept as-is, not
-- guessed at, so a customer's visibility into their own maintenance
-- invoice doesn't regress.
alter policy sales_select on public.sales
  using (
    public.is_admin()
    or public.is_sales()
    or technician_id = auth.uid()
    or customer_id = auth.uid()
    or maintenance_request_id in (
      select id from public.maintenance_requests where customer_id = auth.uid()
    )
  );

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_admin_return_sale', 'admin/sales')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
