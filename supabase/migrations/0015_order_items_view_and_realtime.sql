-- ============================================================================
-- 0015_order_items_view_and_realtime.sql
--
-- order_items RLS is row-level (admin sees all rows, a customer sees rows
-- belonging to their own orders) — but a customer's own order_items row
-- also carries unit_cost_snapshot (needed for COGS/profit reporting), which
-- would otherwise leak the internal cost price for anything they've ever
-- ordered. Same pattern as products_public: project it away in a view
-- rather than trusting the app layer to just not SELECT that column.
-- ============================================================================

create view public.order_items_display
  with (security_invoker = true) as
select id, order_id, product_id, product_name_snapshot, quantity,
       unit_price_snapshot, discount, line_total
from public.order_items;

grant select on public.order_items_display to authenticated;

-- Realtime: customers/admin watch `orders` live (order status updates,
-- new orders in the admin list) without polling.
alter publication supabase_realtime add table public.orders;
