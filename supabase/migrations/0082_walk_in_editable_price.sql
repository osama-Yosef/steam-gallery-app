-- ============================================================================
-- 0082_walk_in_editable_price.sql
--
-- The counter can now charge a stock product more or less than its price:
-- rpc_admin_walk_in_sale takes an item's unit_price for any product, not
-- only a service. When none is sent, the product's price today (offer price
-- included, private.fn_effective_price) is charged exactly as before, so a
-- register that doesn't send one — or an older app version — behaves the
-- same. The cost snapshot is untouched, so profit reports see the real
-- margin of a re-priced line.
--
-- Patched in place on the live definition (as 0080 did) rather than
-- restating the whole function; the one branch that ignored the given price
-- is replaced, and the migration fails if that branch isn't found. Matched
-- on any whitespace: the stored body may have CRLF or LF line endings
-- depending on the machine it was applied from.
-- ============================================================================

do $patch$
declare
  v_oid oid := 'public.rpc_admin_walk_in_sale(text, text, jsonb, payment_method, numeric, uuid, text)'::regprocedure;
  v_def text := pg_get_functiondef(v_oid);
  v_old text := $re$else\s+v_unit_price := private\.fn_effective_price\(v_product\.id\);\s+end if;$re$;
  v_new text := $s$elsif v_unit_price is null then
      v_unit_price := private.fn_effective_price(v_product.id);
    elsif v_unit_price <= 0 or v_unit_price <> round(v_unit_price, 2) then
      raise exception 'INVALID_AMOUNT';
    end if;$s$;
begin
  if v_def !~ v_old then
    raise exception 'rpc_admin_walk_in_sale: price branch not found';
  end if;
  execute regexp_replace(v_def, v_old, v_new);
end
$patch$;

notify pgrst, 'reload schema';
