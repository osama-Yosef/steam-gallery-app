-- ============================================================================
-- 0020_products_public_primary_image.sql
--
-- The catalog grid (customer app) and admin product list have never shown
-- real product photos — always a placeholder icon — because products_public
-- carries no image reference at all. Append a primary_image_url column
-- (falls back to the lowest sort_order image when none is flagged primary)
-- so a single query gives the grid everything it needs, no N+1 per-card
-- image lookups.
-- ============================================================================

create or replace view public.products_public
  with (security_invoker = true) as
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
