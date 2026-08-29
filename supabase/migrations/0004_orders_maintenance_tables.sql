-- ============================================================================
-- 0004_orders_maintenance_tables.sql
-- orders, order_items, maintenance_requests, maintenance_images,
-- maintenance_status_history
-- ============================================================================

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number bigserial unique,
  customer_id uuid not null references public.customers(id),
  status order_status not null default 'pending',
  subtotal numeric(12,2) not null default 0,
  discount numeric(12,2) not null default 0 check (discount >= 0),
  total numeric(12,2) generated always as (subtotal - discount) stored,
  paid_amount numeric(12,2) not null default 0 check (paid_amount >= 0),
  delivery_address text,
  delivery_latitude numeric(10,7),
  delivery_longitude numeric(10,7),
  notes text,
  confirmed_by uuid references public.users(id),
  cancelled_reason text,
  client_request_id uuid unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger trg_orders_updated_at
  before update on public.orders
  for each row execute function public.touch_updated_at();

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id),
  product_name_snapshot text not null,
  quantity int not null check (quantity > 0),
  unit_price_snapshot numeric(12,2) not null check (unit_price_snapshot >= 0),
  unit_cost_snapshot numeric(12,2) not null check (unit_cost_snapshot >= 0),
  discount numeric(12,2) not null default 0 check (discount >= 0),
  line_total numeric(12,2) generated always as (quantity * unit_price_snapshot - discount) stored
);

create trigger trg_order_items_no_update
  before update or delete on public.order_items
  for each row execute function public.prevent_mutation();

-- ----------------------------------------------------------------------------
-- Maintenance (queue system)
-- ----------------------------------------------------------------------------
create table public.maintenance_requests (
  id uuid primary key default gen_random_uuid(),
  ticket_number bigserial unique,
  customer_id uuid not null references public.customers(id),
  customer_name text not null,
  phone text not null,
  address text,
  latitude numeric(10,7),
  longitude numeric(10,7),
  device_type text,
  problem_description text not null,
  notes text,
  status maintenance_status not null default 'waiting',
  assigned_technician_id uuid references public.technicians(id),
  created_at timestamptz not null default now(),
  assigned_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  cancelled_reason text
);

create table public.maintenance_images (
  id uuid primary key default gen_random_uuid(),
  maintenance_request_id uuid not null references public.maintenance_requests(id) on delete cascade,
  image_url text not null,
  uploaded_at timestamptz not null default now()
);

create table public.maintenance_status_history (
  id uuid primary key default gen_random_uuid(),
  maintenance_request_id uuid not null references public.maintenance_requests(id) on delete cascade,
  old_status maintenance_status,
  new_status maintenance_status not null,
  changed_by uuid references public.users(id),
  notes text,
  changed_at timestamptz not null default now()
);

create trigger trg_maintenance_history_no_update
  before update or delete on public.maintenance_status_history
  for each row execute function public.prevent_mutation();
