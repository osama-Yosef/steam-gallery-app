-- ============================================================================
-- 0033_storefront_offers_banners.sql
--
-- Phase 5: content for the customer home screen.
--
--   products.is_featured / featured_sort   "مختارات مكوجي"
--   offers + offer_products                 special offers the admin runs
--                                           whenever they like
--   home_banners                            the home carousel
--   storage bucket `marketing`              banner / offer images
--
-- PRICING IS UNTOUCHED. An offer is promotional content — a title, a badge
-- ("توصيل مجاني"), an image, a schedule and a set of products. It never
-- changes what a product costs: rpc_create_order keeps charging
-- products.selling_price, and nothing here is read by it. (Decided with the
-- business owner: "عروض خاصة وقت ما أحب لكن السعر ثابت".)
--
-- "Live" = switched on AND inside its optional schedule (starts_at/ends_at).
-- Customers only ever see live offers/banners, enforced by RLS — the app
-- filtering too is a nicety, not the boundary. Admins see and maintain
-- everything; nothing is deletable except an offer's product links (a join
-- row, not history).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Featured products
-- ----------------------------------------------------------------------------
alter table public.products
  add column if not exists is_featured boolean not null default false,
  add column if not exists featured_sort int not null default 0;

create index if not exists idx_products_featured
  on public.products (featured_sort, created_at desc)
  where is_featured and is_active and not is_service;

-- New columns go at the end: CREATE OR REPLACE VIEW can only append.
-- Definer semantics kept deliberately (see 0024/0027).
alter view public.products_public set (security_invoker = false);

create or replace view public.products_public as
select
  p.id, p.sku, p.barcode, p.category_id, p.name, p.description, p.specs,
  p.selling_price, p.is_active, p.created_at,
  coalesce(ws.total_qty, 0) > 0 as is_available,
  img.image_url as primary_image_url,
  p.is_featured,
  p.featured_sort
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
where p.is_active = true and p.is_service = false;

grant select on public.products_public to authenticated;

-- ----------------------------------------------------------------------------
-- 2. Offers
-- ----------------------------------------------------------------------------
create table public.offers (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(btrim(title)) between 1 and 80),
  subtitle text check (length(subtitle) <= 160),
  description text check (length(description) <= 1000),
  -- Short label shown on the card, e.g. "توصيل مجاني" / "صيانة مجانية".
  badge_text text check (length(badge_text) <= 24),
  image_url text check (length(image_url) <= 1000),
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean not null default false,
  sort_order int not null default 0,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);

create table public.offer_products (
  offer_id uuid not null references public.offers(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  sort_order int not null default 0,
  primary key (offer_id, product_id)
);

create index idx_offers_live on public.offers (sort_order, created_at desc) where is_active;
create index idx_offer_products_product on public.offer_products (product_id);

create trigger trg_offers_updated_at
  before update on public.offers
  for each row execute function public.touch_updated_at();

-- ----------------------------------------------------------------------------
-- 3. Home banners
-- ----------------------------------------------------------------------------
create table public.home_banners (
  id uuid primary key default gen_random_uuid(),
  -- Shown to screen readers and in the admin list; not drawn on the image.
  title text not null check (length(btrim(title)) between 1 and 80),
  image_url text not null check (length(image_url) between 1 and 1000),
  -- Where tapping the banner goes.
  target_type text not null default 'none'
    check (target_type in ('none', 'offer', 'category', 'product', 'maintenance')),
  target_id uuid,
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean not null default false,
  sort_order int not null default 0,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at is null or starts_at is null or ends_at > starts_at),
  check ((target_type in ('offer', 'category', 'product')) = (target_id is not null))
);

create index idx_home_banners_live on public.home_banners (sort_order, created_at desc) where is_active;

create trigger trg_home_banners_updated_at
  before update on public.home_banners
  for each row execute function public.touch_updated_at();

