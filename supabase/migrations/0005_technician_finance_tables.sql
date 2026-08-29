-- ============================================================================
-- 0005_technician_finance_tables.sql
-- sales, sale_items, technician_accounts, technician_account_transactions,
-- technician_supplies
-- ============================================================================

create table public.sales (
  id uuid primary key default gen_random_uuid(),
  sale_number bigserial unique,
  technician_id uuid not null references public.technicians(id),
  customer_id uuid references public.customers(id),
  customer_name text,
  customer_phone text,
  payment_method payment_method not null default 'cash',
  subtotal numeric(12,2) not null default 0,
  discount numeric(12,2) not null default 0 check (discount >= 0),
  total numeric(12,2) generated always as (subtotal - discount) stored,
  paid_amount numeric(12,2) not null default 0 check (paid_amount >= 0),
  status sale_status not null default 'completed',
  client_request_id uuid unique,
  created_at timestamptz not null default now()
);

create table public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete cascade,
  product_id uuid not null references public.products(id),
  product_name_snapshot text not null,
  quantity int not null check (quantity > 0),
  unit_price_snapshot numeric(12,2) not null check (unit_price_snapshot >= 0),
  unit_cost_snapshot numeric(12,2) not null check (unit_cost_snapshot >= 0),
  discount numeric(12,2) not null default 0 check (discount >= 0),
  line_total numeric(12,2) generated always as (quantity * unit_price_snapshot - discount) stored
);

create trigger trg_sale_items_no_update
  before update or delete on public.sale_items
  for each row execute function public.prevent_mutation();

-- ----------------------------------------------------------------------------
create table public.technician_accounts (
  id uuid primary key references public.technicians(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.technician_supplies (
  id uuid primary key default gen_random_uuid(),
  supply_number bigserial unique,
  technician_id uuid not null references public.technicians(id),
  amount numeric(12,2) not null check (amount > 0),
  notes text,
  recorded_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create table public.technician_account_transactions (
  id uuid primary key default gen_random_uuid(),
  technician_id uuid not null references public.technicians(id),
  transaction_type tech_txn_type not null,
  amount numeric(12,2) not null check (amount > 0),
  sale_id uuid references public.sales(id),
  supply_id uuid references public.technician_supplies(id),
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create trigger trg_tech_txn_no_update
  before update or delete on public.technician_account_transactions
  for each row execute function public.prevent_mutation();
