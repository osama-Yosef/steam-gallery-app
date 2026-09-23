-- ============================================================================
-- 0072_fix_dashboard_revenue_partial_returns.sql
--
-- Bug: daily_sales_summary (0009_views.sql) sums sale_items.line_total for
-- every item on a sale with status = 'completed'. Since 0058, a sale only
-- flips to status = 'returned' once EVERY item is fully returned -- a
-- partial line return (private.fn_return_sale_item) correctly debits the
-- cashbox via v_refund, but leaves the sale 'completed', so the dashboard
-- kept counting the full original line amount in revenue/COGS/net-profit
-- forever after. Cashbox and reported revenue drift apart after any
-- partial refund.
--
-- Fix: net each sale_item's contribution against sale_item_returns
-- (refund_amount already carries the exact prorated discount, same number
-- actually refunded at the till; quantity nets the matching COGS).
-- ============================================================================

create or replace view public.daily_sales_summary
  with (security_invoker = true) as
select day, sum(revenue)::numeric(14,2) as revenue, sum(cogs)::numeric(14,2) as cogs
from (
  select date_trunc('day', o.created_at) as day,
    sum(oi.line_total) as revenue,
    sum(oi.quantity * oi.unit_cost_snapshot) as cogs
  from public.orders o
  join public.order_items oi on oi.order_id = o.id
  where o.status in ('confirmed', 'preparing', 'delivered', 'completed')
  group by 1
  union all
  select date_trunc('day', s.created_at) as day,
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
