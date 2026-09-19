-- ============================================================================
-- 0053_recreate_missing_cart_rpcs.sql
--
-- rpc_cart_set_item/rpc_cart_add_item (3-arg, option-aware versions from
-- 0049) turned out to never exist in the live database at all — confirmed
-- via `select proname from pg_proc where proname in (...)` returning zero
-- rows, after 0050 already dropped the old 2-arg versions. Whatever
-- happened when 0049 was first pasted, these two functions never landed.
-- Re-creating them here; identical bodies to 0049. `apply_function_grants`
-- re-run at the end so the fresh functions get their EXECUTE grant (a
-- brand-new function starts with no grants, regardless of the allowlist
-- entry already existing from 0035).
-- ============================================================================

create or replace function public.rpc_cart_set_item(
  p_product_id uuid, p_quantity int, p_option_ids uuid[] default '{}'
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_price numeric(12,2);
  v_options_total numeric(12,2);
  v_option_ids uuid[];
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  if p_product_id is null or p_quantity is null
     or p_quantity < 0 or p_quantity > private.cart_max_quantity() then
    raise exception 'INVALID_QUANTITY';
  end if;

  select coalesce(array_agg(distinct x order by x), '{}') into v_option_ids
    from unnest(coalesce(p_option_ids, '{}'::uuid[])) x;

  if p_quantity = 0 then
    delete from public.cart_items
     where customer_id = v_uid and product_id = p_product_id and option_ids = v_option_ids;
    return public.rpc_get_my_cart();
  end if;

  select p.selling_price into v_price
    from public.products p
   where p.id = p_product_id and p.is_active and not p.is_service;
  if not found then raise exception 'PRODUCT_NOT_FOUND'; end if;

  if array_length(v_option_ids, 1) > 0 then
    if (select count(*) from public.product_options
         where id = any(v_option_ids) and product_id = p_product_id) <> array_length(v_option_ids, 1) then
      raise exception 'OPTION_NOT_FOUND';
    end if;
    select coalesce(sum(po.extra_price), 0) into v_options_total
      from public.product_options po where po.id = any(v_option_ids);
  else
    v_options_total := 0;
  end if;
  v_price := v_price + v_options_total;

  -- Serialise this customer's cart writes so the line cap can't be raced.
  perform 1 from public.customers where id = v_uid for update;

  if not exists (
      select 1 from public.cart_items
       where customer_id = v_uid and product_id = p_product_id and option_ids = v_option_ids)
     and (select count(*) from public.cart_items where customer_id = v_uid) >= private.cart_max_lines() then
    raise exception 'CART_FULL';
  end if;

  insert into public.cart_items as ci (customer_id, product_id, option_ids, quantity, price_seen)
  values (v_uid, p_product_id, v_option_ids, p_quantity, v_price)
  on conflict (customer_id, product_id, option_ids) do update
    set quantity = excluded.quantity, price_seen = excluded.price_seen, updated_at = now();

  return public.rpc_get_my_cart();
end;
$$;

create or replace function public.rpc_cart_add_item(
  p_product_id uuid, p_quantity int, p_option_ids uuid[] default '{}'
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_current int;
  v_option_ids uuid[];
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > private.cart_max_quantity() then
    raise exception 'INVALID_QUANTITY';
  end if;

  select coalesce(array_agg(distinct x order by x), '{}') into v_option_ids
    from unnest(coalesce(p_option_ids, '{}'::uuid[])) x;

  select quantity into v_current from public.cart_items
   where customer_id = auth.uid() and product_id = p_product_id and option_ids = v_option_ids;
  return public.rpc_cart_set_item(
    p_product_id, least(coalesce(v_current, 0) + p_quantity, private.cart_max_quantity()), v_option_ids);
end;
$$;

select private.apply_function_grants();
notify pgrst, 'reload schema';
