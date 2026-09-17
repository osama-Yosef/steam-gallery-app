-- ============================================================================
-- 0040_wallet.sql  (Phase 13 — wallet)
--
-- The wallet is a SEPARATE financial system from customer_accounts (the
-- existing deferred-payment/debt ledger) — never merged (master prompt §5,
-- §38). A customer tops up their wallet (via InstaPay, reusing Phase 12's
-- manual verification — no gateway needed), then can pay for an order out of
-- that balance instantly, with no waiting on admin review.
--
-- The balance itself is never trusted from the client and never written
-- directly: every change is Lock wallet (SELECT ... FOR UPDATE) → validate →
-- append a ledger row → update the cached balance → commit, all inside one
-- SECURITY DEFINER function. The FOR UPDATE lock is what makes two
-- concurrent spends of the same balance impossible (master prompt's Wallet
-- Race Conditions test).
-- ============================================================================

create type wallet_txn_type as enum ('topup', 'debit', 'refund_credit', 'adjustment');

create table public.wallets (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id),
  currency text not null default 'EGP' check (currency ~ '^[A-Z]{3}$'),
  -- Cached, derived total — always equal to the sum of this wallet's
  -- transactions. Never written directly by anything except the RPCs below,
  -- and always inside the same transaction as the ledger row that explains it.
  balance numeric(12,2) not null default 0 check (balance >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (customer_id, currency)
);

create trigger trg_wallets_updated_at
  before update on public.wallets
  for each row execute function public.touch_updated_at();

revoke all on public.wallets from anon, authenticated;
grant select on public.wallets to authenticated;
alter table public.wallets enable row level security;
create policy wallets_select on public.wallets for select to authenticated
  using (customer_id = auth.uid() or public.is_admin());

create table public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets(id),
  type wallet_txn_type not null,
  -- Positive = credit (top-up, refund), negative = debit (spend).
  amount numeric(12,2) not null check (amount <> 0),
  balance_before numeric(12,2) not null check (balance_before >= 0),
  balance_after numeric(12,2) not null check (balance_after >= 0),
  reference_type text check (length(reference_type) <= 40),
  reference_id uuid,
  idempotency_key uuid unique,
  notes text check (length(notes) <= 500),
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create index idx_wallet_transactions_wallet on public.wallet_transactions(wallet_id, created_at);

-- Immutable ledger, same as every other financial trail here.
create trigger trg_wallet_transactions_no_mutation
  before update or delete on public.wallet_transactions
  for each row execute function public.prevent_mutation();

revoke all on public.wallet_transactions from anon, authenticated;
grant select on public.wallet_transactions to authenticated;
alter table public.wallet_transactions enable row level security;
create policy wallet_transactions_select on public.wallet_transactions for select to authenticated
  using (
    public.is_admin()
    or wallet_id in (select id from public.wallets where customer_id = auth.uid())
  );

