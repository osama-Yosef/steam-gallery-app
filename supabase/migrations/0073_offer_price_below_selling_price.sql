-- ============================================================================
-- 0073_offer_price_below_selling_price.sql
--
-- Bug: offer_products.offer_price (0061) was only checked for >= 0, never
-- against the product's own products.selling_price. An admin could set an
-- "offer" price equal to or above the regular price, and it would display
-- and charge as a discount with no warning anywhere in the stack. A plain
-- check constraint can't reference another table, so this is a trigger.
-- The Dart admin UI (admin_offer_editor_screen.dart) now also validates
-- this before saving -- this is the server-side backstop.
-- ============================================================================

create or replace function private.fn_check_offer_price_below_selling_price()
returns trigger language plpgsql as $$
declare
  v_selling_price numeric(12,2);
begin
  if new.offer_price is null then
    return new;
  end if;
  select selling_price into v_selling_price from public.products where id = new.product_id;
  if v_selling_price is not null and new.offer_price >= v_selling_price then
    raise exception 'OFFER_PRICE_NOT_BELOW_SELLING_PRICE';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_offer_products_price_check on public.offer_products;
create trigger trg_offer_products_price_check
  before insert or update of offer_price, product_id on public.offer_products
  for each row execute function private.fn_check_offer_price_below_selling_price();
