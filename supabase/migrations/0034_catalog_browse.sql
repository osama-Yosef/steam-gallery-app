-- ============================================================================
-- 0034_catalog_browse.sql  (Phase 6 — product catalogue)
--
-- The store used to download every row of products_public and filter with a
-- raw ILIKE (user-typed % and _ acted as wildcards). This adds one paginated,
-- server-side browse RPC:
--
--   * search over name + SKU, Arabic-normalised (أ/إ/آ → ا, ة → ه, ى → ي,
--     diacritics and tatweel dropped), LIKE metacharacters escaped;
--   * filters: category (including its sub-categories), price range,
--     available-only;
--   * sort: newest, price_asc, price_desc, name — each with an id tiebreak so
--     pages never overlap or skip rows;
--   * limit/offset pagination, capped server-side.
--
-- Only catalogue-safe columns are returned (the products_public row type);
-- cost_price never leaves the database. Category admin gets length checks and
-- a self-parent guard; no data, trigger or ledger changes.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Search key
-- ----------------------------------------------------------------------------
-- Immutable so it can back an expression index. It has to live in `public`
-- and be EXECUTE-able by every role that writes products: Postgres checks
-- EXECUTE on index-expression functions at INSERT/UPDATE time, so a revoked
-- helper would make admins unable to save products. It is a pure text
-- function, so exposing it leaks nothing.
create or replace function public.search_key(p text) returns text
language sql immutable parallel safe set search_path = '' as $$
  select lower(
    translate(
      coalesce(p, ''),
      -- أ إ آ ٱ ى ة, then tatweel and the harakat (U+064B..U+0652) -> removed
      'أإآٱىة' || 'ـ' || 'ًٌٍَُِّْ',
      'اااايه'
    )
  );
$$;

create index if not exists idx_products_search_key_trgm
  on public.products
  using gin (public.search_key(name || ' ' || sku) gin_trgm_ops)
  where is_active and not is_service;

-- Newest-first and price sorts over the live catalogue.
create index if not exists idx_products_catalog_created
  on public.products (created_at desc, id) where is_active and not is_service;
create index if not exists idx_products_catalog_price
  on public.products (selling_price, id) where is_active and not is_service;

-- ----------------------------------------------------------------------------
-- 2. Category guards (admin now edits image, order and parent from the app)
-- ----------------------------------------------------------------------------
-- NOT VALID: enforced for new writes without failing on legacy rows.
alter table public.product_categories
  add constraint product_categories_name_len
    check (length(btrim(name)) between 1 and 60) not valid,
  add constraint product_categories_image_url_len
    check (image_url is null or length(image_url) <= 1000) not valid,
  add constraint product_categories_not_own_parent
    check (parent_id is null or parent_id <> id) not valid;

-- ----------------------------------------------------------------------------
-- 3. Browse RPC
-- ----------------------------------------------------------------------------
-- SECURITY DEFINER because it reads public.products directly (so filters and
-- LIMIT apply before the per-row stock/image lookups). It therefore projects
-- the products_public columns explicitly and applies the same visibility rule
-- (active, not a service).
create or replace function public.rpc_browse_products(
  p_search text default null,
  p_category_id uuid default null,
  p_min_price numeric default null,
  p_max_price numeric default null,
  p_available_only boolean default false,
  p_sort text default 'newest',
  p_limit int default 20,
  p_offset int default 0
)
returns setof public.products_public
language plpgsql stable security definer set search_path = '' as $$
declare
  v_term text;
  v_sort text := coalesce(p_sort, 'newest');
begin
  -- Suspended users (and unverified customers when the switch is on) are
  -- 'anon' here, same as everywhere else.
  if public.auth_role() = 'anon' then
    raise exception 'FORBIDDEN';
  end if;

  if v_sort not in ('newest', 'price_asc', 'price_desc', 'name') then
    raise exception 'INVALID_SORT';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 50
     or p_offset is null or p_offset < 0 or p_offset > 10000 then
    raise exception 'INVALID_PAGE';
  end if;
  if (p_min_price is not null and p_min_price < 0)
     or (p_max_price is not null and p_max_price < 0)
     or (p_min_price is not null and p_max_price is not null and p_min_price > p_max_price) then
    raise exception 'INVALID_PRICE_RANGE';
  end if;
  if length(p_search) > 100 then
    raise exception 'INPUT_TOO_LONG';
  end if;

  v_term := nullif(btrim(public.search_key(p_search)), '');
  if v_term is not null then
    v_term := '%' || replace(replace(replace(v_term, '\', '\\'), '%', '\%'), '_', '\_') || '%';
  end if;

  return query
  with recursive cats as (
    select c.id from public.product_categories c where c.id = p_category_id
    union
    select c.id from public.product_categories c join cats on c.parent_id = cats.id
  ),
  page as (
    select
      p.id, p.sku, p.barcode, p.category_id, p.name, p.description, p.specs,
      p.selling_price, p.is_active, p.created_at,
      coalesce((
        select sum(ws.quantity) from public.warehouse_stock ws where ws.product_id = p.id
      ), 0) > 0 as is_available,
      p.is_featured, p.featured_sort
    from public.products p
    where p.is_active
      and not p.is_service
      and (p_category_id is null or p.category_id in (select id from cats))
      and (p_min_price is null or p.selling_price >= p_min_price)
      and (p_max_price is null or p.selling_price <= p_max_price)
      and (v_term is null or public.search_key(p.name || ' ' || p.sku) like v_term)
  )
  select
    pg.id, pg.sku, pg.barcode, pg.category_id, pg.name, pg.description, pg.specs,
    pg.selling_price, pg.is_active, pg.created_at, pg.is_available,
    (
      select pi.image_url from public.product_images pi
      where pi.product_id = pg.id
      order by pi.is_primary desc, pi.sort_order asc
      limit 1
    ) as primary_image_url,
    pg.is_featured, pg.featured_sort
  from page pg
  where not coalesce(p_available_only, false) or pg.is_available
  order by
    case when v_sort = 'price_asc' then pg.selling_price end asc,
    case when v_sort = 'price_desc' then pg.selling_price end desc,
    case when v_sort = 'name' then pg.name end asc,
    case when v_sort = 'newest' then pg.created_at end desc,
    pg.id
  limit p_limit offset p_offset;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Grants (rule from 0029)
-- ----------------------------------------------------------------------------
insert into private.rpc_allowlist (function_name, note) values
  ('search_key', 'pure helper behind idx_products_search_key_trgm'),
  ('rpc_browse_products', 'any signed-in user')
on conflict (function_name) do nothing;

select private.apply_function_grants();
