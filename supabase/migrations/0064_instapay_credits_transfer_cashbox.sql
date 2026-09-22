-- ============================================================================
-- 0064_instapay_credits_transfer_cashbox.sql
--
-- Business decision (confirmed by the owner, 2026-09-22): a confirmed
-- InstaPay transfer IS money the business actually received by transfer,
-- so approving one should credit خزنة التحويلات (0059's transfer
-- cashbox) — reversing 0059's original "InstaPay must never post to
-- cash_transactions" stance now that a transfer till actually exists to
-- post it to. Applies to both an order payment and a wallet top-up
-- confirmed via rpc_admin_verify_instapay: both are real money arriving
-- through the same InstaPay channel.
--
-- Still deliberately NOT touched: the gateway/card channel (not
-- implemented) and wallet spending (never re-enters cash_transactions —
-- it's an internal transfer between the customer's wallet and the order,
-- no new money arrives).
-- ============================================================================

create or replace function public.rpc_admin_verify_instapay(
  p_payment_id uuid, p_approve boolean, p_rejection_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
declare
  v_payment record;
  v_order record;
  v_wallet record;
  v_attempt_no int;
  v_transfer_cashbox_id uuid;
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

    select id into v_transfer_cashbox_id from public.cashboxes where kind = 'transfer' and is_active limit 1;
    if v_transfer_cashbox_id is null then raise exception 'NO_CASHBOX'; end if;

    if v_payment.order_id is not null then
      select * into v_order from public.orders where id = v_payment.order_id for update;
      insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
      values (v_payment.customer_id, 'payment', -v_payment.amount, v_payment.order_id, 'تحويل InstaPay مؤكَّد', auth.uid());

      insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
      values (v_transfer_cashbox_id, 'sale', v_payment.amount, 'order', v_payment.order_id, 'تحويل InstaPay مؤكَّد', auth.uid());

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

      insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
      values (v_transfer_cashbox_id, 'other_income', v_payment.amount, 'payment', p_payment_id, 'شحن محفظة عبر InstaPay مؤكَّد', auth.uid());
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
