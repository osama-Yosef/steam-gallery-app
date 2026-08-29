-- ============================================================================
-- 0006_cashbox_customer_expense_tables.sql
-- cashboxes, cash_transactions, customer_accounts,
-- customer_account_transactions, expense_categories, expenses
-- ============================================================================

create table public.cashboxes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  is_active boolean not null default true
);

create table public.cash_transactions (
  id uuid primary key default gen_random_uuid(),
  cashbox_id uuid not null references public.cashboxes(id),
  transaction_type cash_txn_type not null,
  amount numeric(12,2) not null,  -- signed: positive = income, negative = expense
  reference_type text,
  reference_id uuid,
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  -- Sign is unambiguous only for these types; refund/adjustment/purchase can
  -- legitimately go either way depending on context, so their sign is
  -- validated inside the RPC layer instead of a blanket CHECK here.
  constraint chk_cash_amount_sign check (
    (transaction_type in ('sale', 'technician_deposit', 'other_income') and amount >= 0)
    or (transaction_type in ('expense', 'other_expense') and amount <= 0)
    or (transaction_type in ('refund', 'adjustment', 'purchase'))
  )
);

create trigger trg_cash_txn_no_update
  before update or delete on public.cash_transactions
  for each row execute function public.prevent_mutation();

-- ----------------------------------------------------------------------------
create table public.customer_accounts (
  id uuid primary key references public.customers(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.customer_account_transactions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id),
  transaction_type cust_txn_type not null,
  amount numeric(12,2) not null,  -- signed: positive increases debt, negative reduces it
  order_id uuid references public.orders(id),
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create trigger trg_cust_txn_no_update
  before update or delete on public.customer_account_transactions
  for each row execute function public.prevent_mutation();

-- ----------------------------------------------------------------------------
create table public.expense_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  is_active boolean not null default true
);

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  expense_number bigserial unique,
  category_id uuid not null references public.expense_categories(id),
  amount numeric(12,2) not null check (amount > 0),
  expense_date date not null default current_date,
  notes text,
  attachment_url text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create trigger trg_expenses_no_update
  before update or delete on public.expenses
  for each row execute function public.prevent_mutation();
