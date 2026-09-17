-- ============================================================================
-- 0038_payment_architecture.sql  (Phase 10 — payment architecture)
--
-- No payment provider is wired up yet — that is Phase 11 (gateway) and
-- Phase 12 (InstaPay manual verification). This phase only lays the tables
-- the rest of the payment work will sit on, per the architecture the master
-- prompt requires:
--
--   Flutter → Edge Function (service_role) → Provider → Provider webhook
--   → Edge Function (service_role) → validate → update `payments` → apply
--   business effect → notify.
--
-- Flutter (the `authenticated` role) can only ever READ these tables. There
-- is deliberately no client-callable RPC that inserts or updates a payment:
-- a customer must never be able to mark their own payment "succeeded" —
-- only a server process holding the service_role key can, and that key
-- never reaches the app (see 0029's rule and docs/07). `cash_on_delivery`
-- keeps working exactly as it does today (rpc_record_customer_payment,
-- 0030/0037); this table starts empty and is populated once Phase 11/12
-- exist.
-- ============================================================================

create type payment_channel as enum ('cash_on_delivery', 'gateway', 'instapay', 'wallet');
create type payment_txn_status as enum ('pending', 'processing', 'succeeded', 'failed', 'cancelled', 'refunded');

-- ----------------------------------------------------------------------------
-- 1. payments — one row per payment attempt-group (order or wallet top-up)
-- ----------------------------------------------------------------------------
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id),
  -- Nullable: a wallet top-up (Phase 13) has no order behind it.
  order_id uuid references public.orders(id),
  channel payment_channel not null,
  -- e.g. 'paymob', 'fawry', null for cash_on_delivery / instapay (manual).
  provider text check (length(provider) <= 40),
  amount numeric(12,2) not null check (amount > 0),
  currency text not null default 'EGP' check (currency ~ '^[A-Z]{3}$'),
  status payment_txn_status not null default 'pending',
  provider_reference text check (length(provider_reference) <= 200),
  -- Client-supplied, so retrying the SAME checkout/top-up attempt can never
  -- create two payment rows (same idea as orders.client_request_id).
  idempotency_key uuid unique,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  paid_at timestamptz,
  -- A given provider reference can only ever back one payment — the guard
  -- that makes a replayed "payment succeeded" webhook a no-op, not a
  -- second credit (Test 3 in the master prompt's financial test list).
  unique (provider, provider_reference)
);

create index idx_payments_customer on public.payments(customer_id);
create index idx_payments_order on public.payments(order_id) where order_id is not null;
create index idx_payments_status on public.payments(status);

create trigger trg_payments_updated_at
  before update on public.payments
  for each row execute function public.touch_updated_at();

revoke all on public.payments from anon, authenticated;
grant select on public.payments to authenticated;
alter table public.payments enable row level security;
create policy payments_select on public.payments for select to authenticated
  using (customer_id = auth.uid() or public.is_admin());
-- No insert/update/delete grant to authenticated at all: only service_role
-- (Edge Functions) can write here, once Phase 11/12 exist.

-- ----------------------------------------------------------------------------
-- 2. payment_attempts — append-only history of each try (retries, failures)
-- ----------------------------------------------------------------------------
create table public.payment_attempts (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments(id) on delete cascade,
  attempt_no int not null check (attempt_no > 0),
  status payment_txn_status not null,
  provider_reference text check (length(provider_reference) <= 200),
  failure_reason text check (length(failure_reason) <= 500),
  created_at timestamptz not null default now(),
  unique (payment_id, attempt_no)
);

create index idx_payment_attempts_payment on public.payment_attempts(payment_id);

-- Immutable, like every other financial trail here (stock_movements,
-- cash_transactions, customer_account_transactions): a wrong attempt row
-- gets a new compensating row, never an edit.
create trigger trg_payment_attempts_no_mutation
  before update or delete on public.payment_attempts
  for each row execute function public.prevent_mutation();

revoke all on public.payment_attempts from anon, authenticated;
grant select on public.payment_attempts to authenticated;
alter table public.payment_attempts enable row level security;
create policy payment_attempts_select on public.payment_attempts for select to authenticated
  using (public.is_admin());

-- ----------------------------------------------------------------------------
-- 3. payment_webhook_events — raw provider deliveries, keyed for idempotency
-- ----------------------------------------------------------------------------
-- (provider, event_id) is unique, so a provider retrying the same webhook
-- delivery is caught here before it can double-apply anything. The Edge
-- Function inserts the raw event first, then processes it; processed_at /
-- processing_error record the outcome without touching the original payload.
create table public.payment_webhook_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null check (length(provider) <= 40),
  event_id text not null check (length(event_id) <= 200),
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  processing_error text check (length(processing_error) <= 500),
  unique (provider, event_id)
);

-- The raw delivery (provider/event_id/payload/received_at) never changes
-- once written; only the processing outcome may be filled in afterwards.
create or replace function public.prevent_webhook_event_tamper() returns trigger
language plpgsql as $$
begin
  if new.provider <> old.provider or new.event_id <> old.event_id
     or new.payload is distinct from old.payload or new.received_at <> old.received_at then
    raise exception 'payment_webhook_events: only processed_at/processing_error may change';
  end if;
  return new;
end;
$$;

create trigger trg_payment_webhook_events_immutable_core
  before update on public.payment_webhook_events
  for each row execute function public.prevent_webhook_event_tamper();
create trigger trg_payment_webhook_events_no_delete
  before delete on public.payment_webhook_events
  for each row execute function public.prevent_mutation();

revoke all on public.payment_webhook_events from anon, authenticated;
grant select on public.payment_webhook_events to authenticated;
alter table public.payment_webhook_events enable row level security;
create policy payment_webhook_events_admin_select on public.payment_webhook_events for select to authenticated
  using (public.is_admin());
-- No customer access at all — raw provider payloads may carry sensitive
-- data (§75). No insert/update grant to authenticated either; service_role
-- (Edge Functions) only.

select private.apply_function_grants();
