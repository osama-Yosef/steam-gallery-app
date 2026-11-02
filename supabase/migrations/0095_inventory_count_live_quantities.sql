-- ============================================================================
-- 0095_inventory_count_live_quantities.sql
--
-- Bug (seen live 2026-11-02): a count's "بالنظام" quantity was the stock at
-- the moment the count was started, and stayed so. A count left open while
-- the shop kept selling (or, since 0094, moving stock to a bag) showed the
-- warehouse at 44 and the count at 45 — and approving it would have applied
-- the difference against the old figure, so the stock would have ended
-- wrong.
--
-- Now a line's system quantity is the stock at the time it is counted:
--
--   * rpc_save_inventory_count_item takes the current stock as the line's
--     system quantity before comparing it with what was counted, so the
--     shortage/surplus (and the reason it needs) is against today's stock.
--     A sale after that is not mistaken for a shortage at approval, because
--     approval still applies the difference saved with the line.
--   * rpc_refresh_inventory_count brings every line not counted yet up to
--     the current stock, and adds products that came into the place since
--     the count started. The app calls it each time it opens a draft;
--     rpc_start_inventory_count calls it when it reopens one.
--
-- Lines already counted keep what was saved — re-enter one to compare it
-- with today's stock.
-- ============================================================================

-- What [p_location] holds of [p_product_id] right now.
create or replace function private.fn_location_quantity(
  p_location_type location_type, p_location_id uuid, p_product_id uuid
) returns int language sql stable security definer set search_path = public as $$
  select coalesce(case p_location_type
    when 'warehouse' then (select quantity from public.warehouse_stock
                           where warehouse_id = p_location_id and product_id = p_product_id)
    else (select quantity from public.technician_bag_stock
          where technician_bag_id = p_location_id and product_id = p_product_id)
  end, 0);
$$;
revoke all on function private.fn_location_quantity(location_type, uuid, uuid) from public, anon, authenticated;

create or replace function private.fn_refresh_count(p_count_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_count record;
begin
  select * into v_count from public.inventory_counts where id = p_count_id and status = 'draft' for update;
  if v_count.id is null then return; end if;

  update public.inventory_count_items i
    set system_quantity = private.fn_location_quantity(v_count.location_type, v_count.location_id, i.product_id)
    where i.inventory_count_id = p_count_id and i.actual_quantity is null;

  if v_count.location_type = 'warehouse' then
    insert into public.inventory_count_items (inventory_count_id, product_id, system_quantity)
    select p_count_id, ws.product_id, ws.quantity from public.warehouse_stock ws
    where ws.warehouse_id = v_count.location_id and ws.quantity > 0
      and not exists (select 1 from public.inventory_count_items i
                      where i.inventory_count_id = p_count_id and i.product_id = ws.product_id);
  else
    insert into public.inventory_count_items (inventory_count_id, product_id, system_quantity)
    select p_count_id, bs.product_id, bs.quantity from public.technician_bag_stock bs
    where bs.technician_bag_id = v_count.location_id and bs.quantity > 0
      and not exists (select 1 from public.inventory_count_items i
                      where i.inventory_count_id = p_count_id and i.product_id = bs.product_id);
  end if;
end;
$$;
revoke all on function private.fn_refresh_count(uuid) from public, anon, authenticated;

-- Anyone who can see the count may refresh it; a count that is closed, or
-- a technician's count already sent for review, is left as it is.
create or replace function public.rpc_refresh_inventory_count(p_count_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  begin
    perform private.fn_assert_count_editable(p_count_id);
  exception when others then
    return;
  end;
  perform private.fn_refresh_count(p_count_id);
end;
$$;

-- 0089's body; reopening a draft refreshes it.
create or replace function public.rpc_start_inventory_count(p_location_type location_type, p_location_id uuid, p_product_ids uuid[])
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_count_id uuid;
begin
  if not ((public.is_admin() or public.is_sales())
          or (public.is_technician() and p_location_type = 'technician_bag'
              and exists (select 1 from public.technician_bags
                          where id = p_location_id and technician_id = auth.uid()))) then
    raise exception 'FORBIDDEN';
  end if;

  perform pg_advisory_xact_lock(hashtext('inventory_count:' || p_location_id::text));
  select id into v_count_id from public.inventory_counts
  where location_type = p_location_type and location_id = p_location_id and status = 'draft'
  order by started_at desc limit 1;
  if v_count_id is not null then
    perform public.rpc_refresh_inventory_count(v_count_id);
    return v_count_id;
  end if;

  insert into public.inventory_counts (location_type, location_id, started_by)
  values (p_location_type, p_location_id, auth.uid())
  returning id into v_count_id;

  if p_location_type = 'warehouse' then
    insert into public.inventory_count_items (inventory_count_id, product_id, system_quantity)
    select v_count_id, product_id, quantity from public.warehouse_stock
    where warehouse_id = p_location_id and (p_product_ids is null or product_id = any (p_product_ids));
  else
    insert into public.inventory_count_items (inventory_count_id, product_id, system_quantity)
    select v_count_id, product_id, quantity from public.technician_bag_stock
    where technician_bag_id = p_location_id and quantity > 0
      and (p_product_ids is null or product_id = any (p_product_ids));
  end if;

  return v_count_id;
end;
$$;

-- 0089's body; compared with the stock as it is now.
create or replace function public.rpc_save_inventory_count_item(p_item_id uuid, p_actual_quantity int, p_reason text, p_notes text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_item record;
  v_count record;
  v_system int;
begin
  select * into v_item from public.inventory_count_items where id = p_item_id;
  if v_item.id is null then raise exception 'ITEM_NOT_FOUND_OR_COUNT_CLOSED'; end if;
  perform private.fn_assert_count_editable(v_item.inventory_count_id);
  select * into v_count from public.inventory_counts where id = v_item.inventory_count_id for update;

  if p_actual_quantity is null or p_actual_quantity < 0 then
    raise exception 'INVALID_QUANTITY';
  end if;
  v_system := private.fn_location_quantity(v_count.location_type, v_count.location_id, v_item.product_id);
  if p_actual_quantity <> v_system and coalesce(trim(p_reason), '') = '' then
    raise exception 'COUNT_REASON_REQUIRED';
  end if;

  update public.inventory_count_items
    set system_quantity = v_system,
        actual_quantity = p_actual_quantity,
        reason = case when p_actual_quantity = v_system then null else nullif(trim(p_reason), '') end,
        notes = p_notes
    where id = p_item_id;
end;
$$;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_refresh_inventory_count', 'admin/sales/technician (own bag)')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
