-- ============================================================================
-- 0007_inventory_notifications_audit.sql
-- inventory_counts, inventory_count_items, notifications, audit_logs
-- ============================================================================

create table public.inventory_counts (
  id uuid primary key default gen_random_uuid(),
  count_number bigserial unique,
  location_type location_type not null check (location_type in ('warehouse', 'technician_bag')),
  location_id uuid not null,
  status inventory_count_status not null default 'draft',
  started_by uuid references public.users(id),
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  notes text
);

create table public.inventory_count_items (
  id uuid primary key default gen_random_uuid(),
  inventory_count_id uuid not null references public.inventory_counts(id) on delete cascade,
  product_id uuid not null references public.products(id),
  system_quantity int not null,
  actual_quantity int,
  difference int generated always as (coalesce(actual_quantity, system_quantity) - system_quantity) stored,
  reason text,
  notes text,
  constraint chk_reason_required_if_diff check (
    actual_quantity is null
    or actual_quantity = system_quantity
    or (reason is not null and length(trim(reason)) > 0)
  )
);

-- ----------------------------------------------------------------------------
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  data jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.users(id),
  action text not null,
  table_name text not null,
  record_id uuid,
  old_data jsonb,
  new_data jsonb,
  ip_address text,
  device_info text,
  created_at timestamptz not null default now()
);

create trigger trg_audit_logs_no_update
  before update or delete on public.audit_logs
  for each row execute function public.prevent_mutation();
