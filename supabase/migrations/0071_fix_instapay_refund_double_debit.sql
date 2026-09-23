-- ============================================================================
-- 0071_fix_instapay_refund_double_debit.sql
--
-- Bug: since 0064, an approved InstaPay order payment posts a
-- cash_transactions('sale', reference_type='order') row to the transfer
-- cashbox, on top of what 0059's fn_apply_order_refund already assumed --
-- that ANY such row is a manually-recorded payment (rpc_record_customer_payment)
-- that must be reversed at the till. Refunding an InstaPay-paid order therefore:
--   1) correctly credits the customer's wallet with the InstaPay amount
--      (fn_apply_order_refund's own v_instapay_paid branch, unchanged), AND
--   2) ALSO reverses the 0064 cash_transactions row at the transfer till,
--      debiting money that never left the till as cash -- it became a wallet
--      liability, not a payout. This under-reports the transfer cashbox
--      balance and can raise a spurious INSUFFICIENT_CASH on cancellation.
--
-- Fix: in the per-till reversal loop, subtract the already-wallet-refunded
-- InstaPay amount from whatever the transfer cashbox's row totals before
-- deciding what (if anything) to reverse there. A transfer-till row can
-- still contain a manually-recorded transfer payment for the same order;
-- only the InstaPay portion is excluded.
-- ============================================================================

create or replace function private.fn_apply_order_refund(p_order_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_order record;
  v_wallet_paid numeric(12,2);
  v_instapay_paid numeric(12,2);
  v_gateway_paid numeric(12,2);
  v_wallet record;
  v_till_row record;
  v_balance numeric(14,2);
  v_transfer_cashbox_id uuid;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.paid_amount <= 0 then return; end if;

  select coalesce(sum(amount), 0) into v_wallet_paid
    from public.payments where order_id = p_order_id and channel = 'wallet' and status = 'succeeded';
  select coalesce(sum(amount), 0) into v_instapay_paid
    from public.payments where order_id = p_order_id and channel = 'instapay' and status = 'succeeded';
  select coalesce(sum(amount), 0) into v_gateway_paid
    from public.payments where order_id = p_order_id and channel = 'gateway' and status = 'succeeded';

  if v_gateway_paid > 0 then
    raise exception 'GATEWAY_REFUND_NOT_IMPLEMENTED';
  end if;

  if v_wallet_paid > 0 then
    insert into public.wallets (customer_id) values (v_order.customer_id)
    on conflict (customer_id, currency) do nothing;
    select * into v_wallet from public.wallets
      where customer_id = v_order.customer_id and currency = 'EGP' for update;

    insert into public.wallet_transactions (
      wallet_id, type, amount, balance_before, balance_after,
      reference_type, reference_id, notes, created_by
    ) values (
      v_wallet.id, 'refund_credit', v_wallet_paid, v_wallet.balance, v_wallet.balance + v_wallet_paid,
      'order', p_order_id, btrim(p_reason), auth.uid()
    );
    update public.wallets set balance = balance + v_wallet_paid where id = v_wallet.id;

    update public.payments set status = 'refunded'
      where order_id = p_order_id and channel = 'wallet' and status = 'succeeded';
  end if;

  if v_instapay_paid > 0 then
    insert into public.wallets (customer_id) values (v_order.customer_id)
    on conflict (customer_id, currency) do nothing;
    select * into v_wallet from public.wallets
      where customer_id = v_order.customer_id and currency = 'EGP' for update;

    insert into public.wallet_transactions (
      wallet_id, type, amount, balance_before, balance_after,
      reference_type, reference_id, notes, created_by
    ) values (
      v_wallet.id, 'refund_credit', v_instapay_paid, v_wallet.balance, v_wallet.balance + v_instapay_paid,
      'order', p_order_id, 'استرداد تحويل InstaPay إلى رصيد المحفظة: ' || btrim(p_reason), auth.uid()
    );
    update public.wallets set balance = balance + v_instapay_paid where id = v_wallet.id;

    update public.payments set status = 'refunded'
      where order_id = p_order_id and channel = 'instapay' and status = 'succeeded';

    select id into v_transfer_cashbox_id from public.cashboxes where kind = 'transfer' and is_active limit 1;
  end if;

  -- Every manually-recorded payment (rpc_record_customer_payment) posted an
  -- exact cash_transactions row to a specific till; reverse each one
  -- exactly rather than guessing a single channel.
  for v_till_row in
    select cashbox_id, sum(amount) as amount from public.cash_transactions
    where reference_type = 'order' and reference_id = p_order_id and transaction_type = 'sale'
    group by cashbox_id
  loop
    -- The InstaPay portion of this till's total (if any) was already
    -- refunded to the wallet above, not paid out of the till -- exclude it
    -- so it isn't debited from the till a second time.
    if v_transfer_cashbox_id is not null and v_till_row.cashbox_id = v_transfer_cashbox_id then
      v_till_row.amount := v_till_row.amount - v_instapay_paid;
    end if;

    if v_till_row.amount > 0 then
      select coalesce(sum(amount), 0) into v_balance
        from public.cash_transactions where cashbox_id = v_till_row.cashbox_id;
      if v_till_row.amount > v_balance then
        raise exception 'INSUFFICIENT_CASH: %', v_balance;
      end if;

      insert into public.cash_transactions (cashbox_id, transaction_type, amount, reference_type, reference_id, notes, created_by)
      values (v_till_row.cashbox_id, 'refund', -v_till_row.amount, 'order', p_order_id, btrim(p_reason), auth.uid());

      insert into public.customer_account_transactions (customer_id, transaction_type, amount, order_id, notes, created_by)
      values (v_order.customer_id, 'adjustment', v_till_row.amount, p_order_id, btrim(p_reason), auth.uid());
    end if;
  end loop;
end;
$$;