-- A polymorphic target can't be a foreign key; check it exists instead, so a
-- banner never sends customers to a dead link.
create or replace function public.home_banners_check_target() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (new.target_type = 'offer' and not exists (select 1 from public.offers where id = new.target_id))
     or (new.target_type = 'category' and not exists (select 1 from public.product_categories where id = new.target_id))
     or (new.target_type = 'product' and not exists (select 1 from public.products where id = new.target_id and not is_service))
  then
    raise exception 'BANNER_TARGET_NOT_FOUND';
  end if;
  return new;
end;
$$;

create trigger trg_home_banners_check_target
  before insert or update of target_type, target_id on public.home_banners
  for each row execute function public.home_banners_check_target();

create trigger trg_audit_offers after insert or update or delete on public.offers
  for each row execute function public.audit_trigger();
create trigger trg_audit_home_banners after insert or update or delete on public.home_banners
  for each row execute function public.audit_trigger();

-- ----------------------------------------------------------------------------
-- 4. Liveness + RLS
-- ----------------------------------------------------------------------------
create or replace function public.is_live(p_active boolean, p_starts timestamptz, p_ends timestamptz)
returns boolean language sql stable as $$
  select p_active
     and (p_starts is null or p_starts <= now())
     and (p_ends is null or p_ends > now());
$$;

alter table public.offers enable row level security;
alter table public.offer_products enable row level security;
alter table public.home_banners enable row level security;

revoke all on public.offers, public.offer_products, public.home_banners from public, anon, authenticated;

grant select, insert, update on public.offers, public.home_banners to authenticated;
grant select, insert, update, delete on public.offer_products to authenticated;

create policy offers_select on public.offers for select to authenticated
  using (public.is_admin() or public.is_live(is_active, starts_at, ends_at));
create policy offers_admin_insert on public.offers for insert to authenticated
  with check (public.is_admin());
create policy offers_admin_update on public.offers for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy offer_products_select on public.offer_products for select to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.offers o
      where o.id = offer_id and public.is_live(o.is_active, o.starts_at, o.ends_at)
    )
  );
create policy offer_products_admin_write on public.offer_products for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy home_banners_select on public.home_banners for select to authenticated
  using (public.is_admin() or public.is_live(is_active, starts_at, ends_at));
create policy home_banners_admin_insert on public.home_banners for insert to authenticated
  with check (public.is_admin());
create policy home_banners_admin_update on public.home_banners for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- 5. Products of a live offer (catalogue-safe columns only)
-- ----------------------------------------------------------------------------
-- Invoker rights on purpose: offer_products' RLS decides whether the caller
-- may see this offer's products (live, or admin), and products_public is the
-- cost-free view.
create or replace function public.rpc_offer_products(p_offer_id uuid)
returns setof public.products_public
language sql stable set search_path = public as $$
  select pp.*
  from public.offer_products op
  join public.products_public pp on pp.id = op.product_id
  where op.offer_id = p_offer_id
  order by op.sort_order, pp.name;
$$;

-- ----------------------------------------------------------------------------
-- 6. Storage: marketing images
-- ----------------------------------------------------------------------------
-- Public read (they're shown on the storefront), admin-only writes. Paths:
-- banners/{uuid}.{ext}, offers/{uuid}.{ext}.
insert into storage.buckets (id, name, public) values ('marketing', 'marketing', true)
on conflict (id) do nothing;

create policy "marketing_public_read" on storage.objects for select
  using (bucket_id = 'marketing');
create policy "marketing_admin_insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'marketing' and public.is_admin());
create policy "marketing_admin_update" on storage.objects for update to authenticated
  using (bucket_id = 'marketing' and public.is_admin());
create policy "marketing_admin_delete" on storage.objects for delete to authenticated
  using (bucket_id = 'marketing' and public.is_admin());

-- ----------------------------------------------------------------------------
-- 7. Grants (rule from 0029)
-- ----------------------------------------------------------------------------
-- is_live runs inside RLS policies as the querying user.
insert into private.rpc_allowlist (function_name, note) values
  ('is_live', 'RLS helper'),
  ('rpc_offer_products', 'any signed-in user')
on conflict (function_name) do nothing;

select private.apply_function_grants();
