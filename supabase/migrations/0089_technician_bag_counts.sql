-- ============================================================================
-- 0089_technician_bag_counts.sql
--
-- جرد شنطة الصنايعي — admin, sales and the technician himself.
--
-- The count tables and RPCs (0007/0010) already handle a technician_bag
-- location; this opens them up for bags:
--
-- 1. A technician counts HIS OWN bag: starts the count, enters what he
--    actually has (a reason is required on every shortage/surplus), adds a
--    product the system doesn't think he has (a surplus), then sends it for
--    review. Once sent it is read-only for him.
-- 2. Admin/sales count any bag the same way, and are the only ones who
--    approve (rpc_complete_inventory_count, unchanged): only then does the
--    bag change, as 'inventory_adjustment' movements carrying the reason.
--    No money moves — a shortage is a stock correction, not a charge.
-- 3. One open count per place. A second "start" returns the open one —
--    two drafts of the same bag would apply the same difference twice.
--    This holds for the warehouse too.
--
-- New: inventory_counts.submitted_at, rpc_start_bag_count,
-- rpc_add_inventory_count_item, rpc_submit_inventory_count.
-- Replaced: rpc_start_inventory_count, rpc_save_inventory_count_item.
-- ============================================================================

alter table public.inventory_counts add column if not exists submitted_at timestamptz;

-- ----------------------------------------------------------------------------
-- Who may change a draft: admin/sales always; the bag's own technician
-- until he sends it for review.
-- ----------------------------------------------------------------------------
create or replace function private.fn_assert_count_editable(p_count_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_count record;
begin
  select * into v_count from public.inventory_counts where id = p_count_id;
  if v_count.id is null or v_count.status <> 'draft' then
    raise exception 'COUNT_NOT_DRAFT';
  end if;
  if public.is_admin() or public.is_sales() then return; end if;
  if not (public.is_technician() and v_count.location_type = 'technician_bag'
          and exists (select 1 from public.technician_bags
                      where id = v_count.location_id and technician_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;
  if v_count.submitted_at is not null then
    raise exception 'COUNT_ALREADY_SUBMITTED';
  end if;
end;
$$;
revoke all on function private.fn_assert_count_editable(uuid) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- Start (or reopen) a count.
-- ----------------------------------------------------------------------------
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
  if v_count_id is not null then return v_count_id; end if;

  insert into public.inventory_counts (location_type, location_id, started_by)
  values (p_location_type, p_location_id, auth.uid())
  returning id into v_count_id;

  if p_location_type = 'warehouse' then
    insert into public.inventory_count_items (inventory_count_id, product_id, system_quantity)
    select v_count_id, product_id, quantity from public.warehouse_stock
    where warehouse_id = p_location_id and (p_product_ids is null or product_id = any (p_product_ids));
  else
    -- Only what is actually in the bag; anything else is added as a surplus.
    insert into public.inventory_count_items (inventory_count_id, product_id, system_quantity)
    select v_count_id, product_id, quantity from public.technician_bag_stock
    where technician_bag_id = p_location_id and quantity > 0
      and (p_product_ids is null or product_id = any (p_product_ids));
  end if;

  return v_count_id;
end;
$$;

-- The app knows technicians, not bag ids.
create or replace function public.rpc_start_bag_count(p_technician_id uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_bag_id uuid;
begin
  if not ((public.is_admin() or public.is_sales())
          or (public.is_technician() and p_technician_id = auth.uid())) then
    raise exception 'FORBIDDEN';
  end if;
  insert into public.technician_bags (technician_id) values (p_technician_id)
  on conflict (technician_id) do nothing;
  select id into v_bag_id from public.technician_bags where technician_id = p_technician_id;
  return public.rpc_start_inventory_count('technician_bag', v_bag_id, null);
end;
$$;

-- ----------------------------------------------------------------------------
-- A product found that the count has no line for (a surplus). Returns the
-- line, existing or new.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_add_inventory_count_item(p_count_id uuid, p_product_id uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_count record;
  v_item_id uuid;
  v_qty int;
begin
  perform private.fn_assert_count_editable(p_count_id);
  select * into v_count from public.inventory_counts where id = p_count_id for update;
  if not exists (select 1 from public.products where id = p_product_id) then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  select id into v_item_id from public.inventory_count_items
  where inventory_count_id = p_count_id and product_id = p_product_id;
  if v_item_id is not null then return v_item_id; end if;

  if v_count.location_type = 'warehouse' then
    select quantity into v_qty from public.warehouse_stock
    where warehouse_id = v_count.location_id and product_id = p_product_id;
  else
    select quantity into v_qty from public.technician_bag_stock
    where technician_bag_id = v_count.location_id and product_id = p_product_id;
  end if;

  insert into public.inventory_count_items (inventory_count_id, product_id, system_quantity)
  values (p_count_id, p_product_id, coalesce(v_qty, 0))
  returning id into v_item_id;
  return v_item_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- Enter the counted quantity of one line.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_save_inventory_count_item(p_item_id uuid, p_actual_quantity int, p_reason text, p_notes text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_item record;
begin
  select * into v_item from public.inventory_count_items where id = p_item_id;
  if v_item.id is null then raise exception 'ITEM_NOT_FOUND_OR_COUNT_CLOSED'; end if;
  perform private.fn_assert_count_editable(v_item.inventory_count_id);

  if p_actual_quantity is null or p_actual_quantity < 0 then
    raise exception 'INVALID_QUANTITY';
  end if;
  if p_actual_quantity <> v_item.system_quantity and coalesce(trim(p_reason), '') = '' then
    raise exception 'COUNT_REASON_REQUIRED';
  end if;

  update public.inventory_count_items
    set actual_quantity = p_actual_quantity, reason = nullif(trim(p_reason), ''), notes = p_notes
    where id = p_item_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- The technician hands his count over for review. Every line must be
-- counted — an untouched line would be approved as "matches".
-- ----------------------------------------------------------------------------
create or replace function public.rpc_submit_inventory_count(p_count_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform private.fn_assert_count_editable(p_count_id);
  if exists (select 1 from public.inventory_count_items
             where inventory_count_id = p_count_id and actual_quantity is null) then
    raise exception 'COUNT_INCOMPLETE';
  end if;
  update public.inventory_counts set submitted_at = now() where id = p_count_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- A technician sees the counts of his own bag.
-- ----------------------------------------------------------------------------
alter policy inventory_counts_select on public.inventory_counts
  using (
    public.is_admin() or public.is_sales()
    or (public.is_technician() and location_type = 'technician_bag'
        and location_id in (select id from public.technician_bags where technician_id = auth.uid()))
  );
alter policy inventory_count_items_select on public.inventory_count_items
  using (
    public.is_admin() or public.is_sales()
    or (public.is_technician()
        and inventory_count_id in (select id from public.inventory_counts))
  );

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_start_bag_count', 'admin/sales/technician (own bag)'),
  ('rpc_add_inventory_count_item', 'admin/sales/technician (own bag)'),
  ('rpc_submit_inventory_count', 'technician (own bag)')
on conflict (function_name) do nothing;
update private.rpc_allowlist set note = 'admin/sales/technician (own bag)'
where function_name in ('rpc_start_inventory_count', 'rpc_save_inventory_count_item');

select private.apply_function_grants();
notify pgrst, 'reload schema';
