-- ============================================================================
-- 0060_fix_wallet_topup_verification_regression.sql
--
-- Pre-existing bug, unrelated to today's cashbox work — found by the full
-- test suite while verifying 0059 didn't regress anything. 0040 added a
-- wallet_topup branch to rpc_admin_verify_instapay: an InstaPay payment
-- with no order_id and metadata->>'purpose' = 'wallet_topup' credits the
-- customer's wallet on approval. 0044 rewrote this same function (to widen
-- FORBIDDEN to admin-or-sales) from what looks like an older copy that
-- predates 0040 — the wallet_topup branch never made it into the rewrite.
-- Since 0044, approving an InstaPay wallet top-up marks the payment
-- succeeded but never credits the wallet: the customer's money is
-- acknowledged as received and then never appears anywhere again.
--
-- Restores 0040's wallet_topup branch, keeping 0044's is_sales() widening.
-- ============================================================================

create or replace function public.rpc_admin_verify_instapay(
  p_payment_id uuid, p_approve boolean, p_rejection_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_payment record;
  v_order record;
  v_wallet record;
  v_attempt_no int;
begin
  if not (public.is_admin() or public.is_sales()) then raise exception 'FORBIDDEN'; end if;
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
      -- InstaPay money lands in the bank account, not the physical
      -- cashbox — this must NOT touch cash_transactions (0059's split
      -- keeps that ledger physical-till only).
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

select private.apply_function_grants();
notify pgrst, 'reload schema';
