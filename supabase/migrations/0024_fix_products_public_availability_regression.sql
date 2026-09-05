-- ============================================================================
-- 0024_fix_products_public_availability_regression.sql
--
-- Regression of the exact bug 0016 already fixed: every product showed as
-- "غير متاح" to every customer even with stock on the shelf.
--
-- 0022 recreated products_public to add primary_image_url and reintroduced
-- WITH (security_invoker = true). Under invoker semantics the view's join
-- against warehouse_stock runs with the *querying* user's RLS, and
-- warehouse_stock_select is admin-only by design (customers must never see
-- raw stock levels). So for any customer that join matched nothing,
-- coalesce(ws.total_qty, 0) was 0, and is_available was permanently false.
--
-- As 0016 explains: this view does not need security_invoker. Its protection
-- is structural — it simply never selects cost_price — and that holds no
-- matter who runs it. The image subquery has the same problem and the same
-- answer. Restoring definer semantics fixes availability while
-- `where p.is_active = true` still gates which products are visible at all.
-- ============================================================================

-- CREATE OR REPLACE VIEW does not reliably clear a previously-set reloption,
-- so explicitly turn security_invoker back off first (same as 0016).
alter view public.products_public set (security_invoker = false);

create or replace view public.products_public as
select
  p.id, p.sku, p.barcode, p.category_id, p.name, p.description, p.specs,
  p.selling_price, p.is_active, p.created_at,
  coalesce(ws.total_qty, 0) > 0 as is_available,
  img.image_url as primary_image_url
from public.products p
left join (
  select product_id, sum(quantity) as total_qty
  from public.warehouse_stock
  group by product_id
) ws on ws.product_id = p.id
left join lateral (
  select image_url from public.product_images pi
  where pi.product_id = p.id
  order by pi.is_primary desc, pi.sort_order asc
  limit 1
) img on true
where p.is_active = true;

grant select on public.products_public to authenticated;
