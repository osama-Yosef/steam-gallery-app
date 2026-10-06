-- ============================================================================
-- 0076_offline_replay.sql
--
-- The admin app now queues writes while offline and sends them when the
-- connection is back. A queued write can reach the server twice: the first
-- attempt got through but its response was lost, so the app queued it and
-- sends it again. RPCs that already take a client_request_id (walk-in sale,
-- purchase invoice, supplier/customer payment) or are declarative (invoice
-- edit/delete, 0075) are safe to repeat. The ones below are not — a repeated
-- expense or deposit would be booked twice.
--
-- rpc_replay runs one of them at most once per request id: the id is
-- claimed in the same transaction as the call, so a failed call releases it
-- and a successful one makes every later attempt a no-op. The app sends the
-- same id on the first attempt and on every retry.
--
-- Dispatch is an explicit CASE over a fixed list (no dynamic SQL), and each
-- wrapped RPC still performs its own authorization check.
-- ============================================================================

create table if not exists private.processed_requests (
  id uuid primary key,
  rpc text not null,
  user_id uuid,
  created_at timestamptz not null default now()
);

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
    when 'rpc_cashbox_deposit' then
      v_result := to_jsonb(public.rpc_cashbox_deposit(
        (p ->> 'p_amount')::numeric, p ->> 'p_notes', coalesce(p ->> 'p_kind', 'cash')));
    when 'rpc_cashbox_withdraw' then
      v_result := to_jsonb(public.rpc_cashbox_withdraw(
        (p ->> 'p_amount')::numeric, p ->> 'p_notes', coalesce(p ->> 'p_kind', 'cash')));
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
    else
      raise exception 'UNSUPPORTED_RPC: %', p_rpc;
  end case;

  return jsonb_build_object('replayed', false, 'result', v_result);
end;
$$;

insert into private.rpc_allowlist (function_name, note) values
  ('rpc_replay', 'any signed-in user; each wrapped RPC checks its own role')
on conflict (function_name) do nothing;

select private.apply_function_grants();
notify pgrst, 'reload schema';
