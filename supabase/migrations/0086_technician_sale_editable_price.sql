-- ============================================================================
-- 0086_technician_sale_editable_price.sql
--
-- A technician selling from his bag can now charge a stock product more or
-- less than its price, as the counter can since 0082: rpc_technician_sale
-- takes an item's unit_price for any product, not only a service. When none
-- is sent, the product's selling price is charged exactly as before, so an
-- older app version — which sends a price only for services — behaves the
-- same. The cost snapshot is untouched, so profit reports see the real
-- margin of a re-priced line, and the technician owes what he actually
-- charged.
--
-- Patched in place on the live definition (as 0082 did) rather than
-- restating the whole function; the one branch that ignored the given price
-- is replaced, and the migration fails if that branch isn't found. Matched
-- on any whitespace: the stored body may have CRLF or LF line endings.
-- ============================================================================

do $patch$
declare
  v_oid oid := 'public.rpc_technician_sale(uuid, uuid, text, text, jsonb, payment_method, numeric, numeric, uuid, text, uuid)'::regprocedure;
  v_def text := pg_get_functiondef(v_oid);
  v_old text := $re$else\s+v_unit_price := v_product\.selling_price;\s+end if;$re$;
  v_new text := $s$elsif v_unit_price is null then
      v_unit_price := v_product.selling_price;
    elsif v_unit_price <= 0 or v_unit_price <> round(v_unit_price, 2) then
      raise exception 'INVALID_AMOUNT';
    end if;$s$;
begin
  if v_def !~ v_old then
    raise exception 'rpc_technician_sale: price branch not found';
  end if;
  execute regexp_replace(v_def, v_old, v_new);
end
$patch$;

notify pgrst, 'reload schema';
