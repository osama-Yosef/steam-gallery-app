-- ============================================================================
-- 0054_fix_cart_items_option_ids_column.sql
--
-- Same story as 0053: 0049's `alter table public.cart_items add column
-- option_ids ...` (and the primary key change that depends on it) never
-- landed on the live database either — confirmed by rpc_cart_add_item now
-- existing (0053) but failing with "column option_ids does not exist"
-- the moment it tries to use it. Re-applying that piece of 0049, made safe
-- to re-run: skips the add-column if it's already there, and only touches
-- the primary key if it isn't already the 3-column version.
-- ============================================================================

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'cart_items' and column_name = 'option_ids'
  ) then
    alter table public.cart_items add column option_ids uuid[] not null default '{}';
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints tc
    join information_schema.key_column_usage kcu
      on kcu.constraint_name = tc.constraint_name and kcu.table_schema = tc.table_schema
    where tc.table_schema = 'public' and tc.table_name = 'cart_items'
      and tc.constraint_type = 'PRIMARY KEY' and kcu.column_name = 'option_ids'
  ) then
    alter table public.cart_items drop constraint if exists cart_items_pkey;
    alter table public.cart_items add primary key (customer_id, product_id, option_ids);
  end if;
end $$;

notify pgrst, 'reload schema';

-- Verify: should show option_ids as part of the primary key now.
select kcu.column_name
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on kcu.constraint_name = tc.constraint_name and kcu.table_schema = tc.table_schema
where tc.table_schema = 'public' and tc.table_name = 'cart_items' and tc.constraint_type = 'PRIMARY KEY';
