-- ============================================================================
-- 0096_stock_value_and_count_values.sql
--
-- 1. What the stock was worth at a moment in the past — "جرد يوم 1-10 بكام".
--    stock_movements is the only way stock ever changes (0003's trigger), so
--    the quantity anywhere at time T is the movements in minus out before T.
--    Each product is valued at its cost then: the unit cost of its last
--    movement before T (every movement records the cost price of the time),
--    else today's cost price.
--
--    rpc_month_stock(p_month): the warehouse and the technicians' bags at
--    the start of the Cairo month and at its end (now, for this month).
--    Admin only, like the month report it sits beside.
--
-- 2. What a count is worth. inventory_count_item_values gives each line its
--    unit cost — what its adjustment was booked at once approved, today's
--    cost price before — and inventory_count_values adds up per count: the
--    stock as counted, the stock as the system had it, the shortage and the
--    surplus. Both views run as the caller (security_invoker), so they show
--    exactly the counts the caller can already see.
-- ============================================================================

create or replace function private.fn_stock_value_at(p_at timestamptz)
returns jsonb language sql stable security definer set search_path = public as $$
  with q as (
    select product_id,
      sum(case when to_location_type = 'warehouse' then quantity else 0 end)
        - sum(case when from_location_type = 'warehouse' then quantity else 0 end) as warehouse,
      sum(case when to_location_type = 'technician_bag' then quantity else 0 end)
        - sum(case when from_location_type = 'technician_bag' then quantity else 0 end) as bags
    from public.stock_movements
    where created_at < p_at
    group by product_id
  ), valued as (
    select q.warehouse, q.bags,
      coalesce((select m.unit_cost from public.stock_movements m
                where m.product_id = q.product_id and m.created_at < p_at
                order by m.created_at desc, m.movement_number desc limit 1),
               p.cost_price) as cost
    from q join public.products p on p.id = q.product_id
  )
  select jsonb_build_object(
    'warehouse', coalesce(sum(greatest(warehouse, 0) * cost), 0)::numeric(14,2),
    'bags', coalesce(sum(greatest(bags, 0) * cost), 0)::numeric(14,2))
  from valued;
$$;
revoke all on function private.fn_stock_value_at(timestamptz) from public, anon, authenticated;

create or replace function public.rpc_month_stock(p_month date default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_month date := date_trunc('month',
    coalesce(p_month, (now() at time zone 'Africa/Cairo')::date))::date;
  v_from timestamptz := v_month::timestamp at time zone 'Africa/Cairo';
  v_to timestamptz := (v_month + interval '1 month')::timestamp at time zone 'Africa/Cairo';
  v_end timestamptz := least(v_to, now());
  v_end_value jsonb;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if v_to > now() then
    -- This month ends now: the same figures as the month report's "دلوقتي".
    v_end_value := jsonb_build_object(
      'warehouse', (select coalesce(sum(stock_value), 0) from public.warehouse_stock_value),
      'bags', (select coalesce(sum(bag_value), 0) from public.technician_bag_value));
  else
    v_end_value := private.fn_stock_value_at(v_end);
  end if;
  return jsonb_build_object(
    'month', v_month,
    'start_at', v_from,
    'end_at', v_end,
    'start', private.fn_stock_value_at(v_from),
    'end', v_end_value);
end;
$$;

create or replace view public.inventory_count_item_values
  with (security_invoker = true) as
select i.id as item_id, i.inventory_count_id, i.product_id,
  i.system_quantity, i.actual_quantity, i.difference,
  coalesce(m.unit_cost, p.cost_price)::numeric(12,2) as unit_cost
from public.inventory_count_items i
join public.products p on p.id = i.product_id
left join lateral (
  select sm.unit_cost from public.stock_movements sm
  where sm.reference_type = 'inventory_count' and sm.reference_id = i.inventory_count_id
    and sm.product_id = i.product_id
  limit 1
) m on true;

create or replace view public.inventory_count_values
  with (security_invoker = true) as
select inventory_count_id,
  sum(coalesce(actual_quantity, system_quantity) * unit_cost)::numeric(14,2) as counted_value,
  sum(system_quantity * unit_cost)::numeric(14,2) as system_value,
  sum(case when difference < 0 then -difference * unit_cost else 0 end)::numeric(14,2) as shortage_value,
  sum(case when difference > 0 then difference * unit_cost else 0 end)::numeric(14,2) as surplus_value,
  (count(*) filter (where difference < 0))::int as shortage_count,
  (count(*) filter (where difference > 0))::int as surplus_count
from public.inventory_count_item_values
group by inventory_count_id;

grant select on public.inventory_count_item_values to authenticated;
grant select on public.inventory_count_values to authenticated;

insert into private.rpc_allowlist (function_name, note) values ('rpc_month_stock', 'admin')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
