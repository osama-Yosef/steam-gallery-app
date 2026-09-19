-- ============================================================================
-- 0052_fix_order_items_cost_leak.sql
--
-- P0 regression found via tool/db_tests: 0029 (P0-2) deliberately locked
-- order_items_select down to admin-only, specifically because the raw table
-- carries unit_cost_snapshot (wholesale cost) and customers were meant to
-- see their own order's lines only through order_items_display, a view
-- that never selects that column. 0044 (sales role rollout) widened the
-- policy with `alter policy ... using (... or order_id in (select id from
-- orders where customer_id = auth.uid()))` to let sales see every order —
-- but that same clause also re-opened direct customer access to the raw
-- table, undoing the 0029 fix. A customer can currently select
-- unit_cost_snapshot straight from public.order_items for their own orders,
-- and daily_sales_summary (security_invoker, no own filtering — relies
-- entirely on the base tables' RLS) leaks the same cost data through its
-- cogs column for the same reason.
--
-- The app never reads the raw table directly (only order_items_display),
-- so removing the customer clause here costs it nothing.
--
-- Second, related regression (introduced by 0049, this migration's own
-- author): order_items_display was flipped to `security_invoker = true`
-- when 0049 added selected_options_snapshot to it. 0029 explicitly set
-- `security_invoker = false` (definer + security_barrier, with its own
-- admin-or-owner filter) precisely because under invoker rights the
-- admin-only base policy leaves customers with nothing through the view
-- either — restoring the policy above without also restoring this would
-- have left customers unable to see their own order items at all. Restored
-- to 0029's definer pattern, keeping 0049's selected_options_snapshot
-- column.
-- ============================================================================

alter policy order_items_select on public.order_items
  using (public.is_admin() or public.is_sales());

alter view public.order_items_display set (security_invoker = false);
create or replace view public.order_items_display
  with (security_barrier = true) as
select oi.id, oi.order_id, oi.product_id, oi.product_name_snapshot, oi.quantity,
       oi.unit_price_snapshot, oi.discount, oi.line_total, oi.selected_options_snapshot
from public.order_items oi
where public.is_admin()
   or public.is_sales()
   or exists (
     select 1 from public.orders o
     where o.id = oi.order_id and o.customer_id = auth.uid()
   );
grant select on public.order_items_display to authenticated;