-- ----------------------------------------------------------------------------
-- 1. rpc_get_my_wallet: lazily create-on-first-read (not every customer
--    needs one), never touched by handle_new_auth_user.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_my_wallet() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_wallet record;
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;

  insert into public.wallets (customer_id) values (auth.uid())
  on conflict (customer_id, currency) do nothing;

  select id, balance, currency, is_active into v_wallet
    from public.wallets where customer_id = auth.uid() and currency = 'EGP';

  return jsonb_build_object(
    'id', v_wallet.id, 'balance', v_wallet.balance,
    'currency', v_wallet.currency, 'is_active', v_wallet.is_active
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- 2. Top-up: customer declares an InstaPay transfer meant for the wallet
--    (mirrors rpc_submit_instapay_payment, but order-less — kept as its own
--    function rather than overloading Phase 12's, since the two have
--    different required inputs and this avoids touching already-shipped,
--    already-tested code).
-- ----------------------------------------------------------------------------
create or replace function public.rpc_wallet_topup_via_instapay(
  p_amount numeric, p_reference text, p_proof_path text,
  p_client_request_id uuid default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_payment_id uuid;
  v_existing uuid;
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then
    raise exception 'INVALID_AMOUNT';
  end if;
  if p_reference is null or length(btrim(p_reference)) = 0 then
    raise exception 'REFERENCE_REQUIRED';
  end if;
  if length(p_reference) > 100 then raise exception 'INPUT_TOO_LONG'; end if;
  if p_proof_path is null or length(p_proof_path) = 0 or length(p_proof_path) > 500 then
    raise exception 'PROOF_REQUIRED';
  end if;
  if p_proof_path !~ ('^' || auth.uid()::text || '/') then
    raise exception 'INVALID_PROOF_PATH';
  end if;

  if p_client_request_id is not null then
    select id into v_existing from public.payments where idempotency_key = p_client_request_id;
    if found then return v_existing; end if;
  end if;

  if exists (
    select 1 from public.payments
    where customer_id = auth.uid() and order_id is null and channel = 'instapay'
      and status = 'pending_verification'
  ) then
    raise exception 'VERIFICATION_ALREADY_PENDING';
  end if;

  begin
    insert into public.payments (
      customer_id, order_id, channel, provider, amount, status,
      provider_reference, idempotency_key, metadata
    ) values (
      auth.uid(), null, 'instapay', 'instapay', p_amount, 'pending_verification',
      btrim(p_reference), p_client_request_id,
      jsonb_build_object('proof_path', p_proof_path, 'purpose', 'wallet_topup')
    )
    returning id into v_payment_id;
  exception when unique_violation then
    raise exception 'DUPLICATE_REFERENCE_OR_REQUEST';
  end;

  perform public.notify_all_admins('instapay_submitted', 'شحن محفظة InstaPay بانتظار المراجعة',
    format('%s ج.م', p_amount), jsonb_build_object('payment_id', v_payment_id));

  return v_payment_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 3. Extend rpc_admin_verify_instapay: an order-less approved payment whose
--    metadata says purpose='wallet_topup' credits the wallet instead of an
--    order. Same signature as 0039 — this is a plain replace, no drop.
-- ----------------------------------------------------------------------------
create or replace function public.rpc_admin_verify_instapay(
  p_payment_id uuid, p_approve boolean, p_rejection_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_payment record;
  v_order record;
  v_wallet record;
  v_attempt_no int;
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_approve is null then raise exception 'INVALID_INPUT'; end if;
  if not p_approve and (p_rejection_reason is null or btrim(p_rejection_reason) = '') then
    raise exception 'REASON_REQUIRED';
  end if;
  if length(p_rejection_reason) > 500 then raise exception 'INPUT_TOO_LONG'; end if;

  select * into v_payment from public.payments where id = p_payment_id for update;
  if not found then raise exception 'PAYMENT_NOT_FOUND'; end if;
  if v_payment.channel <> 'instapay' then raise exception 'NOT_AN_INSTAPAY_PAYMENT'; end if;
  if v_payment.status <> 'pending_verification' then
    raise exception 'PAYMENT_NOT_PENDING_VERIFICATION';
  end if;

  select coalesce(max(attempt_no), 0) + 1 into v_attempt_no
    from public.payment_attempts where payment_id = p_payment_id;

  if p_approve then
    update public.payments set status = 'succeeded', paid_at = now() where id = p_payment_id;
    insert into public.payment_attempts (payment_id, attempt_no, status)
    values (p_payment_id, v_attempt_no, 'succeeded');

    if v_payment.order_id is not null then
      select * into v_order from public.orders where id = v_payment.order_id for update;
      insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
      values (v_payment.customer_id, 'payment', -v_payment.amount, v_payment.order_id, 'تحويل InstaPay مؤكَّد', auth.uid());

      update public.orders
        set paid_amount = paid_amount + v_payment.amount,
            payment_status = (case
              when v_order.paid_amount + v_payment.amount >= v_order.total then 'paid'
              else 'partially_paid'
            end)::payment_status
        where id = v_payment.order_id;
    elsif v_payment.metadata ->> 'purpose' = 'wallet_topup' then
      insert into public.wallets (customer_id) values (v_payment.customer_id)
      on conflict (customer_id, currency) do nothing;

      select * into v_wallet from public.wallets
        where customer_id = v_payment.customer_id and currency = 'EGP' for update;

      insert into public.wallet_transactions (
        wallet_id, type, amount, balance_before, balance_after,
        reference_type, reference_id, created_by
      ) values (
        v_wallet.id, 'topup', v_payment.amount, v_wallet.balance,
        v_wallet.balance + v_payment.amount, 'payment', p_payment_id, auth.uid()
      );
      update public.wallets set balance = balance + v_payment.amount where id = v_wallet.id;
    end if;

    perform public.notify_user(v_payment.customer_id, 'payment_confirmed', 'تم تأكيد تحويلك',
      format('تم تأكيد تحويل InstaPay بقيمة %s ج.م', v_payment.amount),
      jsonb_build_object('payment_id', p_payment_id, 'order_id', v_payment.order_id));
  else
    update public.payments
      set status = 'failed', metadata = metadata || jsonb_build_object('rejection_reason', btrim(p_rejection_reason))
      where id = p_payment_id;
    insert into public.payment_attempts (payment_id, attempt_no, status, failure_reason)
    values (p_payment_id, v_attempt_no, 'failed', btrim(p_rejection_reason));

    perform public.notify_user(v_payment.customer_id, 'payment_rejected', 'تعذَّر تأكيد تحويلك',
      btrim(p_rejection_reason),
      jsonb_build_object('payment_id', p_payment_id, 'order_id', v_payment.order_id));
  end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Pay an order from the wallet — instant, no admin review needed (the
--    money already cleared when it was topped up).
-- ----------------------------------------------------------------------------
create or replace function public.rpc_pay_order_from_wallet(
  p_order_id uuid, p_amount numeric, p_client_request_id uuid default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_wallet record;
  v_existing uuid;
  v_payment_id uuid;
begin
  if not public.is_customer() then raise exception 'FORBIDDEN'; end if;
  if p_amount is null or p_amount <= 0 or p_amount <> round(p_amount, 2) then
    raise exception 'INVALID_AMOUNT';
  end if;

  if p_client_request_id is not null then
    select id into v_existing from public.payments where idempotency_key = p_client_request_id;
    if found then return; end if;
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.customer_id <> auth.uid() then raise exception 'ORDER_CUSTOMER_MISMATCH'; end if;
  if v_order.status in ('cancelled', 'returned') then raise exception 'ORDER_NOT_PAYABLE'; end if;
  if p_amount > v_order.total - v_order.paid_amount then
    raise exception 'AMOUNT_EXCEEDS_REMAINING';
  end if;

  -- The lock that makes two concurrent spends of the same balance
  -- impossible: the second call blocks here until the first commits, then
  -- re-reads a balance that already reflects the first debit.
  select * into v_wallet from public.wallets
    where customer_id = auth.uid() and currency = 'EGP' for update;
  if not found or v_wallet.balance < p_amount then
    raise exception 'INSUFFICIENT_WALLET_BALANCE';
  end if;

  insert into public.wallet_transactions (
    wallet_id, type, amount, balance_before, balance_after,
    reference_type, reference_id, idempotency_key, created_by
  ) values (
    v_wallet.id, 'debit', -p_amount, v_wallet.balance, v_wallet.balance - p_amount,
    'order', p_order_id, p_client_request_id, auth.uid()
  );
  update public.wallets set balance = balance - p_amount where id = v_wallet.id;

  insert into public.payments (customer_id, order_id, channel, amount, status, paid_at, idempotency_key)
  values (auth.uid(), p_order_id, 'wallet', p_amount, 'succeeded', now(), p_client_request_id)
  returning id into v_payment_id;

  insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
  values (auth.uid(), 'payment', -p_amount, p_order_id, 'دفع من المحفظة', auth.uid());

  update public.orders
    set paid_amount = paid_amount + p_amount,
        payment_status = (case
          when v_order.paid_amount + p_amount >= v_order.total then 'paid'
          else 'partially_paid'
        end)::payment_status
    where id = p_order_id;
end;
$$;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_get_my_wallet', 'customer'),
  ('rpc_wallet_topup_via_instapay', 'customer'),
  ('rpc_pay_order_from_wallet', 'customer')
on conflict (function_name) do nothing;

select private.apply_function_grants();
