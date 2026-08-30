-- ============================================================================
-- 0016_fix_products_public_availability.sql
--
-- Bug found via live testing: products_public was created WITH
-- (security_invoker = true), which made its internal join against
-- warehouse_stock run under the QUERYING user's RLS. warehouse_stock's
-- SELECT policy is admin-only (by design — customers must never see raw
-- stock levels), so for every customer that join returned nothing and
-- is_available was permanently false for every product, for every
-- customer. Nobody could ever add anything to a cart.
--
-- Fix: products_public does NOT need security_invoker at all. Unlike the
-- summary views (technician_account_summary etc.) where per-viewer RLS
-- scoping on the underlying tables IS the security mechanism, this view's
-- only real protection is structural — it simply never selects cost_price
-- — and that holds regardless of who runs the query. Reverting to the
-- default (definer-semantics, view owner bypasses RLS) lets the
-- availability aggregate work for every authenticated role while the
-- explicit `where p.is_active = true` still gates which products appear
-- at all.
-- ============================================================================

-- CREATE OR REPLACE VIEW does not reliably clear a previously-set reloption,
-- so explicitly turn security_invoker back off first.
alter view public.products_public set (security_invoker = false);

create or replace view public.products_public as
select
  p.id, p.sku, p.barcode, p.category_id, p.name, p.description, p.specs,
  p.selling_price, p.is_active, p.created_at,
  coalesce(ws.total_qty, 0) > 0 as is_available
from public.products p
left join (
  select product_id, sum(quantity) as total_qty
  from public.warehouse_stock
  group by product_id
) ws on ws.product_id = p.id
where p.is_active = true;

grant select on public.products_public to authenticated;
