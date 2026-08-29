-- ============================================================================
-- 0003_catalog_warehouse_tables.sql
-- product_categories, products, product_images,
-- warehouses, warehouse_stock, technician_bags, technician_bag_stock,
-- stock_movements (the immutable stock ledger)
-- ============================================================================

create table public.product_categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.product_categories(id) on delete set null,
  name text not null,
  image_url text,
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  barcode text unique,
  category_id uuid references public.product_categories(id) on delete set null,
  name text not null,
  description text,
  specs jsonb not null default '{}'::jsonb,
  cost_price numeric(12,2) not null check (cost_price >= 0),
  selling_price numeric(12,2) not null check (selling_price >= 0),
  min_stock int not null default 0 check (min_stock >= 0),
  is_active boolean not null default true,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_products_updated_at
  before update on public.products
  for each row execute function public.touch_updated_at();

create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  image_url text not null,
  sort_order int not null default 0,
  is_primary boolean not null default false
);

create table public.warehouses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type warehouse_type not null default 'main',
  is_active boolean not null default true
);

create table public.warehouse_stock (
  id uuid primary key default gen_random_uuid(),
  warehouse_id uuid not null references public.warehouses(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity int not null default 0 check (quantity >= 0),
  unique (warehouse_id, product_id)
);

create table public.technician_bags (
  id uuid primary key default gen_random_uuid(),
  technician_id uuid not null unique references public.technicians(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.technician_bag_stock (
  id uuid primary key default gen_random_uuid(),
  technician_bag_id uuid not null references public.technician_bags(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity int not null default 0 check (quantity >= 0),
  unique (technician_bag_id, product_id)
);

-- ----------------------------------------------------------------------------
-- stock_movements: the single immutable ledger for ALL stock changes.
-- No table above is ever updated directly by client code; only by the
-- trigger below, which fires on INSERT into stock_movements.
-- ----------------------------------------------------------------------------
create table public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  movement_number bigserial unique,
  product_id uuid not null references public.products(id),
  movement_type stock_movement_type not null,
  quantity int not null check (quantity > 0),
  from_location_type location_type,
  from_location_id uuid,
  to_location_type location_type,
  to_location_id uuid,
  unit_cost numeric(12,2) not null check (unit_cost >= 0),
  total_cost numeric(14,2) generated always as (quantity * unit_cost) stored,
  reference_type text,
  reference_id uuid,
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

-- Immutability: no update/delete allowed at all (enforced again via RLS/grants,
-- this is a belt-and-suspenders guard at the trigger level).
create or replace function public.prevent_mutation() returns trigger
language plpgsql as $$
begin
  raise exception 'Ledger rows are immutable: % on % is not allowed', TG_OP, TG_TABLE_NAME;
end;
$$;

create trigger trg_stock_movements_no_update
  before update or delete on public.stock_movements
  for each row execute function public.prevent_mutation();
