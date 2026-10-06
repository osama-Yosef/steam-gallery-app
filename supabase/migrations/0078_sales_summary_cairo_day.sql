-- ============================================================================
-- 0078_sales_summary_cairo_day.sql
--
-- Bug (found live 2026-10-07 00:33 Cairo): sales made after midnight in
-- Cairo didn't count in "مبيعات اليوم". daily_sales_summary grouped by
-- date_trunc('day', created_at) — the UTC day — and Cairo is UTC+3, so
-- anything sold between 00:00 and 03:00 local time landed on yesterday.
--
-- Fix: the business day is the Cairo calendar day. `day` stays a
-- timestamptz (Cairo midnight) rather than becoming a date, so the type
-- doesn't change, monthly_sales_summary built on top of it needs no drop,
-- and the app's existing `DateTime.parse(day).toLocal()` lands on the right
-- day. Body otherwise identical to 0072.
-- ============================================================================

create or replace view public.daily_sales_summary
  with (security_invoker = true) as
select day, sum(revenue)::numeric(14,2) as revenue, sum(cogs)::numeric(14,2) as cogs
from (
  select date_trunc('day', o.created_at at time zone 'Africa/Cairo') at time zone 'Africa/Cairo' as day,
    sum(oi.line_total) as revenue,
    sum(oi.quantity * oi.unit_cost_snapshot) as cogs
  from public.orders o
  join public.order_items oi on oi.order_id = o.id
  where o.status in ('confirmed', 'preparing', 'delivered', 'completed')
  group by 1
  union all
  select date_trunc('day', s.created_at at time zone 'Africa/Cairo') at time zone 'Africa/Cairo' as day,
    sum(si.line_total - coalesce(sr.total_refund, 0)) as revenue,
    sum((si.quantity - coalesce(sr.total_returned_qty, 0)) * si.unit_cost_snapshot) as cogs
  from public.sales s
  join public.sale_items si on si.sale_id = s.id
  left join (
    select sale_item_id,
      sum(quantity) as total_returned_qty,
      sum(refund_amount) as total_refund
    from public.sale_item_returns
    group by sale_item_id
  ) sr on sr.sale_item_id = si.id
  where s.status = 'completed'
  group by 1
) x
group by day
order by day desc;

-- Same Cairo calendar for the month (the 1st's first hours were the
-- previous month in UTC).
create or replace view public.monthly_sales_summary
  with (security_invoker = true) as
select date_trunc('month', day at time zone 'Africa/Cairo') at time zone 'Africa/Cairo' as month,
  sum(revenue)::numeric(14,2) as revenue,
  sum(cogs)::numeric(14,2) as cogs
from public.daily_sales_summary
group by 1
order by 1 desc;
