-- ============================================================================
-- 0002_core_tables.sql
-- users (profile extension of auth.users), customers, technicians
-- ============================================================================

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null default 'customer',
  full_name text not null,
  phone text unique,
  email text,
  avatar_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.users is 'Profile extension of auth.users. role drives every RLS policy.';

create table public.customers (
  id uuid primary key references public.users(id) on delete cascade,
  default_address text,
  default_latitude numeric(10,7),
  default_longitude numeric(10,7),
  notes text,
  created_at timestamptz not null default now()
);

create table public.technicians (
  id uuid primary key references public.users(id) on delete cascade,
  employee_code text unique not null,
  hire_date date not null default current_date,
  is_active boolean not null default true,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

-- updated_at auto-touch
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_users_updated_at
  before update on public.users
  for each row execute function public.touch_updated_at();
