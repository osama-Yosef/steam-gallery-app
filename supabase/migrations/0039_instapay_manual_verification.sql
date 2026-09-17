-- ============================================================================
-- 0039_instapay_manual_verification.sql  (Phase 12 — InstaPay, manual)
--
-- No InstaPay API integration exists (nor is one needed): the flow the spec
-- asks for is manual — the customer transfers to the business's own InstaPay
-- handle, tells us the reference and uploads a screenshot, and an admin
-- checks the real bank statement before confirming. The customer can only
-- ever create a 'pending_verification' payment; only rpc_admin_verify_instapay
-- (admin-only, SECURITY DEFINER) can turn that into 'succeeded' or 'failed'.
-- This is exactly the "لا تسمح للعميل بتعديل payment status" / "اعتبار نجاح
-- callback من العميل دليلًا كافيًا" rule — there is no callback here at all,
-- only a human checking a real bank statement.
--
-- Reuses the payments/payment_attempts tables from Phase 10 (channel =
-- 'instapay') rather than a new parallel table.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. A distinct status for "customer says they paid, nobody has checked yet"
-- ----------------------------------------------------------------------------
alter type payment_txn_status add value if not exists 'pending_verification' after 'pending';

-- Full audit trail of every payment change from here on (Phase 12 needs it
-- for InstaPay verification; every future channel benefits too).
create trigger trg_audit_payments after insert or update or delete on public.payments
  for each row execute function public.audit_trigger();

-- ----------------------------------------------------------------------------
-- 2. Admin-configurable InstaPay details (the actual handle is a business
--    fact, not something to hardcode) — text settings alongside 0031's
--    boolean ones.
-- ----------------------------------------------------------------------------
insert into private.app_settings (key, value) values
  ('instapay_ipa_address', 'null'::jsonb),
  ('instapay_beneficiary_name', 'null'::jsonb)
on conflict (key) do nothing;

create or replace function private.setting_text(p_key text) returns text
language sql stable security definer set search_path = private, public as $$
  select nullif(value #>> '{}', '') from private.app_settings where key = p_key;
$$;
revoke all on function private.setting_text(text) from public, anon, authenticated;

-- Any signed-in user needs this to know where to send the transfer.
create or replace function public.rpc_get_instapay_details() returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'ipa_address', private.setting_text('instapay_ipa_address'),
    'beneficiary_name', private.setting_text('instapay_beneficiary_name'),
    'configured', private.setting_text('instapay_ipa_address') is not null
  );
$$;

create or replace function public.rpc_admin_set_text_setting(p_key text, p_value text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_old jsonb;
  v_allowed_keys text[] := array['instapay_ipa_address', 'instapay_beneficiary_name'];
begin
  if not public.is_admin() then raise exception 'FORBIDDEN'; end if;
  if p_key <> all(v_allowed_keys) then raise exception 'UNKNOWN_SETTING'; end if;
  if length(p_value) > 200 then raise exception 'INPUT_TOO_LONG'; end if;

  select value into v_old from private.app_settings where key = p_key for update;
  if not found then raise exception 'UNKNOWN_SETTING'; end if;

  update private.app_settings
    set value = to_jsonb(nullif(btrim(p_value), '')), updated_at = now(), updated_by = auth.uid()
    where key = p_key;

  insert into public.audit_logs (actor_id, action, table_name, old_data, new_data)
  values (auth.uid(), 'SETTING_CHANGED', 'private.app_settings',
          jsonb_build_object('key', p_key, 'value', v_old),
          jsonb_build_object('key', p_key, 'value', to_jsonb(p_value)));
end;
$$;

-- ----------------------------------------------------------------------------
-- 3. Storage: payment proof screenshots — private, path
--    payment_proofs/{customer_id}/{filename}
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public) values ('payment_proofs', 'payment_proofs', false)
on conflict (id) do nothing;

create policy "payment_proofs_owner_read" on storage.objects for select to authenticated
  using (
    bucket_id = 'payment_proofs'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
  );
create policy "payment_proofs_owner_write" on storage.objects for insert to authenticated
  with check (bucket_id = 'payment_proofs' and (storage.foldername(name))[1] = auth.uid()::text);
