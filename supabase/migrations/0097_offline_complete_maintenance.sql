-- ============================================================================
-- 0097_offline_complete_maintenance.sql
--
-- The technician's app now keeps working with no connection: a bag sale and
-- closing a maintenance job are saved on the phone and sent once the
-- connection is back (specs/001-offline-mode).
--
-- A queued write can reach the server twice — the first attempt got through
-- but its answer was lost, so the app sends it again. rpc_technician_sale is
-- already safe to repeat (p_client_request_id, 0090). rpc_complete_maintenance
-- is not: the second call finds the job completed and raises
-- FORBIDDEN_OR_NOT_IN_PROGRESS, so a close that worked would show as refused.
--
-- rpc_replay (0076, restated in 0081) runs it at most once per request id.
-- The function below is 0081's, unchanged except for the new case. The
-- wrapped RPC still does its own check (admin, or the technician the job is
-- assigned to), and rpc_replay stays callable by any signed-in user.
-- ============================================================================

create or replace function public.rpc_replay(p_request_id uuid, p_rpc text, p_params jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  p jsonb := coalesce(p_params, '{}'::jsonb);
  v_result jsonb;
begin
  if auth.uid() is null then raise exception 'FORBIDDEN'; end if;
  if p_request_id is null or p_rpc is null then raise exception 'INVALID_INPUT'; end if;

  insert into private.processed_requests (id, rpc, user_id)
  values (p_request_id, p_rpc, auth.uid())
  on conflict (id) do nothing;
  if not found then
    return jsonb_build_object('replayed', true);
  end if;

  case p_rpc
    when 'rpc_record_expense' then
      v_result := to_jsonb(public.rpc_record_expense(
        (p ->> 'p_category_id')::uuid, (p ->> 'p_amount')::numeric, (p ->> 'p_expense_date')::date,
        p ->> 'p_notes', p ->> 'p_attachment_url', coalesce(p ->> 'p_kind', 'cash')));
    when 'rpc_record_expenses' then
      v_result := public.rpc_record_expenses(
        p -> 'p_items', (p ->> 'p_expense_date')::date, coalesce(p ->> 'p_kind', 'cash'));
    when 'rpc_cashbox_deposit' then
      v_result := to_jsonb(public.rpc_cashbox_deposit(
        (p ->> 'p_amount')::numeric, p ->> 'p_notes', coalesce(p ->> 'p_kind', 'cash')));
    when 'rpc_cashbox_withdraw' then
      v_result := to_jsonb(public.rpc_cashbox_withdraw(
        (p ->> 'p_amount')::numeric, p ->> 'p_notes', coalesce(p ->> 'p_kind', 'cash')));
    when 'rpc_cashbox_transfer' then
      v_result := to_jsonb(public.rpc_cashbox_transfer(
        p ->> 'p_from_kind', p ->> 'p_to_kind', (p ->> 'p_amount')::numeric, p ->> 'p_notes'));
    when 'rpc_employee_advance' then
      v_result := to_jsonb(public.rpc_employee_advance(
        (p ->> 'p_employee_id')::uuid, (p ->> 'p_amount')::numeric, (p ->> 'p_advance_date')::date,
        p ->> 'p_kind', p ->> 'p_notes'));
    when 'rpc_pay_salary' then
      v_result := to_jsonb(public.rpc_pay_salary(
        (p ->> 'p_employee_id')::uuid, (p ->> 'p_month')::date, (p ->> 'p_absence_deduction')::numeric,
        (p ->> 'p_bonus')::numeric, (p ->> 'p_advance_deduction')::numeric, p ->> 'p_kind', p ->> 'p_notes'));
    when 'rpc_confirm_order' then
      perform public.rpc_confirm_order((p ->> 'p_order_id')::uuid);
    when 'rpc_update_order_status' then
      perform public.rpc_update_order_status((p ->> 'p_order_id')::uuid, (p ->> 'p_new_status')::order_status);
    when 'rpc_cancel_order' then
      perform public.rpc_cancel_order((p ->> 'p_order_id')::uuid, p ->> 'p_reason');
    when 'rpc_admin_return_order' then
      perform public.rpc_admin_return_order((p ->> 'p_order_id')::uuid, p ->> 'p_reason');
    when 'rpc_admin_set_shipping_fee' then
      perform public.rpc_admin_set_shipping_fee((p ->> 'p_order_id')::uuid, (p ->> 'p_amount')::numeric);
    -- 0097: a maintenance job closed on the technician's phone with no
    -- connection. Sent twice, it would fail the second time (the job is no
    -- longer in progress), so it goes through here instead.
    when 'rpc_complete_maintenance' then
      perform public.rpc_complete_maintenance((p ->> 'p_request_id')::uuid, p ->> 'p_notes');
    else
      raise exception 'UNSUPPORTED_RPC: %', p_rpc;
  end case;

  return jsonb_build_object('replayed', false, 'result', v_result);
end;
$$;
