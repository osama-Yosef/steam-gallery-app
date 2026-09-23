-- ============================================================================
-- 0074_bulk_effective_prices_rpc.sql
--
-- Bug: the walk-in sale screen (admin/sales) reads warehouse_stock joined
-- straight to products.selling_price, so staff see and total the raw
-- catalogue price at the register. rpc_admin_walk_in_sale (0061) already
-- charges private.fn_effective_price() per product (offer price when a
-- live offer applies) -- the ledger itself stays correct, but the number
-- shown to staff before confirming can be higher than what actually gets
-- charged and debited from the till, if a product is on a live offer.
--
-- Bulk RPC so the walk-in sale screen can resolve every visible product's
-- real price in one round trip instead of one fn_effective_price() call
-- per row.
-- ============================================================================

create or replace function public.rpc_effective_prices(p_product_ids uuid[])
returns table(product_id uuid, effective_price numeric)
language sql stable security definer set search_path = public as $$
  select p.id, private.fn_effective_price(p.id)
  from public.products p
  where p.id = any(p_product_ids);
$$;

revoke all on function public.rpc_effective_prices(uuid[]) from public, anon;
grant execute on function public.rpc_effective_prices(uuid[]) to authenticated;