-- No update/delete policy at all: submitted evidence is not editable by
-- anyone, including the customer who uploaded it or an admin.

-- ----------------------------------------------------------------------------
-- 4. rpc_submit_instapay_payment: customer declares a transfer they made
-- ----------------------------------------------------------------------------
create or replace function public.rpc_submit_instapay_payment(
  p_order_id uuid, p_amount numeric, p_reference text, p_proof_path text,
  p_client_request_id uuid default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_payment_id uuid;
  v_existing record;
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
  -- The proof must actually be this customer's own upload, in their own
  -- storage folder ({customer_id}/{file}, matching payment_proofs' RLS) —
  -- not any path they feel like typing in.
  if p_proof_path !~ ('^' || auth.uid()::text || '/') then
    raise exception 'INVALID_PROOF_PATH';
  end if;

  -- Checked before the "already pending" business rule below: a genuine
  -- retry of the SAME submission must short-circuit here, not be blocked by
  -- a "pending" row that this very attempt already created.
  if p_client_request_id is not null then
    select id into v_existing from public.payments where idempotency_key = p_client_request_id;
    if found then return v_existing.id; end if;
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.customer_id <> auth.uid() then raise exception 'ORDER_CUSTOMER_MISMATCH'; end if;
  if v_order.status in ('cancelled', 'returned') then raise exception 'ORDER_NOT_PAYABLE'; end if;
  if p_amount > v_order.total - v_order.paid_amount then
    raise exception 'AMOUNT_EXCEEDS_REMAINING';
  end if;
  if exists (
    select 1 from public.payments
    where order_id = p_order_id and channel = 'instapay' and status = 'pending_verification'
  ) then
    raise exception 'VERIFICATION_ALREADY_PENDING';
  end if;

  begin
    insert into public.payments (
      customer_id, order_id, channel, provider, amount, status,
      provider_reference, idempotency_key, metadata
    ) values (
      auth.uid(), p_order_id, 'instapay', 'instapay', p_amount, 'pending_verification',
      btrim(p_reference), p_client_request_id, jsonb_build_object('proof_path', p_proof_path)
    )
    returning id into v_payment_id;
  exception when unique_violation then
    -- Either the same client_request_id retried, or (far less likely) two
    -- genuinely different transfers happened to share a reference string —
    -- either way this must not silently create a second row.
    raise exception 'DUPLICATE_REFERENCE_OR_REQUEST';
  end;

  perform public.notify_all_admins('instapay_submitted', 'تحويل InstaPay بانتظار المراجعة',
    format('طلب #%s — %s ج.م', v_order.order_number, p_amount),
    jsonb_build_object('order_id', p_order_id, 'payment_id', v_payment_id));

  return v_payment_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- 5. rpc_admin_verify_instapay: the only path from pending_verification
-- ----------------------------------------------------------------------------
create or replace function public.rpc_admin_verify_instapay(
  p_payment_id uuid, p_approve boolean, p_rejection_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_payment record;
  v_order record;
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
  -- Locked by the SELECT ... FOR UPDATE above: a second concurrent verify
  -- call blocks until the first commits, then finds this false and stops —
  -- no double-apply (master prompt Test 9).
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
      -- InstaPay money lands in the bank account, not the physical
      -- cashbox — unlike rpc_record_customer_payment's cash path, this
      -- must NOT touch cash_transactions (that ledger is physical-till
      -- only). The customer account ledger still reconciles either way.
      insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
      values (v_payment.customer_id, 'payment', -v_payment.amount, v_payment.order_id, 'تحويل InstaPay مؤكَّد', auth.uid());

      update public.orders
        set paid_amount = paid_amount + v_payment.amount,
            payment_status = (case
              when v_order.paid_amount + v_payment.amount >= v_order.total then 'paid'
              else 'partially_paid'
            end)::payment_status
        where id = v_payment.order_id;
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

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_get_instapay_details', 'any signed-in user'),
  ('rpc_admin_set_text_setting', 'admin'),
  ('rpc_submit_instapay_payment', 'customer'),
  ('rpc_admin_verify_instapay', 'admin')
on conflict (function_name) do nothing;

select private.apply_function_grants();
