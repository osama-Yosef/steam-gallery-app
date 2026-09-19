-- ============================================================================
-- 0062_recreate_missing_product_options_table.sql
--
-- Root-causes the recurring "تعذر تحميل السلة" / can't-add-to-cart bug:
-- 0049 was supposed to create public.product_options, but on the live
-- database that migration never actually took (the table was missing
-- entirely — confirmed via the Supabase API logs: every rpc_get_my_cart /
-- rpc_cart_add_item call was failing with `relation "public.product_options"
-- does not exist`, 42P01). 0053/0054 later re-created the cart RPCs and the
-- cart_items.option_ids column (chasing a different, PGRST202 symptom) but
-- never re-created this table, since nothing at the time pointed to it being
-- the missing piece. All `if not exists`/guards below make this safe to run
-- regardless of exactly how much of 0049 did or didn't apply.
-- ============================================================================

create table if not exists public.product_options (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  name text not null check (btrim(name) <> ''),
  extra_price numeric(10,2) not null default 0 check (extra_price >= 0),
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists idx_product_options_product
  on public.product_options (product_id, sort_order);

alter table public.product_options enable row level security;

grant select on public.product_options to authenticated;
grant insert, update, delete on public.product_options to authenticated;

drop policy if exists product_options_select on public.product_options;
create policy product_options_select on public.product_options for select to authenticated using (true);

drop policy if exists product_options_write on public.product_options;
create policy product_options_write on public.product_options for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

select private.apply_function_grants();
notify pgrst, 'reload schema';
